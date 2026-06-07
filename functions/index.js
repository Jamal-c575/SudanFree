const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { FieldValue } = require("firebase-admin/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getAuth } = require("firebase-admin/auth");
const { getStorage } = require("firebase-admin/storage");
const { getMessaging } = require("firebase-admin/messaging");
const twilio = require("twilio");

initializeApp();

const db = getFirestore();
const authAdmin = getAuth();
const storage = getStorage();
const getBucket = () => storage.bucket('sudanfree-d04fc.appspot.com');
const messaging = getMessaging();

// Development flag: set IS_PRODUCTION=true in prod env
const isProduction = process.env.IS_PRODUCTION === 'true' || process.env.NODE_ENV === 'production';

// ─── Twilio Client (Production Only) ───────────────────────────────────
let twilioClient = null;
if (isProduction && process.env.TWILIO_ACCOUNT_SID && process.env.TWILIO_AUTH_TOKEN) {
    twilioClient = twilio(
        process.env.TWILIO_ACCOUNT_SID,
        process.env.TWILIO_AUTH_TOKEN
    );
    console.log("✓ Twilio client initialized for production OTP delivery");
} else if (isProduction) {
    console.warn("⚠️ WARNING: Production mode enabled but Twilio credentials missing. OTP will not be sent!");
} else {
    console.log("✓ Development mode: OTP delivery disabled, using debug codes");
}

// ─── Rate Limiting Configuration ───────────────────────────────────────
const RATE_LIMIT_WINDOW = 10 * 60 * 1000; // 10 minutes
const RATE_LIMIT_MAX_ATTEMPTS = 3;
const BRUTE_FORCE_WINDOW = 15 * 60 * 1000; // 15 minutes
const BRUTE_FORCE_MAX_ATTEMPTS = 5;

// ─── Helper: Audit Logging ────────────────────────────────────────────
/**
 * Logs important events for compliance and debugging
 * @param {string} action - Action performed (e.g., 'OTP_SENT', 'OTP_VERIFIED', 'USER_DELETED')
 * @param {string} userId - User ID (optional for OTP pre-auth)
 * @param {object} details - Additional context
 */
async function logAudit(action, userId = null, details = {}) {
    try {
        await db.collection('audit_logs').add({
            action,
            userId: userId || null,
            phoneNumber: details.phoneNumber || null,
            status: details.status || 'success',
            errorMessage: details.errorMessage || null,
            timestamp: FieldValue.serverTimestamp(),
            ipAddress: details.ipAddress || null,
            adminId: details.adminId || null,
            details: details.metadata || {}
        });
    } catch (error) {
        console.error(`Failed to log audit event ${action}:`, error);
        // Don't throw - audit failure shouldn't block main flow
    }
}

function normalizeSudanesePhone(phoneNumber) {
    const digits = phoneNumber.replace(/\D+/g, '');
    if (digits.startsWith('249') && digits.length === 12) {
        return `+${digits}`;
    }
    if (digits.startsWith('0') && digits.length === 10) {
        return `+249${digits.slice(1)}`;
    }
    if (digits.startsWith('9') && digits.length === 9) {
        return `+249${digits}`;
    }
    return null;
}

// ─── Helper: Rate Limiting ────────────────────────────────────────────
/**
 * Checks if phone number has exceeded OTP request limit
 * Throws HttpsError if limit exceeded
 */
async function checkOTPRateLimit(phoneNumber) {
    const normalizedPhone = normalizeSudanesePhone(phoneNumber);
    if (!normalizedPhone) {
        throw new HttpsError('invalid-argument', 'Invalid Sudanese phone number format');
    }
    const limitKey = `otp_send_${normalizedPhone}`;
    const limitDoc = db.collection('_rate_limits').doc(limitKey);
    
    try {
        const doc = await limitDoc.get();
        const now = Date.now();
        
        if (doc.exists) {
            const data = doc.data();
            const windowExpiry = data.resetAt.toMillis ? data.resetAt.toMillis() : data.resetAt.getTime();
            
            if (windowExpiry > now) {
                // Window still active
                if (data.count >= RATE_LIMIT_MAX_ATTEMPTS) {
                    await logAudit('OTP_REQUEST_BLOCKED', null, {
                        phoneNumber,
                        status: 'blocked',
                        errorMessage: 'Rate limit exceeded',
                        metadata: { attempt: data.count }
                    });
                    throw new HttpsError(
                        'resource-exhausted',
                        `Too many OTP requests. Please try again in ${Math.ceil((windowExpiry - now) / 60000)} minutes.`
                    );
                }
                // Increment counter
                await limitDoc.update({ count: FieldValue.increment(1) });
            } else {
                // Window expired, reset
                await limitDoc.set({
                    count: 1,
                    resetAt: new Date(now + RATE_LIMIT_WINDOW)
                });
            }
        } else {
            // First request, create new limit doc
            await limitDoc.set({
                count: 1,
                resetAt: new Date(now + RATE_LIMIT_WINDOW),
                createdAt: FieldValue.serverTimestamp()
            });
        }
    } catch (error) {
        if (error instanceof HttpsError) throw error;
        console.error('Rate limit check error:', error);
        // On error, allow request but log it
        await logAudit('OTP_RATE_LIMIT_ERROR', null, {
            phoneNumber,
            status: 'error',
            errorMessage: error.message
        });
    }
}

// ─── Helper: Brute-Force Protection ────────────────────────────────────
/**
 * Checks if phone number has exceeded OTP verification attempts
 * Throws HttpsError if limit exceeded
 */
async function checkOTPBruteForceLimit(phoneNumber) {
    const normalizedPhone = normalizeSudanesePhone(phoneNumber);
    if (!normalizedPhone) {
        throw new HttpsError('invalid-argument', 'Invalid Sudanese phone number format');
    }
    const bruteForceKey = `otp_verify_${normalizedPhone}`;
    const bruteForceDoc = db.collection('_brute_force_attempts').doc(bruteForceKey);
    
    try {
        const doc = await bruteForceDoc.get();
        const now = Date.now();
        
        if (doc.exists) {
            const data = doc.data();
            const windowExpiry = data.resetAt.toMillis ? data.resetAt.toMillis() : data.resetAt.getTime();
            
            if (windowExpiry > now && data.count >= BRUTE_FORCE_MAX_ATTEMPTS) {
                await logAudit('OTP_VERIFY_BLOCKED', null, {
                    phoneNumber,
                    status: 'blocked',
                    errorMessage: 'Too many failed verification attempts',
                    metadata: { attemptCount: data.count }
                });
                throw new HttpsError(
                    'permission-denied',
                    'Too many failed verification attempts. Request a new OTP and try again.'
                );
            }
        }
    } catch (error) {
        if (error instanceof HttpsError) throw error;
        console.error('Brute-force check error:', error);
    }
}

// ─── Helper: Record Failed OTP Verification ────────────────────────────
async function recordFailedOTPVerification(phoneNumber) {
    const normalizedPhone = normalizeSudanesePhone(phoneNumber);
    if (!normalizedPhone) {
        return;
    }
    const bruteForceKey = `otp_verify_${normalizedPhone}`;
    const bruteForceDoc = db.collection('_brute_force_attempts').doc(bruteForceKey);
    
    try {
        const doc = await bruteForceDoc.get();
        const now = Date.now();
        
        if (doc.exists) {
            const data = doc.data();
            const windowExpiry = data.resetAt.toMillis ? data.resetAt.toMillis() : data.resetAt.getTime();
            
            if (windowExpiry > now) {
                await bruteForceDoc.update({ count: FieldValue.increment(1) });
            } else {
                // Reset counter on new window
                await bruteForceDoc.set({
                    count: 1,
                    resetAt: new Date(now + BRUTE_FORCE_WINDOW)
                });
            }
        } else {
            // First failed attempt
            await bruteForceDoc.set({
                count: 1,
                resetAt: new Date(now + BRUTE_FORCE_WINDOW),
                createdAt: FieldValue.serverTimestamp()
            });
        }
    } catch (error) {
        console.error('Failed to record OTP verification attempt:', error);
    }
}

async function isAdminUser(uid) {
    const userDoc = await db.collection('users').doc(uid).get();
    return userDoc.exists && userDoc.data()?.role === 'admin';
}

async function deleteUserFirestoreData(userId) {
    const allRefs = [];
    const posts = await db.collection('posts').where('userId', '==', userId).get();
    allRefs.push(...posts.docs.map(d => d.ref));

    const comments = await db.collectionGroup('comments').where('userId', '==', userId).get();
    allRefs.push(...comments.docs.map(d => d.ref));

    const reviews = await db.collection('reviews').where('reviewerId', '==', userId).get();
    allRefs.push(...reviews.docs.map(d => d.ref));

    const notifications = await db.collection('notifications').where('userId', '==', userId).get();
    allRefs.push(...notifications.docs.map(d => d.ref));

    const reports = await db.collection('reports').where('reporterId', '==', userId).get();
    allRefs.push(...reports.docs.map(d => d.ref));

    const deletionRequests = await db.collection('deletion_requests').where('userId', '==', userId).get();
    allRefs.push(...deletionRequests.docs.map(d => d.ref));

    const portfolio = await db.collection('users').doc(userId).collection('portfolio').get();
    allRefs.push(...portfolio.docs.map(d => d.ref));

    const settings = await db.collection('users').doc(userId).collection('settings').get();
    allRefs.push(...settings.docs.map(d => d.ref));

    allRefs.push(db.collection('users').doc(userId));

    for (let i = 0; i < allRefs.length; i += 400) {
        const batch = db.batch();
        const end = Math.min(i + 400, allRefs.length);
        for (let j = i; j < end; j += 1) {
            batch.delete(allRefs[j]);
        }
        await batch.commit();
    }
}

async function deleteUserStorageData(userId) {
    const prefixes = [
        `users/profile/${userId}`,
        `users/portfolio/${userId}`,
        `users/portfolio_videos/${userId}`,
        `users/verifications/${userId}`,
    ];

    for (const prefix of prefixes) {
        const [files] = await getBucket().getFiles({ prefix });
        if (!files.length) continue;
        await Promise.all(files.map((file) => file.delete().catch((error) => {
            console.error(`Failed to delete file at ${file.name}:`, error);
        })));
    }
}

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
);

