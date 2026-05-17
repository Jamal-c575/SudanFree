import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../../models/review_model.dart';
import '../../models/notification_model.dart';

class ReviewFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create review (uses transaction to prevent race conditions and duplicates)
  Future<String> createReview(ReviewModel review, {bool isJobCompleted = false}) async {
    // Unique ID per reviewer -> target to prevent duplicates
    final uniqueDocId = '${review.reviewerId}_${review.freelancerId}';
    final ratingRef = _firestore.collection('ratings').doc(uniqueDocId);
    final reviewRef = _firestore.collection('reviews').doc(uniqueDocId);
    final freelancerRef = _firestore.collection('users').doc(review.freelancerId);

    String resultId = uniqueDocId;

    print('DEBUG: Starting createReview transaction for $uniqueDocId, rating=${review.rating}');

    await _firestore.runTransaction((tx) async {
      final ratingSnap = await tx.get(ratingRef);
      if (ratingSnap.exists) {
        // User already rated this target — abort and return existing id
        print('DEBUG: Rating already exists for $uniqueDocId — aborting transaction');
        resultId = ratingRef.id;
        return;
      }

      // Create rating document in `ratings/{reviewer}_{target}`
      tx.set(ratingRef, {
        'reviewerId': review.reviewerId,
        'freelancerId': review.freelancerId,
        'rating': review.rating,
        'comment': review.comment,
        'wouldWorkAgain': review.wouldWorkAgain,
        'isNegative': review.isNegative,
        'jobId': review.jobId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Also write the full review record (keeps existing reviews stream intact)
      tx.set(reviewRef, review.toFirestore());

      // Read freelancer current stats
      final freelancerSnap = await tx.get(freelancerRef);
      final currentRating = (freelancerSnap.data()?['rating'] as num?)?.toDouble() ?? 0.0;
      final currentCount = (freelancerSnap.data()?['reviewsCount'] as num?)?.toInt() ?? 0;

      final newCount = currentCount + 1;
      final newRating = ((currentRating * currentCount) + review.rating) / newCount;

      final Map<String, dynamic> updateData = {
        'rating': newRating,
        'reviewsCount': newCount,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final int roundedRating = review.rating.round();
      if (roundedRating >= 1 && roundedRating <= 5) {
        updateData['ratingCounts.$roundedRating'] = FieldValue.increment(1);
      }
      if (review.isNegative) updateData['negativeReports'] = FieldValue.increment(1);
      if (isJobCompleted) updateData['completedJobs'] = FieldValue.increment(1);

      tx.update(freelancerRef, updateData);

      // Create a notification for the freelancer
      final notifRef = _firestore.collection('notifications').doc();
      final Map<String, dynamic> notifData = {
        'id': notifRef.id,
        'userId': review.freelancerId,
        'type': review.isNegative ? NotificationType.fraudWarning.name : NotificationType.rating.name,
        'title': review.isNegative ? 'تحذير احتيال' : 'تقييم جديد',
        'message': review.isNegative
            ? 'تم الإبلاغ عن حسابك كاحتيال/سلبي بواسطة ${review.reviewerName}'
            : 'قام ${review.reviewerName} بتقييمك بـ ${review.rating} نجوم',
        'createdAt': FieldValue.serverTimestamp(),
        'relatedId': reviewRef.id,
      };
      tx.set(notifRef, notifData);

      print('DEBUG: Prepared transaction writes for $uniqueDocId (newRating=$newRating, newCount=$newCount)');
    });

    print('DEBUG: Completed createReview for $uniqueDocId');
    return resultId;
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
