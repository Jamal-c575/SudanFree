const utils = require('./utils');
const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { FieldValue } = require('firebase-admin/firestore');

const { db, messaging, logAudit } = utils;

// ─── Helper: Build FCM message ────────────────────────────────────────────────
function buildFcmMessage(token, title, body, extraData = {}) {
    return {
        token,
        notification: { title, body },
        data: {
            type: 'system',
            click_action: 'FLUTTER_NOTIFICATION_CLICK',
            ...extraData,
        },
        android: {
            priority: 'high',
            notification: {
                channelId: 'sudan_free_channel',
                priority: 'high',
                defaultSound: true,
                defaultVibrateTimings: true,
                icon: '@drawable/sudan1',
            },
        },
        apns: {
            payload: {
                aps: {
                    alert: { title, body },
                    badge: 1,
                    sound: 'default',
                },
            },
        },
    };
}

// ─── Helper: Haversine Distance (km) ─────────────────────────────────────────
function haversineDistance(lat1, lon1, lat2, lon2) {
    const R = 6371;
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

// ─── Function: notifyUsersAboutNewProviders ───────────────────────────────────
/**
 * Scheduled Cloud Function: notifyUsersAboutNewProviders
 *
 * Runs every day at 09:00 (Africa/Khartoum).
 * For each user who has serviceInterests or shopInterests set, it finds
 * newly-registered providers (created in the last 24 h) that match their
 * interests AND are within a configurable nearby radius (50 km by default).
 * If any matching providers are found, an FCM notification is sent.
 */
exports.notifyUsersAboutNewProviders = onSchedule(
    {
        schedule: '0 9 * * *',
        timeZone: 'Africa/Khartoum',
        retryCount: 2,
    },
    async (event) => {
        const NEARBY_RADIUS_KM = 50;
        const now = new Date();
        const yesterday = new Date(now.getTime() - 24 * 60 * 60 * 1000);

        console.log('notifyUsersAboutNewProviders: starting scheduled job');

        try {
            // 1. Fetch all new providers created in the last 24 h
            const newProvidersSnap = await db
                .collection('users')
                .where('role', 'in', [
                    'freelancer',
                    'shop',
                    'Freelancer',
                    'Shop',
                    'privateService',
                    'techService',
                ])
                .where('createdAt', '>=', yesterday)
                .get();

            if (newProvidersSnap.empty) {
                console.log('notifyUsersAboutNewProviders: no new providers in the last 24h');
                return;
            }

            const newProviders = newProvidersSnap.docs.map((d) => ({ id: d.id, ...d.data() }));
            console.log(`notifyUsersAboutNewProviders: found ${newProviders.length} new provider(s)`);

            // 2. Fetch users who have interests defined
            const interestedUsersSnap = await db.collection('users').get();
            let notifsSent = 0;

            for (const userDoc of interestedUsersSnap.docs) {
                const user = userDoc.data();
                const userId = userDoc.id;

                // Combine both interest arrays into a normalised set
                const rawInterests = [
                    ...(Array.isArray(user.serviceInterests) ? user.serviceInterests : []),
                    ...(Array.isArray(user.shopInterests) ? user.shopInterests : []),
                ];

                if (rawInterests.length === 0) continue;
                if (!user.fcmToken || typeof user.fcmToken !== 'string' || user.fcmToken.length < 10) continue;

                const interests = rawInterests.map((i) => (typeof i === 'string' ? i.toLowerCase() : ''));

                // 3. Find matching new providers near this user
                const userLat = typeof user.latitude === 'number' ? user.latitude : null;
                const userLon = typeof user.longitude === 'number' ? user.longitude : null;

                const matchingByCategory = {};

                for (const provider of newProviders) {
                    // Skip the user themselves
                    if (provider.id === userId) continue;

                    // Geographic filter (only when both have coordinates)
                    if (userLat !== null && userLon !== null) {
                        const pLat = typeof provider.latitude === 'number' ? provider.latitude : null;
                        const pLon = typeof provider.longitude === 'number' ? provider.longitude : null;
                        if (pLat !== null && pLon !== null) {
                            const distKm = haversineDistance(userLat, userLon, pLat, pLon);
                            if (distKm > NEARBY_RADIUS_KM) continue;
                        }
                    }

                    // Category/interest match
                    const providerSkills = Array.isArray(provider.skills) ? provider.skills : [];
                    const providerJobTitle =
                        typeof provider.jobTitle === 'string' ? provider.jobTitle.toLowerCase() : '';

                    for (const interest of interests) {
                        if (!interest) continue;
                        const matched =
                            providerSkills.some(
                                (s) => typeof s === 'string' && s.toLowerCase() === interest
                            ) || providerJobTitle === interest;

                        if (matched) {
                            if (!matchingByCategory[interest]) {
                                matchingByCategory[interest] = 0;
                            }
                            matchingByCategory[interest]++;
                        }
                    }
                }

                // 4. If there are matches, send one notification per top category
                const categories = Object.keys(matchingByCategory);
                if (categories.length === 0) continue;

                // Pick the category with the most matches
                categories.sort((a, b) => matchingByCategory[b] - matchingByCategory[a]);
                const topCategory = categories[0];
                const count = matchingByCategory[topCategory];

                const title = 'حرفيون جدد في منطقتك';
                const body = `${count} حرفي جديد يقدم ${topCategory} قريب منك`;

                try {
                    const fcmMsg = buildFcmMessage(user.fcmToken, title, body, {
                        category: topCategory,
                        count: String(count),
                    });
                    await messaging.send(fcmMsg);
                    notifsSent++;
                    console.log(
                        `notifyUsersAboutNewProviders: sent to user ${userId} (${topCategory}, ${count} providers)`
                    );
                } catch (sendErr) {
                    // Invalid / expired token — clean up silently
                    if (
                        sendErr.code === 'messaging/invalid-registration-token' ||
                        sendErr.code === 'messaging/registration-token-not-registered'
                    ) {
                        console.warn(
                            `notifyUsersAboutNewProviders: removing invalid FCM token for user ${userId}`
                        );
                        await db
                            .collection('users')
                            .doc(userId)
                            .update({ fcmToken: null })
                            .catch((e) => console.error('Failed to clear token:', e));
                    } else {
                        console.error(
                            `notifyUsersAboutNewProviders: FCM error for user ${userId}:`,
                            sendErr
                        );
                    }
                }
            }

            console.log(`notifyUsersAboutNewProviders: completed — ${notifsSent} notification(s) sent`);

            await logAudit('NEW_PROVIDERS_NOTIFICATIONS_SENT', null, {
                status: 'success',
                metadata: {
                    newProviders: newProviders.length,
                    notificationsSent: notifsSent,
                },
            });
        } catch (error) {
            console.error('notifyUsersAboutNewProviders: error:', error);
            await logAudit('NEW_PROVIDERS_NOTIFICATIONS_ERROR', null, {
                status: 'error',
                errorMessage: error.message,
            });
        }
    }
);

// ─── Function: sendWelcomeNotification ───────────────────────────────────────
/**
 * Firestore Trigger: sendWelcomeNotification
 *
 * Fires when a new document is created in the `users` collection.
 * Sends a welcome FCM push notification to the new user's fcmToken
 * (if present).
 */
exports.sendWelcomeNotification = onDocumentCreated(
    { document: 'users/{userId}', concurrency: 80 },
    async (event) => {
        const userId = event.params.userId;
        const userData = event.data?.data();

        if (!userData) {
            console.log(`sendWelcomeNotification: no data for user ${userId}`);
            return null;
        }

        const fcmToken = userData.fcmToken;
        if (!fcmToken || typeof fcmToken !== 'string' || fcmToken.length < 10) {
            console.log(`sendWelcomeNotification: no valid FCM token for user ${userId}`);
            return null;
        }

        const title = 'مرحباً بك في سودان فري 🎉';
        const body = 'ابدأ رحلتك الآن واكتشف آلاف الحرفيين والخدمات';

        try {
            const fcmMsg = buildFcmMessage(fcmToken, title, body, {
                type: 'welcome',
                userId,
            });
            const response = await messaging.send(fcmMsg);
            console.log(`sendWelcomeNotification: welcome push sent to user ${userId}:`, response);
        } catch (error) {
            console.error(`sendWelcomeNotification: error sending to user ${userId}:`, error);

            // Clean up invalid token
            if (
                error.code === 'messaging/invalid-registration-token' ||
                error.code === 'messaging/registration-token-not-registered'
            ) {
                await db
                    .collection('users')
                    .doc(userId)
                    .update({ fcmToken: null })
                    .catch((e) => console.error('Failed to clear token:', e));
            }
        }

        return null;
    }
);