/**
 * Callable Cloud Function: sendWhatsAppOTP
 *
 * Sends an OTP code via WhatsApp or SMS for user verification
 * 
 * Production: Sends real OTP via Twilio (requires TWILIO_* env vars)
 * Development: Returns debug code without sending (set IS_PRODUCTION=false)
 * 
 * Rate Limited: Max 3 requests per phone number per 10 minutes
 */
exports.sendWhatsAppOTP = onCall(async (request) => {
    const { phoneNumber, method = 'whatsapp' } = request.data || {};
    
    if (!phoneNumber || typeof phoneNumber !== 'string') {
        throw new HttpsError('invalid-argument', 'Valid phone number is required');
    }

    const normalizedPhone = normalizeSudanesePhone(phoneNumber);
    if (!normalizedPhone) {
        throw new HttpsError('invalid-argument', 'Invalid Sudanese phone number format');
    }

    try {
        // ─── PHASE 1: Rate Limiting ───────────────────────────────────────
        await checkOTPRateLimit(normalizedPhone);

        // Generate 6-digit OTP
        const otp = Math.floor(100000 + Math.random() * 900000).toString();
        
        // Store OTP in Firestore with expiration (5 minutes)
        const otpDoc = {
            phoneNumber: normalizedPhone,
            otp: otp,
            method: method,
            createdAt: FieldValue.serverTimestamp(),
            expiresAt: new Date(Date.now() + 5 * 60 * 1000), // 5 minutes
            used: false,
            deliveryAttempts: 1
        };

        // ─── PHASE 2: Send via Twilio (Production) or Debug (Dev) ────────
        let deliveryStatus = 'queued';
        let deliveryMessageSid = null;

        if (isProduction && twilioClient) {
            try {
                let message;
                if (method === 'whatsapp') {
                    message = await twilioClient.messages.create({
                        body: `Your SudanFree verification code is: ${otp}\n\nValid for 5 minutes. Do not share this code.`,
                        from: `whatsapp:${process.env.TWILIO_WHATSAPP_NUMBER}`,
                        to: `whatsapp:${normalizedPhone}`
                    });
                } else {
                    // SMS fallback
                    message = await twilioClient.messages.create({
                        body: `Your SudanFree verification code is: ${otp}. Valid for 5 minutes.`,
                        from: process.env.TWILIO_SMS_NUMBER,
                        to: normalizedPhone
                    });
                }
                
                deliveryStatus = 'sent';
                deliveryMessageSid = message.sid;
                console.log(`✓ OTP sent via ${method} to ${normalizedPhone} (SID: ${message.sid})`);
                
            } catch (twilioError) {
                deliveryStatus = 'failed';
                console.error(`✗ Twilio delivery error for ${phoneNumber}:`, twilioError.message);
                
                // Log but continue - store OTP for retry
                await logAudit('OTP_TWILIO_DELIVERY_ERROR', null, {
                    phoneNumber,
                    method,
                    status: 'failed',
                    errorMessage: twilioError.message
                });
            }
        } else if (!isProduction) {
            // Development mode: no actual delivery
            deliveryStatus = 'debug_mode';
            console.log(`[DEV] OTP for ${phoneNumber}: ${otp}`);
        } else {
            deliveryStatus = 'production_no_credentials';
            console.warn(`[WARN] Production mode but no Twilio credentials. OTP not sent to ${phoneNumber}`);
        }

        otpDoc.deliveryStatus = deliveryStatus;
        if (deliveryMessageSid) otpDoc.deliveryMessageSid = deliveryMessageSid;

        // Store OTP record
        const docRef = await db.collection('otp_codes').add(otpDoc);

        // ─── PHASE 3: Audit Logging ───────────────────────────────────────
        await logAudit('OTP_SENT', null, {
            phoneNumber,
            method,
            status: 'success',
            deliveryStatus,
            metadata: {
                otpDocId: docRef.id,
                messageSid: deliveryMessageSid
            }
        });

        // Prepare response
        const response = {
            success: true,
            message: isProduction 
                ? `OTP sent via ${method.toUpperCase()}`
                : 'OTP generated (development mode)',
            expiresIn: 300, // 5 minutes in seconds
            deliveryStatus,
            method
        };

        if (!isProduction) {
            // Development mode: return debug OTP
            await db.collection('otp_debug_codes').add({
                phoneNumber: phoneNumber,
                otp: otp,
                method: method,
                createdAt: FieldValue.serverTimestamp(),
                expiresAt: new Date(Date.now() + 5 * 60 * 1000),
                used: false,
                environment: 'development',
                docRefId: docRef.id
            });
            response.debugOtp = otp;
            response.note = 'DEBUG MODE: Use debugOtp above. In production, user receives code via Twilio.';
        }

        return response;

    } catch (error) {
        if (error instanceof HttpsError) {
            // Rate limit or validation errors
            throw error;
        }

        console.error('Error in sendWhatsAppOTP:', error);
        
        await logAudit('OTP_SEND_ERROR', null, {
            phoneNumber,
            status: 'error',
            errorMessage: error.message
        });

        throw new HttpsError('internal', 'Failed to send OTP');
    }
});

