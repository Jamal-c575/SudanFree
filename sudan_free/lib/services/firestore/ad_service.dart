import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../models/ad_model.dart';
import '../../models/user_model.dart';

class AdService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetches the most relevant ad for the user based on Region and Profession
  Future<AdModel?> getTargetedAd(UserModel currentUser) async {
    try {
      final now = Timestamp.now();
      
      // Query 1: Ads specifically targeted to this user's region AND profession
      var targetedQuery = _firestore.collection('ads')
          .where('isActive', isEqualTo: true)
          .where('targetRegion', isEqualTo: currentUser.state ?? 'all')
          .where('targetProfession', isEqualTo: currentUser.role)
          .where('expiryDate', isGreaterThan: now)
          .orderBy('expiryDate')
          .limit(1);

      var snap = await targetedQuery.get();

      // If no specific ad, try querying ads for their region only
      if (snap.docs.isEmpty) {
        var regionQuery = _firestore.collection('ads')
            .where('isActive', isEqualTo: true)
            .where('targetRegion', isEqualTo: currentUser.state ?? 'all')
            .where('targetProfession', isEqualTo: 'all')
            .where('expiryDate', isGreaterThan: now)
            .orderBy('expiryDate')
            .limit(1);
        snap = await regionQuery.get();
      }

      // If still no ad, get a global ad
      if (snap.docs.isEmpty) {
        var globalQuery = _firestore.collection('ads')
            .where('isActive', isEqualTo: true)
            .where('targetRegion', isEqualTo: 'all')
            .where('targetProfession', isEqualTo: 'all')
            .where('expiryDate', isGreaterThan: now)
            .orderBy('expiryDate')
            .limit(1);
        snap = await globalQuery.get();
      }

      if (snap.docs.isNotEmpty) {
        final ads = snap.docs.map((d) => AdModel.fromFirestore(d)).toList();
        // Sort by priority locally to pick the highest priority one if multiple matches
        ads.sort((a, b) => b.priority.compareTo(a.priority));
        return ads.first;
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching ad: $e');
      return null;
    }
  }
}
