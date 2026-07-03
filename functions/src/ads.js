const utils = require('./utils');
const { onDocumentCreated, onDocumentUpdated } = require('firebase-functions/v2/firestore');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { FieldValue } = require('firebase-admin/firestore');

const { logAudit, normalizeSudanesePhone, checkOTPRateLimit, checkOTPBruteForceLimit, recordFailedOTPVerification, isAdminUser, deleteUserFirestoreData, deleteUserStorageData, twilio, db, authAdmin, storage, getBucket, messaging, isProduction, RATE_LIMIT_WINDOW, RATE_LIMIT_MAX_ATTEMPTS, BRUTE_FORCE_WINDOW, BRUTE_FORCE_MAX_ATTEMPTS, twilioClient } = utils;

/**
 * Cloud Function: onAdCreated
 * 
 * Sends a global push notification to all users when a new Ad is created.
 */
exports.onAdCreated = onDocumentCreated(
    { document: "ads/{adId}", concurrency: 80 },
    async (event) => {
        const ad = event.data?.data();
        if (!ad) return null;

        if (ad.isActive === false) return null;
        if (ad.silentNotification === true) return null;

        const fcmMessage = {
            topic: "all_users",
            notification: {
                title: ad.title || "إعلان جديد! 📣",
                body: ad.description || "تصفح أحدث الإعلانات في تطبيق سودان فري",
            },
            data: {
                type: "ad",
                relatedId: event.params.adId,
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
                            title: ad.title || "إعلان جديد! 📣",
                            body: ad.description || "تصفح أحدث الإعلانات",
                        },
                        badge: 1,
                        sound: "default",
                    },
                },
            },
        };

        try {
            const response = await messaging.send(fcmMessage);
            console.log(`Global ad push sent to all_users:`, response);
            return response;
        } catch (error) {
            console.error(`Error sending global ad push:`, error);
            return null;
        }
    }
);;