/**
 * Callable Cloud Function: verifyWhatsAppOTP
 *
 * Verifies the OTP code sent via WhatsApp/SMS
 * 
 * Rate Limited: Max 5 failed verification attempts per phone per 15 minutes
 * Audited: All verification attempts logged for security analysis
 */
exports.verifyWhatsAppOTP = onCall(async (request) => {
    const { phoneNumber, otp } = request.data || {};
    
    if (!phoneNumber || !otp || typeof phoneNumber !== 'string' || typeof otp !== 'string') {
        throw new HttpsError('invalid-argument', 'Phone number and OTP are required');
    }

    const normalizedPhone = normalizeSudanesePhone(phoneNumber);
    if (!normalizedPhone) {
        throw new HttpsError('invalid-argument', 'Invalid Sudanese phone number format');
    }

    try {
        // ─── PHASE 1: Brute-Force Protection ──────────────────────────────
        await checkOTPBruteForceLimit(normalizedPhone);

        // ─── PHASE 2: Find Valid OTP ──────────────────────────────────────
        const otpQuery = await db.collection('otp_codes')
            .where('phoneNumber', '==', normalizedPhone)
            .where('used', '==', false)
            .where('expiresAt', '>', new Date())
            .orderBy('expiresAt', 'desc')
            .limit(1)
            .get();

        if (otpQuery.empty) {
            // Log failed verification
            await logAudit('OTP_VERIFY_FAILED', null, {
                phoneNumber,
                status: 'failed',
                errorMessage: 'OTP not found or expired'
            });

            // Record failed attempt for brute-force tracking
            await recordFailedOTPVerification(normalizedPhone);

            throw new HttpsError('not-found', 'OTP not found or expired. Request a new OTP.');
        }

        const otpDoc = otpQuery.docs[0];
        const otpData = otpDoc.data();

        // ─── PHASE 3: Validate OTP Code ───────────────────────────────────
        if (otpData.otp !== otp) {
            // Log failed verification
            await logAudit('OTP_VERIFY_FAILED', null, {
                phoneNumber,
                status: 'failed',
                errorMessage: 'Invalid OTP code'
            });

            // Record failed attempt for brute-force tracking
            await recordFailedOTPVerification(normalizedPhone);

            throw new HttpsError('invalid-argument', 'Incorrect OTP code. Please try again.');
        }

        // ─── PHASE 4: Mark OTP as Used ────────────────────────────────────
        await otpDoc.ref.update({ 
            used: true,
            verifiedAt: FieldValue.serverTimestamp()
        });

        // ─── PHASE 5: Clear Brute-Force Counter ───────────────────────────
        // Reset failed attempts counter on successful verification
        try {
            await db.collection('_brute_force_attempts')
                .doc(`otp_verify_${normalizedPhone}`)
                .delete();
        } catch (err) {
            // Silently fail if doc doesn't exist
            console.log(`No brute-force counter to clear for ${normalizedPhone}`);
        }

        // ─── PHASE 6: Audit Logging ───────────────────────────────────────
        await logAudit('OTP_VERIFIED', null, {
            phoneNumber,
            status: 'success',
            metadata: {
                otpDocId: otpDoc.id,
                method: otpData.method || 'unknown'
            }
        });

        return { 
            success: true, 
            message: 'OTP verified successfully',
            verifiedAt: FieldValue.serverTimestamp(),
            method: otpData.method || 'unknown'
        };

    } catch (error) {
        if (error instanceof HttpsError) {
            throw error;
        }

        console.error('Error verifying WhatsApp OTP:', error);
        
        await logAudit('OTP_VERIFY_ERROR', null, {
            phoneNumber,
            status: 'error',
            errorMessage: error.message
        });

        throw new HttpsError('internal', 'Failed to verify OTP');
    }
});

