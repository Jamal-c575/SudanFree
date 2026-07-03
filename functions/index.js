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

