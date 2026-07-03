const utils = require('./utils');
const { onDocumentCreated, onDocumentUpdated } = require('firebase-functions/v2/firestore');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { FieldValue } = require('firebase-admin/firestore');

const { logAudit, normalizeSudanesePhone, checkOTPRateLimit, checkOTPBruteForceLimit, recordFailedOTPVerification, isAdminUser, deleteUserFirestoreData, deleteUserStorageData, twilio, db, authAdmin, storage, getBucket, messaging, isProduction, RATE_LIMIT_WINDOW, RATE_LIMIT_MAX_ATTEMPTS, BRUTE_FORCE_WINDOW, BRUTE_FORCE_MAX_ATTEMPTS, twilioClient } = utils;

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
});;

