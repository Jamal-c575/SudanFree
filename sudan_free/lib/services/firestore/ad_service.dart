import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../models/ad_model.dart';
import '../../models/user_model.dart';

class AdService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetches the most relevant ad for a specific placement based on user's region/profession
  Future<AdModel?> getTargetedAd(UserModel currentUser, {AdPlacement placement = AdPlacement.homeBanner}) async {
    try {
      final now = Timestamp.now();
      
      // Query 1: Ads targeted to this user's region AND profession for this placement
      var targetedQuery = _firestore.collection('ads')
          .where('isActive', isEqualTo: true)
          .where('placement', isEqualTo: placement.name)
          .where('targetRegion', isEqualTo: currentUser.state ?? 'all')
          .where('targetProfession', isEqualTo: currentUser.role)
          .where('expiryDate', isGreaterThan: now)
          .orderBy('expiryDate')
          .limit(1);

      var snap = await targetedQuery.get();

      // If no specific ad, try region-only
      if (snap.docs.isEmpty) {
        var regionQuery = _firestore.collection('ads')
            .where('isActive', isEqualTo: true)
            .where('placement', isEqualTo: placement.name)
            .where('targetRegion', isEqualTo: currentUser.state ?? 'all')
            .where('targetProfession', isEqualTo: 'all')
            .where('expiryDate', isGreaterThan: now)
            .orderBy('expiryDate')
            .limit(1);
        snap = await regionQuery.get();
      }

      // If still no ad, get a global ad for this placement
      if (snap.docs.isEmpty) {
        var globalQuery = _firestore.collection('ads')
            .where('isActive', isEqualTo: true)
            .where('placement', isEqualTo: placement.name)
            .where('targetRegion', isEqualTo: 'all')
            .where('targetProfession', isEqualTo: 'all')
            .where('expiryDate', isGreaterThan: now)
            .orderBy('expiryDate')
            .limit(1);
        snap = await globalQuery.get();
      }

      // Fallback: any active ad for this placement (ignore targeting)
      if (snap.docs.isEmpty) {
        var fallbackQuery = _firestore.collection('ads')
            .where('isActive', isEqualTo: true)
            .where('placement', isEqualTo: placement.name)
            .where('expiryDate', isGreaterThan: now)
            .orderBy('expiryDate')
            .limit(3);
        snap = await fallbackQuery.get();
      }

      // Legacy fallback: any active ad without placement field (old ads)
      if (snap.docs.isEmpty) {
        var legacyQuery = _firestore.collection('ads')
            .where('isActive', isEqualTo: true)
            .where('expiryDate', isGreaterThan: now)
            .orderBy('expiryDate')
            .limit(3);
        snap = await legacyQuery.get();
      }

      if (snap.docs.isNotEmpty) {
        final ads = snap.docs.map((d) => AdModel.fromFirestore(d)).toList();
        ads.sort((a, b) => b.priority.compareTo(a.priority));
        return ads.first;
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching ad: $e');
      return null;
    }
  }

  /// Fetch multiple ads for a placement (e.g., carousel on home)
  Future<List<AdModel>> getAdsForPlacement(UserModel currentUser, AdPlacement placement, {int limit = 5}) async {
    try {
      final now = Timestamp.now();

      final snap = await _firestore.collection('ads')
          .where('isActive', isEqualTo: true)
          .where('placement', isEqualTo: placement.name)
          .where('expiryDate', isGreaterThan: now)
          .orderBy('expiryDate')
          .limit(limit)
          .get();

      if (snap.docs.isEmpty) return [];

      final ads = snap.docs.map((d) => AdModel.fromFirestore(d)).toList();
      ads.sort((a, b) => b.priority.compareTo(a.priority));
      return ads;
    } catch (e) {
      debugPrint('Error fetching ads for placement: $e');
      return [];
    }
  }

  /// Record an ad impression
  Future<void> recordImpression(String adId) async {
    try {
      await _firestore.collection('ads').doc(adId).update({
        'impressions': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('Error recording impression: $e');
    }
  }

  /// Record an ad click
  Future<void> recordClick(String adId) async {
    try {
      await _firestore.collection('ads').doc(adId).update({
        'clicks': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('Error recording click: $e');
    }
  }
}
