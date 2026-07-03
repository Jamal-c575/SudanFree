const utils = require('./utils');
const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { FieldValue } = require('firebase-admin/firestore');

const { db, logAudit } = utils;

// ─── Constants ─────────────────────────────────────────────────────────────
const REVIEW_WINDOW_HOURS = 24;
const MAX_REVIEWS_PER_WINDOW = 3;
const MIN_ACCOUNT_AGE_DAYS = 7;
const HIGH_RISK_SCORE_THRESHOLD = 5;

// ─── Function: analyzeReview ──────────────────────────────────────────────────
/**
 * Firestore Trigger: analyzeReview
 *
 * Fires when a new document is created in the `reviews` collection.
 * Applies two fraud signals:
 *   1. New account (< 7 days) leaving a 5-star review → suspicious
 *   2. More than 3 reviews submitted in the last 24 hours → suspicious
 *
 * If flagged, marks the review as suspicious and increments the reviewed
 * user's risk_score by 1.
 */
exports.analyzeReview = onDocumentCreated(
    { document: 'reviews/{reviewId}', concurrency: 40 },
    async (event) => {
        const review = event.data?.data();
        if (!review) {
            console.log('analyzeReview: no review data found, skipping');
            return null;
        }

        const reviewId = event.params.reviewId;
        const { reviewerId, freelancerId, rating } = review;

        if (!reviewerId || !freelancerId) {
            console.log(`analyzeReview: missing reviewerId or freelancerId on review ${reviewId}`);
            return null;
        }

        let isSuspicious = false;
        const suspiciousReasons = [];

        try {
            // ── Signal 1: New account with 5-star review ──────────────────
            const reviewerDoc = await db.collection('users').doc(reviewerId).get();
            if (reviewerDoc.exists) {
                const reviewerData = reviewerDoc.data();
                const createdAt = reviewerData?.createdAt;

                if (createdAt) {
                    const createdAtMs = createdAt.toMillis
                        ? createdAt.toMillis()
                        : new Date(createdAt).getTime();
                    const accountAgeMs = Date.now() - createdAtMs;
                    const accountAgeDays = accountAgeMs / (1000 * 60 * 60 * 24);

                    if (accountAgeDays < MIN_ACCOUNT_AGE_DAYS && Number(rating) === 5) {
                        isSuspicious = true;
                        suspiciousReasons.push(
                            `New account (${Math.floor(accountAgeDays)} days old) left a 5-star review`
                        );
                        console.log(
                            `analyzeReview [${reviewId}]: Signal 1 triggered — new account ${reviewerId}`
                        );
                    }
                }
            } else {
                console.warn(`analyzeReview: reviewer ${reviewerId} not found in users collection`);
            }

            // ── Signal 2: More than 3 reviews in the last 24 hours ────────
            const windowStart = new Date(Date.now() - REVIEW_WINDOW_HOURS * 60 * 60 * 1000);
            const recentReviewsSnap = await db
                .collection('reviews')
                .where('reviewerId', '==', reviewerId)
                .where('createdAt', '>=', windowStart)
                .get();

            // Count includes the current review that just triggered this function,
            // but Firestore may or may not have indexed it yet — we use > to be safe.
            if (recentReviewsSnap.size > MAX_REVIEWS_PER_WINDOW) {
                isSuspicious = true;
                suspiciousReasons.push(
                    `Reviewer submitted ${recentReviewsSnap.size} reviews in the last ${REVIEW_WINDOW_HOURS}h (limit: ${MAX_REVIEWS_PER_WINDOW})`
                );
                console.log(
                    `analyzeReview [${reviewId}]: Signal 2 triggered — ${recentReviewsSnap.size} reviews in 24h by ${reviewerId}`
                );
            }

            // ── Apply fraud flags if suspicious ───────────────────────────
            if (isSuspicious) {
                const suspiciousReason = suspiciousReasons.join('; ');

                // Update the review document
                await db.collection('reviews').doc(reviewId).update({
                    isSuspicious: true,
                    suspiciousReason,
                    flaggedAt: FieldValue.serverTimestamp(),
                });

                // Increment the reviewed user's risk_score
                await db.collection('users').doc(freelancerId).update({
                    risk_score: FieldValue.increment(1),
                });

                // Audit log
                await logAudit('SUSPICIOUS_REVIEW_DETECTED', reviewerId, {
                    status: 'flagged',
                    metadata: {
                        reviewId,
                        freelancerId,
                        rating,
                        reasons: suspiciousReasons,
                    },
                });

                console.log(
                    `analyzeReview [${reviewId}]: Flagged as suspicious — "${suspiciousReason}"`
                );
            } else {
                console.log(`analyzeReview [${reviewId}]: No fraud signals detected`);
            }
        } catch (error) {
            console.error(`analyzeReview [${reviewId}]: Error during analysis:`, error);
            await logAudit('FRAUD_ANALYSIS_ERROR', reviewerId, {
                status: 'error',
                errorMessage: error.message,
                metadata: { reviewId },
            });
        }

        return null;
    }
);

// ─── Function: getUserRiskScore ───────────────────────────────────────────────
/**
 * Callable Cloud Function: getUserRiskScore
 *
 * Returns the risk_score for a given userId from the users collection.
 * If risk_score >= 5 the response also includes { shouldWarn: true } so
 * the client can display an appropriate warning to the viewer.
 *
 * Requires authentication.
 * Accepts { userId }.
 */
exports.getUserRiskScore = onCall(async (request) => {
    const callerUid = request.auth?.uid;
    if (!callerUid) {
        throw new HttpsError('unauthenticated', 'Must be logged in');
    }

    const { userId } = request.data || {};
    if (!userId || typeof userId !== 'string') {
        throw new HttpsError('invalid-argument', 'userId is required');
    }

    try {
        const userDoc = await db.collection('users').doc(userId).get();
        if (!userDoc.exists) {
            throw new HttpsError('not-found', `User ${userId} not found`);
        }

        const userData = userDoc.data();
        const risk_score = typeof userData.risk_score === 'number' ? userData.risk_score : 0;
        const shouldWarn = risk_score >= HIGH_RISK_SCORE_THRESHOLD;

        console.log(
            `getUserRiskScore: user ${userId} has risk_score=${risk_score}, shouldWarn=${shouldWarn}`
        );

        return {
            userId,
            risk_score,
            shouldWarn,
        };
    } catch (error) {
        if (error instanceof HttpsError) throw error;
        console.error('getUserRiskScore error:', error);
        throw new HttpsError('internal', `Failed to get risk score: ${error.message}`);
    }
});
