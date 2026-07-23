require('./src/utils'); // Initialize Firebase

Object.assign(exports, require('./src/notifications'));
Object.assign(exports, require('./src/users'));
Object.assign(exports, require('./src/jobs'));
Object.assign(exports, require('./src/ads'));
Object.assign(exports, require('./src/media'));

// ─── Recommendation Engine ─────────────────────────────────────────────────
const recommendations = require('./src/recommendations');
exports.calculateRecommendations = recommendations.calculateRecommendations;
exports.trackUserInteraction = recommendations.trackUserInteraction;

// ─── Fraud Detection ───────────────────────────────────────────────────────
const fraudDetection = require('./src/fraud_detection');
exports.analyzeReview = fraudDetection.analyzeReview;
exports.getUserRiskScore = fraudDetection.getUserRiskScore;

// ─── Smart Notifications ───────────────────────────────────────────────────
const smartNotifications = require('./src/smart_notifications');
exports.notifyUsersAboutNewProviders = smartNotifications.notifyUsersAboutNewProviders;
exports.sendWelcomeNotification = smartNotifications.sendWelcomeNotification;

// ─── AI Assistant ──────────────────────────────────────────────────────────
const ai = require('./src/ai');
exports.ai_chatWithHome      = ai.ai_chatWithHome;
exports.ai_generatePageGuide = ai.ai_generatePageGuide;
exports.ai_smartFillRequest  = ai.ai_smartFillRequest;
exports.ai_enhanceText       = ai.ai_enhanceText;
exports.ai_transcribeAudio   = ai.transcribeAudio;
