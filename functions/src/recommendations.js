const utils = require('./utils');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { FieldValue } = require('firebase-admin/firestore');

const { db, logAudit } = utils;

// ─── Helper: Haversine Distance (km) ─────────────────────────────────────────
/**
 * Calculates the distance between two lat/lng points in kilometres.
 */
function haversineDistance(lat1, lon1, lat2, lon2) {
    const R = 6371; // Earth radius in km
    const dLat = ((lat2 - lat1) * Math.PI) / 180;
    const dLon = ((lon2 - lon1) * Math.PI) / 180;
    const a =
        Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos((lat1 * Math.PI) / 180) *
            Math.cos((lat2 * Math.PI) / 180) *
            Math.sin(dLon / 2) *
            Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
}

// ─── Helper: Distance Score ───────────────────────────────────────────────────
function getDistanceScore(distanceKm) {
    if (distanceKm < 5) return 1.0;
    if (distanceKm < 10) return 0.7;
    if (distanceKm < 20) return 0.4;
    return 0.1;
}

// ─── Function: calculateRecommendations ──────────────────────────────────────
/**
 * Callable Cloud Function: calculateRecommendations
 *
 * Accepts { userId, latitude, longitude, category } from the caller.
 * Queries freelancers/shops from the users collection, scores each one
 * based on distance, rating, popularity and category match, then returns
 * the top-10 results and persists them to recommendations/{userId}.
 */
exports.calculateRecommendations = onCall(async (request) => {
    const { userId, latitude, longitude, category } = request.data || {};

    if (!userId || typeof userId !== 'string') {
        throw new HttpsError('invalid-argument', 'userId is required');
    }
    if (latitude == null || longitude == null) {
        throw new HttpsError('invalid-argument', 'latitude and longitude are required');
    }

    const lat = Number(latitude);
    const lon = Number(longitude);
    if (isNaN(lat) || isNaN(lon)) {
        throw new HttpsError('invalid-argument', 'latitude and longitude must be valid numbers');
    }

    try {
        // Fetch caller document to get their interests
        const callerDoc = await db.collection('users').doc(userId).get();
        const callerData = callerDoc.exists ? callerDoc.data() : {};
        const serviceInterests = Array.isArray(callerData.serviceInterests) ? callerData.serviceInterests : [];
        
        // Determine search target categories (either explicitly requested or from interests)
        const targetCategories = category ? [category.toLowerCase()] : serviceInterests.map(i => i.toLowerCase());

        // Query providers from Firestore
        const snapshot = await db
            .collection('users')
            .where('role', 'in', ['freelancer', 'shop', 'Freelancer', 'Shop', 'privateService', 'techService'])
            .get();

        if (snapshot.empty) {
            return { recommendations: [], count: 0 };
        }

        const scored = [];

        snapshot.docs.forEach((doc) => {
            // Skip the requesting user themselves
            if (doc.id === userId) return;

            const user = doc.data();

            // ── Distance score ────────────────────────────────────────────
            let distance_score = 0.1; // default: unknown location
            if (user.latitude != null && user.longitude != null) {
                const distKm = haversineDistance(lat, lon, Number(user.latitude), Number(user.longitude));
                distance_score = getDistanceScore(distKm);
            }

            // ── Rating score ──────────────────────────────────────────────
            const rating = typeof user.rating === 'number' ? user.rating : 0;
            const rating_score = Math.min(Math.max(rating / 5.0, 0), 1);

            // ── Popularity score ──────────────────────────────────────────
            const reviewsCount = typeof user.reviewsCount === 'number' ? user.reviewsCount : 0;
            const popularity_score = Math.min(reviewsCount / 50, 1.0);

            // ── Category match ────────────────────────────────────────────
            let category_match = 0;
            if (targetCategories.length > 0) {
                const skills = Array.isArray(user.skills) ? user.skills : [];
                const jobTitle = typeof user.jobTitle === 'string' ? user.jobTitle : '';
                
                const hasMatch = targetCategories.some(target => 
                    skills.some((s) => typeof s === 'string' && s.toLowerCase().includes(target)) ||
                    jobTitle.toLowerCase().includes(target)
                );
                
                if (hasMatch) {
                    category_match = 1.0;
                }
            } else {
                // If no interests/category, give a slight baseline score to show nearby/active people
                category_match = 0.5;
            }

            // ── Composite score ───────────────────────────────────────────
            const score =
                0.4 * distance_score +
                0.2 * rating_score +
                0.1 * popularity_score +
                0.3 * category_match;

            scored.push({
                userId: doc.id,
                name: user.name || null,
                rating: rating,
                reviewsCount: reviewsCount,
                role: user.role || null,
                jobTitle: user.jobTitle || null,
                profileImageUrl: user.profileImageUrl || null,
                score: Math.round(score * 1000) / 1000, // round to 3 dp
            });
        });

        // Sort descending by score and take top 10
        scored.sort((a, b) => b.score - a.score);
        const top10 = scored.slice(0, 10);
        const topUserIds = top10.map((u) => u.userId);

        // Persist recommendations to Firestore
        await db.collection('recommendations').doc(userId).set({
            userIds: topUserIds,
            calculatedAt: FieldValue.serverTimestamp(),
        });

        console.log(`calculateRecommendations: saved ${top10.length} recommendations for user ${userId}`);

        return {
            recommendations: top10,
            count: top10.length,
        };
    } catch (error) {
        console.error('calculateRecommendations error:', error);
        await logAudit('RECOMMENDATIONS_ERROR', userId, {
            status: 'error',
            errorMessage: error.message,
        });
        throw new HttpsError('internal', `Failed to calculate recommendations: ${error.message}`);
    }
});

// ─── Function: trackUserInteraction ──────────────────────────────────────────
/**
 * Callable Cloud Function: trackUserInteraction
 *
 * Records a user interaction event (view / contact / hire) into
 * user_interactions/{callerId}/events so the recommendation engine
 * can learn from real behaviour over time.
 *
 * Requires authentication.
 * Accepts { targetUserId, interactionType } where interactionType ∈ {'view','contact','hire'}.
 */
exports.trackUserInteraction = onCall(async (request) => {
    const callerUid = request.auth?.uid;
    if (!callerUid) {
        throw new HttpsError('unauthenticated', 'Must be logged in to track interactions');
    }

    const { targetUserId, interactionType } = request.data || {};

    if (!targetUserId || typeof targetUserId !== 'string') {
        throw new HttpsError('invalid-argument', 'targetUserId is required');
    }

    const VALID_TYPES = ['view', 'contact', 'hire'];
    if (!interactionType || !VALID_TYPES.includes(interactionType)) {
        throw new HttpsError(
            'invalid-argument',
            `interactionType must be one of: ${VALID_TYPES.join(', ')}`
        );
    }

    try {
        const eventRef = db
            .collection('user_interactions')
            .doc(callerUid)
            .collection('events')
            .doc();

        await eventRef.set({
            targetUserId,
            type: interactionType,
            timestamp: FieldValue.serverTimestamp(),
        });

        console.log(
            `trackUserInteraction: user ${callerUid} → ${interactionType} → ${targetUserId}`
        );

        return { success: true };
    } catch (error) {
        console.error('trackUserInteraction error:', error);
        throw new HttpsError('internal', `Failed to track interaction: ${error.message}`);
    }
});
