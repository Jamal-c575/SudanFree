const utils = require('./utils');
const { onDocumentCreated, onDocumentUpdated } = require('firebase-functions/v2/firestore');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { FieldValue } = require('firebase-admin/firestore');

const { logAudit, normalizeSudanesePhone, checkOTPRateLimit, checkOTPBruteForceLimit, recordFailedOTPVerification, isAdminUser, deleteUserFirestoreData, deleteUserStorageData, twilio, db, authAdmin, storage, getBucket, messaging, isProduction, RATE_LIMIT_WINDOW, RATE_LIMIT_MAX_ATTEMPTS, BRUTE_FORCE_WINDOW, BRUTE_FORCE_MAX_ATTEMPTS, twilioClient } = utils;

/**
 * Cloud Function: onNotificationCreated
 * 
 * Triggers when a new document is created in the 'notifications' collection.
 * Fetches the target user's FCM token and sends a push notification.
 * 
 * Handles: likes, comments, mentions, reviews, fraud warnings
 */
exports.onNotificationCreated = onDocumentCreated(
    { document: "notifications/{notificationId}", concurrency: 80 },
    async (event) => {
        const notification = event.data?.data();
        if (!notification) {
            console.log("No notification data found");
            return null;
        }

        const { userId, title, message, type, relatedId } = notification;

        if (!userId) {
            console.log("No userId in notification");
            return null;
        }

        // Fetch the target user's FCM token
        let userDoc;
        try {
            userDoc = await db.collection("users").doc(userId).get();
        } catch (error) {
            console.error("Error fetching user:", error);
            return null;
        }

        if (!userDoc.exists) {
            console.log(`User ${userId} not found`);
            return null;
        }

        const fcmToken = userDoc.data()?.fcmToken;
        if (!fcmToken) {
            console.log(`No FCM token for user ${userId}`);
            return null;
        }

        // Build the FCM message
        const fcmMessage = {
            token: fcmToken,
            notification: {
                title: title || "إشعار جديد",
                body: message || "",
            },
            data: {
                type: type || "general",
                relatedId: relatedId || "",
                notificationId: event.params.notificationId,
                click_action: "FLUTTER_NOTIFICATION_CLICK",
            },
            android: {
                priority: "high",
                notification: {
                    channelId: "sudan_free_channel",
                    priority: "high",
                    defaultSound: true,
                    defaultVibrateTimings: true,
                    icon: "@drawable/sudan1",
                },
            },
            apns: {
                payload: {
                    aps: {
                        alert: {
                            title: title || "إشعار جديد",
                            body: message || "",
                        },
                        badge: 1,
                        sound: "default",
                    },
                },
            },
        };

        // Send the push notification
        try {
            const response = await messaging.send(fcmMessage);
            console.log(`Push sent to user ${userId}:`, response);
            return response;
        } catch (error) {
            console.error(`Error sending push to user ${userId}:`, error);

            // If the token is invalid, clean it up
            if (
                error.code === "messaging/invalid-registration-token" ||
                error.code === "messaging/registration-token-not-registered"
            ) {
                console.log(`Removing invalid FCM token for user ${userId}`);
                try {
                    await db.collection("users").doc(userId).update({
                        fcmToken: null,
                    });
                } catch (updateError) {
                    console.error("Error removing invalid token:", updateError);
                }
            }

            return null;
        }
    }
);;

/**
 * Cloud Function: onReviewCreated
 * 
 * Accurately and securely recalculates a freelancer's average rating,
 * reviewsCount, and negativeReports when a new review is added.
 */
exports.onReviewCreated = onDocumentCreated(
    { document: "reviews/{reviewId}", concurrency: 80 },
    async (event) => {
        const review = event.data?.data();
        if (!review) return null;

        const { freelancerId, reviewerId, rating, isNegative } = review;
        if (!freelancerId || !reviewerId) return null;

        // ✅ Guard: check if the ratings doc has already been processed by the CF
        // This prevents double-counting if the CF runs more than once (CF retries)
        const ratingsDocId = `${reviewerId}_${freelancerId}`;
        const ratingsRef = db.collection("ratings").doc(ratingsDocId);
        const ratingsSnap = await ratingsRef.get();

        if (ratingsSnap.exists && ratingsSnap.data()?.cfProcessed === true) {
            console.log(`CF: Already processed rating for ${ratingsDocId} — skipping`);
            return null;
        }

        const userRef = db.collection("users").doc(freelancerId);

        try {
            await db.runTransaction(async (transaction) => {
                const userDoc = await transaction.get(userRef);
                if (!userDoc.exists) return;

                const userData = userDoc.data();
                const currentRating = userData.rating || 0.0;
                const currentCount = userData.reviewsCount || 0;
                const newCount = currentCount + 1;
                const newRating = ((currentRating * currentCount) + rating) / newCount;

                const updates = {
                    rating: newRating,
                    reviewsCount: newCount,
                    updatedAt: FieldValue.serverTimestamp(),
                };

                const roundedRating = Math.round(rating);
                if (roundedRating >= 1 && roundedRating <= 5) {
                    updates[`ratingCounts.${roundedRating}`] = FieldValue.increment(1);
                }

                if (isNegative) {
                    updates.negativeReports = FieldValue.increment(1);
                }

                transaction.update(userRef, updates);

                // ✅ Mark as processed to prevent CF retries from double-counting
                if (ratingsSnap.exists) {
                    transaction.update(ratingsRef, { cfProcessed: true });
                }
            });
            console.log(`CF: Successfully updated ratings for freelancer ${freelancerId} (avg=${((((userRef._path || '') + '') || ''))}, count+1)`);
        } catch (error) {
            console.error(`CF: Error updating ratings for freelancer ${freelancerId}:`, error);
        }
        return null;
    }
);;

