import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // Track page views
  Future<void> logScreenView({required String screenName, String? screenClass}) async {
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass ?? screenName,
      );
    } catch (e) {
      debugPrint('Analytics Error: $e');
    }
  }

  // Track login/signup
  Future<void> logLogin(String method) async {
    try {
      await _analytics.logLogin(loginMethod: method);
    } catch (e) {
      debugPrint('Analytics Error: $e');
    }
  }

  Future<void> logSignUp(String method) async {
    try {
      await _analytics.logSignUp(signUpMethod: method);
    } catch (e) {
      debugPrint('Analytics Error: $e');
    }
  }

  // Track job/offer actions
  Future<void> logJobCreated(String jobId, String category) async {
    try {
      await _analytics.logEvent(
        name: 'job_created',
        parameters: {
          'job_id': jobId,
          'category': category,
        },
      );
    } catch (e) {
      debugPrint('Analytics Error: $e');
    }
  }

  Future<void> logOfferSubmitted(String jobId, double amount) async {
    try {
      await _analytics.logEvent(
        name: 'offer_submitted',
        parameters: {
          'job_id': jobId,
          'amount': amount,
        },
      );
    } catch (e) {
      debugPrint('Analytics Error: $e');
    }
  }

  // Set user properties
  Future<void> setUserProperty(String name, String value) async {
    try {
      await _analytics.setUserProperty(name: name, value: value);
    } catch (e) {
      debugPrint('Analytics Error: $e');
    }
  }
}