/**
 * Callable Cloud Function: deleteUserAccount
 *
 * Allows an admin to delete a user account completely from Auth, Firestore, and Storage.
 * This is intended for the admin dashboard and is protected by the admin role check.
 */
exports.deleteUserAccount = onCall(async (request) => {
    const authUid = request.auth?.uid;
    if (!authUid) {
        throw new HttpsError('unauthenticated', 'Authentication is required');
    }

    const isAdmin = await isAdminUser(authUid);
    if (!isAdmin) {
        throw new HttpsError('permission-denied', 'Admin privileges are required');
    }

    const { userId } = request.data || {};
    if (!userId || typeof userId !== 'string') {
        throw new HttpsError('invalid-argument', 'userId is required');
    }

    try {
        await deleteUserFirestoreData(userId);
        await deleteUserStorageData(userId);
        try {
            await authAdmin.deleteUser(userId);
        } catch (authError) {
            if (authError.code !== 'auth/user-not-found') {
                throw authError;
            }
            console.warn(`Auth user ${userId} not found, continuing deletion of Firestore/Storage data.`);
        }
        return { success: true };
    } catch (error) {
        console.error(`Error deleting user account ${userId}:`, error);
        throw new HttpsError('internal', 'Failed to delete user account');
    }
});

/**
 * Cloud Function: onUserUpdated
 * 
 * PHASE 1 FIX: Syncs admin role to Firebase Auth custom claims
 * Eliminates performance issue from repeated Firestore reads in firestore.rules
 * 
 * When user.role changes to/from 'admin', updates Auth custom claims
 * This allows firestore.rules to use request.auth.token.admin (fast) 
 * instead of get() Firestore read (slow)
 */