/**
 * Cloud Function: onMessageCreated
 * 
 * Triggers when a new message is added to a chat's messages subcollection.
 * Sends a push notification to the receiver.
 */
exports.onMessageCreated = onDocumentCreated(
    { document: "chats/{chatId}/messages/{messageId}", concurrency: 80 },
    async (event) => {
        const messageData = event.data?.data();
        if (!messageData) {
            console.log("No message data found");
            return null;
        }

        const { senderName, receiverId, content, type } = messageData;

        if (!receiverId) {
            console.log("No receiverId in message");
            return null;
        }

        // Fetch the receiver user's FCM token
        let userDoc;
        try {
            userDoc = await db.collection("users").doc(receiverId).get();
        } catch (error) {
            console.error("Error fetching receiver user:", error);
            return null;
        }

        if (!userDoc.exists) {
            console.log(`Receiver user ${receiverId} not found`);
            return null;
        }

        const fcmToken = userDoc.data()?.fcmToken;
        if (!fcmToken) {
            console.log(`No FCM token for receiver ${receiverId}`);
            return null;
        }

        // Build the FCM message
        const bodyContent = type === "image" ? "📷 صورة" : (type === "file" ? "📎 ملف" : content);
        
        const fcmMessage = {
            token: fcmToken,
            notification: {
                title: senderName || "رسالة جديدة",
                body: bodyContent || "",
            },
            data: {
                type: "chat_message",
                chatId: event.params.chatId,
                senderName: senderName || "",
                click_action: "FLUTTER_NOTIFICATION_CLICK",
            },
            android: {
                priority: "high",
                notification: {
                    channelId: "sudan_free_chat_channel",
                    priority: "high",
                    defaultSound: true,
                    defaultVibrateTimings: true,
                    icon: "@drawable/sudan1",
                },
            },
            apns: {
                payload: {
                    aps: {
                        alert: {
                            title: senderName || "رسالة جديدة",
                            body: bodyContent || "",
                        },
                        badge: 1,
                        sound: "default",
                    },
                },
            },
        };

        // Send the push notification
        try {
            const response = await messaging.send(fcmMessage);
            console.log(`Chat push sent to receiver ${receiverId}:`, response);
            return response;
        } catch (error) {
            console.error(`Error sending chat push to receiver ${receiverId}:`, error);
            return null;
        }
    }
);;

/**
 * Callable Cloud Function: adminSendNotification
 * 
 * Sends a targeted push notification and creates in-app notifications
 * to a filtered segment of users.
 */
