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
const getBucket = () => storage.bucket('sudanfree-d04fc.firebasestorage.app');
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


module.exports = {
    logAudit,
    normalizeSudanesePhone,
    checkOTPRateLimit,
    checkOTPBruteForceLimit,
    recordFailedOTPVerification,
    isAdminUser,
    deleteUserFirestoreData,
    deleteUserStorageData,
    twilio,
    db,
    authAdmin,
    storage,
    getBucket,
    messaging,
    isProduction,
    RATE_LIMIT_WINDOW,
    RATE_LIMIT_MAX_ATTEMPTS,
    BRUTE_FORCE_WINDOW,
    BRUTE_FORCE_MAX_ATTEMPTS,
    twilioClient,
};