exports.onUserUpdated = onDocumentUpdated(
    { document: "users/{userId}", concurrency: 80 },
    async (event) => {
        const userBefore = event.data.before.data();
        const userAfter = event.data.after.data();
        const userId = event.params.userId;

        if (!userBefore || !userAfter) return null;

        const roleBefore = userBefore.role;
        const roleAfter = userAfter.role;

        // Only process if role changed
        if (roleBefore === roleAfter) return null;

        try {
            // If promoted to admin, set custom claim
            if (roleAfter === 'admin' && roleBefore !== 'admin') {
                await authAdmin.setCustomUserClaims(userId, { admin: true });
                console.log(`✓ Admin custom claim SET for user ${userId}`);
                
                await logAudit('ADMIN_ROLE_GRANTED', userId, {
                    status: 'success',
                    metadata: { previousRole: roleBefore, newRole: roleAfter }
                });
            }
            // If demoted from admin, remove custom claim
            else if (roleAfter !== 'admin' && roleBefore === 'admin') {
                await authAdmin.setCustomUserClaims(userId, { admin: false });
                console.log(`✓ Admin custom claim REMOVED for user ${userId}`);
                
                await logAudit('ADMIN_ROLE_REVOKED', userId, {
                    status: 'success',
                    metadata: { previousRole: roleBefore, newRole: roleAfter }
                });
            }
        } catch (error) {
            console.error(`Error syncing admin role for user ${userId}:`, error);
            await logAudit('ADMIN_SYNC_ERROR', userId, {
                status: 'error',
                errorMessage: error.message
            });
        }

        return null;
    }
);