exports.adminSendNotification = onCall(async (request) => {
    // 1. Check if caller is admin
    const callerUid = request.auth?.uid;
    if (!callerUid) {
        throw new HttpsError('unauthenticated', 'Must be logged in');
    }

    const isAdmin = await isAdminUser(callerUid);
    if (!isAdmin) {
        throw new HttpsError('permission-denied', 'Must be an admin to send bulk notifications');
    }

    const { 
        title, 
        message, 
        targetRole, 
        targetJobTitle, 
        targetState, 
        targetLocality 
    } = request.data || {};

    if (!title || !message) {
        throw new HttpsError('invalid-argument', 'Title and message are required');
    }

    try {
        // 2. Build the query based on targeting filters
        let usersQuery = db.collection('users');

        if (targetRole && targetRole !== 'all') {
            usersQuery = usersQuery.where('role', '==', targetRole);
        }
        if (targetJobTitle && targetJobTitle !== 'all') {
            usersQuery = usersQuery.where('jobTitle', '==', targetJobTitle);
        }
        if (targetState && targetState !== 'all') {
            usersQuery = usersQuery.where('state', '==', targetState);
        }
        if (targetLocality && targetLocality !== 'all') {
            usersQuery = usersQuery.where('locality', '==', targetLocality);
        }

        // 3. Fetch matching users
        const querySnapshot = await usersQuery.get();
        if (querySnapshot.empty) {
            return { success: true, count: 0, message: 'No users matched the targeting criteria' };
        }

        const users = querySnapshot.docs;
        const tokens = [];
        const batchArray = [];
        let currentBatch = db.batch();
        let batchOperationCount = 0;

        // 4. Prepare tokens and Firestore notifications
        users.forEach((doc) => {
            const userData = doc.data();
            const fcmToken = userData.fcmToken;

            // Add FCM token if valid
            if (fcmToken && typeof fcmToken === 'string' && fcmToken.length > 10) {
                tokens.push(fcmToken);
            }

            // Prepare in-app notification doc
            const notifRef = db.collection('notifications').doc();
            currentBatch.set(notifRef, {
                userId: doc.id,
                type: 'system',
                title: title,
                message: message,
                isRead: false,
                createdAt: FieldValue.serverTimestamp(),
                relatedId: 'bulk_notification'
            });

            batchOperationCount++;
            
            // Commit batch if it reaches the limit of 500
            if (batchOperationCount === 490) {
                batchArray.push(currentBatch.commit());
                currentBatch = db.batch();
                batchOperationCount = 0;
            }
        });

        // Commit remaining batch
        if (batchOperationCount > 0) {
            batchArray.push(currentBatch.commit());
        }

        // Execute all batches
        await Promise.all(batchArray);

        // 5. Send FCM Multicast
        let successCount = 0;
        let failureCount = 0;

        if (tokens.length > 0) {
            // FCM multicast limits to 500 tokens per request
            const maxTokensPerRequest = 500;
            for (let i = 0; i < tokens.length; i += maxTokensPerRequest) {
                const tokenBatch = tokens.slice(i, i + maxTokensPerRequest);
                
                const fcmMessage = {
                    tokens: tokenBatch,
                    notification: {
                        title: title,
                        body: message,
                    },
                    data: {
                        type: 'system',
                        click_action: 'FLUTTER_NOTIFICATION_CLICK',
                    },
                    android: {
                        priority: 'high',
                        notification: {
                            channelId: 'sudan_free_channel',
                            defaultSound: true,
                            defaultVibrateTimings: true,
                            icon: '@drawable/sudan1',
                        },
                    },
                    apns: {
                        payload: {
                            aps: {
                                alert: { title, body: message },
                                sound: 'default',
                            },
                        },
                    },
                };

                const response = await messaging.sendEachForMulticast(fcmMessage);
                successCount += response.successCount;
                failureCount += response.failureCount;
                
                // Cleanup invalid tokens could be done here as well based on response.responses
            }
        }

        // 6. Log Audit
        const logData = {
            title,
            message,
            targetRole: targetRole || null,
            targetJobTitle: targetJobTitle || null,
            targetState: targetState || null,
            targetLocality: targetLocality || null,
            matchedUsers: users.length,
            fcmSent: successCount,
            fcmFailed: failureCount,
            createdAt: FieldValue.serverTimestamp(),
            adminId: callerUid
        };
        
        await db.collection('bulk_notifications').add(logData);

        await logAudit('BULK_NOTIFICATION_SENT', null, {
            adminId: callerUid,
            status: 'success',
            metadata: logData
        });

        return { 
            success: true, 
            matchedUsers: users.length,
            fcmSent: successCount,
            message: `Successfully notified ${users.length} users (${successCount} push notifications sent)` 
        };

    } catch (error) {
        console.error('Error sending bulk notification:', error);
        await logAudit('BULK_NOTIFICATION_ERROR', null, {
            adminId: callerUid,
            status: 'error',
            errorMessage: error.message
        });
        throw new HttpsError('internal', `Failed to send notifications: ${error.message}`);
    }
});;

/**
 * Scheduled Cloud Function: notifyNewLocalProviders
 * Runs every day at 19:00 (7 PM) Africa/Khartoum time.
 * Finds newly registered service providers in the last 24 hours,
 * groups them by locality, and sends a localized push notification to users in that locality.
 */
