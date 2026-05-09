const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { FieldValue } = require("firebase-admin/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

const db = getFirestore();
const messaging = getMessaging();

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
                    icon: "@mipmap/launcher_icon",
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
);

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

        const { freelancerId, rating, isNegative } = review;
        if (!freelancerId) return null;

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
            });
            console.log(`Successfully updated ratings for freelancer ${freelancerId}`);
        } catch (error) {
            console.error(`Error updating ratings for freelancer ${freelancerId}:`, error);
        }
        return null;
    }
);

/**
 * Cloud Function: onJobUpdated
 * 
 * Safely increments completed jobs for the freelancer when a job is marked completed.
 */
exports.onJobUpdated = onDocumentUpdated(
    { document: "jobs/{jobId}", concurrency: 80 },
    async (event) => {
        const jobBefore = event.data.before.data();
        const jobAfter = event.data.after.data();

        if (!jobBefore || !jobAfter) return null;

        // If job just changed status to 'completed'
        if (jobBefore.status !== 'completed' && jobAfter.status === 'completed') {
            const freelancerId = jobAfter.assignedFreelancerId;
            if (!freelancerId) return null;

            const userRef = db.collection("users").doc(freelancerId);
            try {
                await userRef.update({
                    completedJobs: FieldValue.increment(1),
                    totalJobs: FieldValue.increment(1),
                    updatedAt: FieldValue.serverTimestamp()
                });
                console.log(`Successfully incremented completedJobs for ${freelancerId}`);
            } catch (error) {
                console.error(`Error incrementing completedJobs for ${freelancerId}:`, error);
            }
        }
        return null;
    }
);
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
                    icon: "@mipmap/launcher_icon",
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
);