// ═══ Verification Request Approved - Auto-sync User Status ═══
exports.onVerificationRequestUpdated = onDocumentUpdated(
    "verification_requests/{requestId}",
    async (event) => {
        const requestData = event.data.after.data();
        const previousData = event.data.before.data();

        // Only trigger when status changes to 'approved'
        if (requestData.status === 'approved' && previousData.status !== 'approved') {
            const userId = requestData.userId;

            try {
                console.log(`🔄 Syncing verification status for user ${userId}`);

                // Update user document to ensure consistency
                await db.collection('users').doc(userId).update({
                    isVerified: true,
                    verifiedAt: FieldValue.serverTimestamp(),
                    verificationStatus: 'verified',
                    updatedAt: FieldValue.serverTimestamp()
                });

                console.log(`✓ User ${userId} verification status synced successfully`);

                await logAudit('VERIFICATION_APPROVED_SYNC', userId, {
                    status: 'success',
                    requestId: event.params.requestId,
                    metadata: { syncedFields: ['isVerified', 'verifiedAt', 'verificationStatus'] }
                });

            } catch (error) {
                console.error(`Error syncing verification for user ${userId}:`, error);

                await logAudit('VERIFICATION_SYNC_ERROR', userId, {
                    status: 'error',
                    requestId: event.params.requestId,
                    errorMessage: error.message
                });
            }
        }

        return null;
    }
);