exports.notifyNewLocalProviders = onSchedule({
    schedule: "0 19 * * *",
    timeZone: "Africa/Khartoum",
    retryCount: 3
}, async (event) => {
    try {
        console.log("Starting daily check for new local providers...");
        
        const now = new Date();
        const yesterday = new Date(now.getTime() - (24 * 60 * 60 * 1000));
        
        // 1. Find new providers registered in the last 24 hours
        // We look for roles: freelancer, shop, privateService, techService
        const newProvidersSnapshot = await db.collection("users")
            .where("role", "in", ["freelancer", "shop", "privateService", "techService", "Freelancer", "Shop"])
            .where("createdAt", ">=", yesterday)
            .get();
            
        if (newProvidersSnapshot.empty) {
            console.log("No new providers registered in the last 24 hours.");
            return;
        }

        console.log(`Found ${newProvidersSnapshot.size} new providers.`);

        // 2. Group new providers by locality (or state if locality missing)
        const locationMap = {}; // { "Khartoum_Bahri": { count: 3, names: ["Ali", "ShopX"] } }
        
        newProvidersSnapshot.docs.forEach(doc => {
            const data = doc.data();
            const locationKey = data.locality || data.state;
            
            if (locationKey && typeof locationKey === 'string' && locationKey.trim() !== '') {
                const key = locationKey.trim();
                if (!locationMap[key]) {
                    locationMap[key] = { count: 0, names: [] };
                }
                locationMap[key].count++;
                if (data.name && locationMap[key].names.length < 2) {
                    locationMap[key].names.push(data.name); // Store up to 2 names for the message
                }
            }
        });

        const locations = Object.keys(locationMap);
        if (locations.length === 0) {
            console.log("New providers did not have valid localities/states.");
            return;
        }

        console.log(`Grouped new providers into ${locations.length} locations:`, locations);

        // 3. For each location, find users and send notification
        let totalNotificationsSent = 0;

        for (const loc of locations) {
            const info = locationMap[loc];
            // Build a catchy localized message
            const title = `مقدمي خدمات جدد في ${loc}! 📍`;
            let body = `انضم إلينا اليوم ${info.count} من المتاجر والحرفيين الجدد في ${loc}.`;
            if (info.names.length > 0) {
                body += ` رحبوا بـ ${info.names.join(' و')}!`;
            }

            console.log(`Processing location ${loc} -> Title: ${title}`);

            // Find all users in this locality to notify them (clients, other freelancers, etc.)
            // Note: If you have a huge userbase, you might need to paginate this query.
            const localUsersQuery1 = await db.collection("users").where("locality", "==", loc).get();
            const localUsersQuery2 = await db.collection("users").where("state", "==", loc).get();

            // Merge and deduplicate by document ID
            const usersMap = new Map();
            localUsersQuery1.docs.forEach(d => usersMap.set(d.id, d.data()));
            localUsersQuery2.docs.forEach(d => usersMap.set(d.id, d.data()));

            const tokens = [];
            usersMap.forEach((userData, userId) => {
                if (userData.fcmToken && typeof userData.fcmToken === 'string' && userData.fcmToken.length > 10) {
                    tokens.push(userData.fcmToken);
                }
            });

            if (tokens.length === 0) {
                console.log(`No users with FCM tokens found in ${loc}.`);
                continue;
            }

            // Send FCM Multicast
            const maxTokensPerRequest = 500;
            for (let i = 0; i < tokens.length; i += maxTokensPerRequest) {
                const tokenBatch = tokens.slice(i, i + maxTokensPerRequest);
                
                const fcmMessage = {
                    tokens: tokenBatch,
                    notification: {
                        title: title,
                        body: body,
                    },
                    data: {
                        type: 'system',
                        click_action: 'FLUTTER_NOTIFICATION_CLICK',
                    },
                    android: {
                        priority: 'high',
                        notification: {
                            channelId: 'sudan_free_channel',
                            defaultSound: true,
                            defaultVibrateTimings: true,
                            icon: '@drawable/sudan1',
                        },
                    },
                    apns: {
                        payload: {
                            aps: {
                                alert: { title, body },
                                sound: 'default',
                            },
                        },
                    },
                };

                try {
                    const response = await messaging.sendEachForMulticast(fcmMessage);
                    totalNotificationsSent += response.successCount;
                    console.log(`Sent to ${response.successCount} users in ${loc}`);
                } catch (err) {
                    console.error(`Error sending to ${loc}:`, err);
                }
            }
        }

        console.log(`Daily local providers notification completed. Total sent: ${totalNotificationsSent}`);
        
        await logAudit('DAILY_LOCAL_PROVIDERS_NOTIF', null, {
            status: 'success',
            metadata: { locationsProcessed: locations.length, totalSent: totalNotificationsSent }
        });

    } catch (error) {
        console.error('Error in notifyNewLocalProviders schedule:', error);
        await logAudit('DAILY_LOCAL_PROVIDERS_ERROR', null, {
            status: 'error',
            errorMessage: error.message
        });
    }
});;

