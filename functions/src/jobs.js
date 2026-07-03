const utils = require('./utils');
const { onDocumentCreated, onDocumentUpdated } = require('firebase-functions/v2/firestore');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { FieldValue } = require('firebase-admin/firestore');

const { logAudit, normalizeSudanesePhone, checkOTPRateLimit, checkOTPBruteForceLimit, recordFailedOTPVerification, isAdminUser, deleteUserFirestoreData, deleteUserStorageData, twilio, db, authAdmin, storage, getBucket, messaging, isProduction, RATE_LIMIT_WINDOW, RATE_LIMIT_MAX_ATTEMPTS, BRUTE_FORCE_WINDOW, BRUTE_FORCE_MAX_ATTEMPTS, twilioClient } = utils;

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
);;