// ═══ Admin: Delete User Account (Auth + Firestore + Storage) ═══
exports.deleteUserAccount = onCall(async (request) => {
    // 1. Only admins can call this function
    const callerUid = request.auth?.uid;
    if (!callerUid) {
        throw new HttpsError('unauthenticated', 'يجب تسجيل الدخول أولاً');
    }
    const isAdmin = await isAdminUser(callerUid);
    if (!isAdmin) {
        throw new HttpsError('permission-denied', 'هذه العملية متاحة للمشرفين فقط');
    }

    const { userId, requestId } = request.data || {};
    if (!userId || typeof userId !== 'string') {
        throw new HttpsError('invalid-argument', 'معرف المستخدم مطلوب');
    }

    try {
        console.log(`Admin ${callerUid} deleting user ${userId}...`);

        // 2. Delete from Firebase Auth
        try {
            await authAdmin.deleteUser(userId);
            console.log(`✓ Deleted user ${userId} from Firebase Auth`);
        } catch (authError) {
            // If user not found in Auth, continue with Firestore deletion
            if (authError.code !== 'auth/user-not-found') {
                throw authError;
            }
            console.warn(`User ${userId} not found in Firebase Auth, continuing with data deletion`);
        }

        // 3. Delete all Firestore data
        await deleteUserFirestoreData(userId);
        console.log(`✓ Deleted Firestore data for user ${userId}`);

        // 4. Delete Storage files
        await deleteUserStorageData(userId);
        console.log(`✓ Deleted Storage files for user ${userId}`);

        // 5. Mark deletion request as approved
        if (requestId) {
            await db.collection('deletion_requests').doc(requestId).update({
                status: 'approved',
                approvedAt: FieldValue.serverTimestamp(),
                approvedBy: callerUid,
            });
        }

        // 6. Audit log
        await logAudit('USER_DELETED', userId, {
            adminId: callerUid,
            status: 'success',
            metadata: { requestId: requestId || null }
        });

        console.log(`✅ User ${userId} fully deleted by admin ${callerUid}`);
        return { success: true, message: 'تم حذف الحساب بنجاح' };

    } catch (error) {
        console.error(`Error deleting user ${userId}:`, error);
        await logAudit('USER_DELETE_ERROR', userId, {
            adminId: callerUid,
            status: 'error',
            errorMessage: error.message
        });
        throw new HttpsError('internal', `فشل الحذف: ${error.message}`);
    }
});

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
});

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
});

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
);

/**
 * Callable Cloud Function: generateCloudinarySignature
 * Generates a signed signature for secure Cloudinary uploads from the client.
 */
exports.generateCloudinarySignature = onCall(async (request) => {
    const apiSecret = process.env.CLOUDINARY_API_SECRET;
    const apiKey = process.env.CLOUDINARY_API_KEY;
    
    if (!apiSecret || !apiKey) {
        throw new HttpsError('internal', 'Cloudinary API credentials are not configured.');
    }

    if (!request.auth) {
        throw new HttpsError('unauthenticated', 'User must be logged in to upload files.');
    }

    const timestamp = Math.round((new Date).getTime() / 1000);
    const folder = request.data?.folder || 'general';
    
    const crypto = require('crypto');
    const signatureString = `folder=${folder}&timestamp=${timestamp}${apiSecret}`;
    const signature = crypto.createHash('sha1').update(signatureString).digest('hex');

    return {
        timestamp: timestamp,
        signature: signature,
        folder: folder,
        apiKey: apiKey
    };
});
