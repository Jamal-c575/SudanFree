const utils = require('./utils');
const { onDocumentCreated, onDocumentUpdated } = require('firebase-functions/v2/firestore');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { FieldValue } = require('firebase-admin/firestore');

const { logAudit, normalizeSudanesePhone, checkOTPRateLimit, checkOTPBruteForceLimit, recordFailedOTPVerification, isAdminUser, deleteUserFirestoreData, deleteUserStorageData, twilio, db, authAdmin, storage, getBucket, messaging, isProduction, RATE_LIMIT_WINDOW, RATE_LIMIT_MAX_ATTEMPTS, BRUTE_FORCE_WINDOW, BRUTE_FORCE_MAX_ATTEMPTS, twilioClient } = utils;

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

// ═══ Verification Request Approved - Auto-sync User Status ═══;

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

// ═══ Admin: Delete User Account (Auth + Firestore + Storage) ═══;

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

