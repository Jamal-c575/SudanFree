import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RecommendationService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Calculate hybrid score for a user
  static double calculateScore({
    required double distanceKm,
    required double rating,
    required int reviewsCount,
    required bool categoryMatch,
  }) {
    final distanceScore = distanceKm < 5
        ? 1.0
        : distanceKm < 10
            ? 0.7
            : distanceKm < 20
                ? 0.4
                : 0.1;
    final ratingScore = rating / 5.0;
    final popularityScore = (reviewsCount / 50.0).clamp(0.0, 1.0);
    final categoryScore = categoryMatch ? 1.0 : 0.0;

    return (0.4 * distanceScore) +
        (0.2 * ratingScore) +
        (0.1 * popularityScore) +
        (0.3 * categoryScore);
  }

  /// Calculate distance between two coordinates (Haversine formula)
  static double calculateDistance(
    double lat1, double lon1, double lat2, double lon2,
  ) {
    const R = 6371.0; // Earth radius in km
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = _sinSq(dLat / 2) +
        _cos(_toRad(lat1)) * _cos(_toRad(lat2)) * _sinSq(dLon / 2);
    final c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));
    return R * c;
  }

  static double _toRad(double deg) => deg * 3.14159265358979 / 180;
  static double _sinSq(double x) => _sin(x) * _sin(x);
  static double _sin(double x) => x - x * x * x / 6 + x * x * x * x * x / 120;
  static double _cos(double x) => 1 - x * x / 2 + x * x * x * x / 24;
  static double _sqrt(double x) => x <= 0 ? 0 : x < 1 ? x / 2 + 0.5 : x * 0.5;
  static double _atan2(double y, double x) {
    if (x > 0) return _atan(y / x);
    if (x < 0 && y >= 0) return _atan(y / x) + 3.14159265;
    if (x < 0 && y < 0) return _atan(y / x) - 3.14159265;
    if (x == 0 && y > 0) return 3.14159265 / 2;
    if (x == 0 && y < 0) return -3.14159265 / 2;
    return 0;
  }
  static double _atan(double x) => x - x*x*x/3 + x*x*x*x*x/5 - x*x*x*x*x*x*x/7;

  /// Track user interaction (view, contact, hire)
  Future<void> trackInteraction({
    required String currentUserId,
    required String targetUserId,
    required String interactionType, // 'view', 'contact', 'hire'
  }) async {
    try {
      await _db
          .collection('user_interactions')
          .doc(currentUserId)
          .collection('events')
          .add({
        'targetUserId': targetUserId,
        'type': interactionType,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error tracking interaction: $e');
    }
  }

  /// Get cached recommendations for a user
  Future<List<String>> getCachedRecommendations(String userId) async {
    try {
      final doc = await _db.collection('recommendations').doc(userId).get();
      if (!doc.exists) return [];
      final data = doc.data();
      final userIds = data?['userIds'] as List<dynamic>?;
      return userIds?.cast<String>() ?? [];
    } catch (e) {
      debugPrint('Error getting recommendations: $e');
      return [];
    }
  }

  /// Get user's most viewed categories from interactions
  Future<String?> getMostInterestedCategory(String userId) async {
    try {
      final snapshot = await _db
          .collection('user_interactions')
          .doc(userId)
          .collection('events')
          .orderBy('timestamp', descending: true)
          .limit(20)
          .get();

      final Map<String, int> categoryCounts = {};
      for (final doc in snapshot.docs) {
        final targetId = doc.data()['targetUserId'] as String?;
        if (targetId != null) {
          final userDoc = await _db.collection('users').doc(targetId).get();
          final skills = userDoc.data()?['skills'] as List<dynamic>?;
          if (skills != null && skills.isNotEmpty) {
            final category = skills.first.toString();
            categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
          }
        }
      }

      if (categoryCounts.isEmpty) return null;
      return categoryCounts.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
    } catch (e) {
      return null;
    }
  }
}
