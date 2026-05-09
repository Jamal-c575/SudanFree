import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../../models/review_model.dart';
import '../../models/notification_model.dart';

class ReviewFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create review
  Future<String> createReview(ReviewModel review, {bool isJobCompleted = false}) async {
    final batch = _firestore.batch();
    
    // Check if first review
    final existingReviews = await _firestore
        .collection('reviews')
        .where('freelancerId', isEqualTo: review.freelancerId)
        .where('reviewerId', isEqualTo: review.reviewerId)
        .limit(1)
        .get();
        
    final isFirstReview = existingReviews.docs.isEmpty;
    final reviewRef = _firestore.collection('reviews').doc();
    batch.set(reviewRef, review.toFirestore());
    
    if (isFirstReview) {
      final freelancerDoc = await _firestore.collection('users').doc(review.freelancerId).get();
      final currentRating = (freelancerDoc.data()?['rating'] as num?)?.toDouble() ?? 0.0;
      final currentCount = (freelancerDoc.data()?['reviewsCount'] as num?)?.toInt() ?? 0;
      
      final newCount = currentCount + 1;
      final newRating = ((currentRating * currentCount) + review.rating) / newCount;
      
      final Map<String, dynamic> updateData = {
        'rating': newRating,
        'reviewsCount': newCount,
        'updatedAt': Timestamp.now(),
      };

      final int roundedRating = review.rating.round();
      if (roundedRating >= 1 && roundedRating <= 5) {
        updateData['ratingCounts.$roundedRating'] = FieldValue.increment(1);
      }
      
      if (review.isNegative) {
        updateData['negativeReports'] = FieldValue.increment(1);
      }

      if (isJobCompleted) {
        updateData['completedJobs'] = FieldValue.increment(1);
      }
      
      batch.update(_firestore.collection('users').doc(review.freelancerId), updateData);
    }
    
    final notifRef = _firestore.collection('notifications').doc();
    final notification = NotificationModel(
      id: notifRef.id,
      userId: review.freelancerId,
      type: review.isNegative ? NotificationType.fraudWarning : NotificationType.rating,
      title: review.isNegative ? 'تحذير احتيال' : 'تقييم جديد',
      message: review.isNegative 
          ? 'تم الإبلاغ عن حسابك كاحتيال/سلبي بواسطة ${review.reviewerName}'
          : 'قام ${review.reviewerName} ${isFirstReview ? 'بتقييمك بـ ${review.rating} نجوم' : 'بالتعليق على ملفك الشخصي'}',
      createdAt: Timestamp.now(),
      relatedId: reviewRef.id,
    );
    batch.set(notifRef, notification.toFirestore());
    
    await batch.commit();
    return reviewRef.id;
  }

  // Stream reviews
  Stream<List<ReviewModel>> getFreelancerReviews(String freelancerId) {
    return _firestore
        .collection('reviews')
        .where('freelancerId', isEqualTo: freelancerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => ReviewModel.fromFirestore(doc)).toList());
  }
}
