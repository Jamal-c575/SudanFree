import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../../models/user_model.dart';
import '../../models/notification_model.dart';
import '../performance_service.dart';

class UserFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get user by ID
  Future<UserModel?> getUser(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (doc.exists) {
      return UserModel.fromFirestore(doc);
    }
    return null;
  }

  // Get user stream
  Stream<UserModel?> getUserStream(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map((doc) {
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    });
  }

  // Update user profile
  Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    final updates = Map<String, dynamic>.from(data);
    updates['updatedAt'] = Timestamp.now();
    await _firestore.collection('users').doc(userId).update(updates);
  }

  /// Update lastActive timestamp for online presence tracking
  Future<void> updateLastActive(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'lastActive': Timestamp.now(),
    });
  }

  // Send Partner Request
  Future<void> sendPartnerRequest(String requesterId, String requesterName, String targetId) async {
    final targetRef = _firestore.collection('users').doc(targetId);
    await targetRef.update({
      'pendingPartnerIds': FieldValue.arrayUnion([requesterId])
    });
  }

  // Handle Partner Request
  Future<void> handlePartnerRequest(String userId, String responderName, String requesterId, bool accept) async {
    final batch = _firestore.batch();
    final userRef = _firestore.collection('users').doc(userId);
    final requesterRef = _firestore.collection('users').doc(requesterId);

    batch.update(userRef, {
      'pendingPartnerIds': FieldValue.arrayRemove([requesterId])
    });

    if (accept) {
      batch.update(userRef, {
        'partnerIds': FieldValue.arrayUnion([requesterId])
      });
      batch.update(requesterRef, {
        'partnerIds': FieldValue.arrayUnion([userId])
      });
    }

    final notifRef = _firestore.collection('notifications').doc();
    final notification = NotificationModel(
      id: notifRef.id,
      userId: requesterId,
      type: NotificationType.system,
      title: accept ? 'طلب زمالة مقبول ✅' : 'طلب زمالة مرفوض ❌',
      message: accept ? 'قام $responderName بقبول طلب الزمالة الخاص بك' : 'قام $responderName برفض طلب الزمالة الخاص بك',
      createdAt: Timestamp.now(),
      relatedId: userId,
    );
    batch.set(notifRef, notification.toFirestore());

    await batch.commit();
  }

  // Toggle Follow
  Future<void> toggleFollow(String followerId, String targetId, bool isFollowing) async {
    final batch = _firestore.batch();
    final followerRef = _firestore.collection('users').doc(followerId);
    final targetRef = _firestore.collection('users').doc(targetId);

    if (isFollowing) {
      // Unfollow
      batch.update(followerRef, {
        'following': FieldValue.arrayRemove([targetId])
      });
      batch.update(targetRef, {
        'followers': FieldValue.arrayRemove([followerId])
      });
    } else {
      // Follow
      batch.update(followerRef, {
        'following': FieldValue.arrayUnion([targetId])
      });
      batch.update(targetRef, {
        'followers': FieldValue.arrayUnion([followerId])
      });
    }
    await batch.commit();
  }

  // Increment Profile Views (only once per unique viewer)
  Future<void> incrementProfileViews(String userId, [String? viewerId]) async {
    if (viewerId == null) return;
    
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) return;
    
    final viewers = List<String>.from(userDoc.data()?['viewers'] ?? []);
    if (viewers.contains(viewerId)) return; // Already viewed
    
    await _firestore.collection('users').doc(userId).update({
      'profileViews': FieldValue.increment(1),
      'viewers': FieldValue.arrayUnion([viewerId]),
    });
  }

  // Get Users by IDs
  Future<List<UserModel>> getUsersByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    List<UserModel> users = [];
    for (var i = 0; i < ids.length; i += 10) {
      final end = (i + 10 < ids.length) ? i + 10 : ids.length;
      final chunk = ids.sublist(i, end);
      final snapshot = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      users.addAll(snapshot.docs.map((doc) => UserModel.fromFirestore(doc)));
    }
    return users;
  }

  // Get freelancers paginated
  Future<Map<String, dynamic>> getFreelancersPaginated({
    DocumentSnapshot? startAfterDoc,
    int limit = 15,
    String? state,
  }) async {
    final trace = PerformanceService().startTrace('query_freelancers');
    trace.putAttribute('limit', limit.toString());
    trace.putAttribute('is_paginated', (startAfterDoc != null).toString());

    Query query = _firestore
        .collection('users')
        .where('role', whereIn: ['freelancer', 'privateService', 'techService', 'Freelancer', 'FREELANCER', 'freelancer ', 'Freelancer '])
        .orderBy('createdAt', descending: true)
        .limit(limit);

    // Filter by state if provided
    if (state != null && state.isNotEmpty) {
      query = _firestore
          .collection('users')
          .where('state', isEqualTo: state)
          .where('role', whereIn: ['freelancer', 'privateService', 'techService', 'Freelancer', 'FREELANCER', 'freelancer ', 'Freelancer '])
          .orderBy('createdAt', descending: true)
          .limit(limit);
    }

    if (startAfterDoc != null) {
      query = query.startAfterDocument(startAfterDoc);
    }

    final snapshot = await query.get();
    final users = snapshot.docs
        .map((doc) => UserModel.fromFirestore(doc))
        .toList();

    trace.incrementMetric('result_count', users.length);
    trace.stop();

    return {
      'users': users,
      'lastDoc': snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
      'hasMore': snapshot.docs.length == limit,
    };
  }

  // Get shops paginated
  Future<Map<String, dynamic>> getShopsPaginated({
    DocumentSnapshot? startAfterDoc,
    int limit = 15,
    String? state,
  }) async {
    Query query = _firestore
        .collection('users')
        .where('role', whereIn: ['shop', 'Shop', 'SHOP', 'shop ', 'Shop '])
        .orderBy('createdAt', descending: true)
        .limit(limit);

    // Filter by state if provided
    if (state != null && state.isNotEmpty) {
      query = _firestore
          .collection('users')
          .where('state', isEqualTo: state)
          .where('role', whereIn: ['shop', 'Shop', 'SHOP', 'shop ', 'Shop '])
          .orderBy('createdAt', descending: true)
          .limit(limit);
    }

    if (startAfterDoc != null) {
      query = query.startAfterDocument(startAfterDoc);
    }

    final snapshot = await query.get();
    final shops = snapshot.docs
        .map((doc) => UserModel.fromFirestore(doc))
        .toList();

    return {
      'users': shops,
      'lastDoc': snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
      'hasMore': snapshot.docs.length == limit,
    };
  }

  // Get both freelancers and shops paginated (for smart search)
  Future<Map<String, dynamic>> getProvidersPaginated({
    DocumentSnapshot? startAfterDoc,
    int limit = 200,
  }) async {
    final trace = PerformanceService().startTrace('query_all_providers');
    trace.putAttribute('limit', limit.toString());

    Query query = _firestore
        .collection('users')
        .where('role', whereIn: [
          'freelancer', 'Freelancer', 'shop', 'Shop', 
          'privateService', 'techService', 
          'freelancer ', 'Freelancer ', 'shop ', 'Shop '
        ])
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (startAfterDoc != null) {
      query = query.startAfterDocument(startAfterDoc);
    }

    final snapshot = await query.get();
    final users = snapshot.docs
        .map((doc) => UserModel.fromFirestore(doc))
        .toList();

    trace.incrementMetric('result_count', users.length);
    trace.stop();

    return {
      'users': users,
      'lastDoc': snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
      'hasMore': snapshot.docs.length == limit,
    };
  }

  // Stream freelancers for variety (legacy support if needed)
  Stream<List<UserModel>> getFreelancersStream({String? skill, int limit = 100}) {
    return _firestore
        .collection('users')
        .where('role', whereIn: ['freelancer', 'privateService', 'techService', 'Freelancer', 'FREELANCER', 'freelancer ', 'Freelancer '])
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      var users = snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
      if (skill != null && skill.isNotEmpty) {
        users = users.where((u) => u.skills.contains(skill)).toList();
      }
      users.sort((a, b) => b.rating.compareTo(a.rating));
      return users;
    });
  }

  // Delete all user data (Cascading)
  Future<void> deleteAllUserData(String userId) async {
    List<DocumentReference> allRefs = [];
    final posts = await _firestore.collection('posts').where('userId', isEqualTo: userId).get();
    allRefs.addAll(posts.docs.map((d) => d.reference));
    final comments = await _firestore.collectionGroup('comments').where('userId', isEqualTo: userId).get();
    allRefs.addAll(comments.docs.map((d) => d.reference));
    final reviews = await _firestore.collection('reviews').where('reviewerId', isEqualTo: userId).get();
    allRefs.addAll(reviews.docs.map((d) => d.reference));
    final notifications = await _firestore.collection('notifications').where('userId', isEqualTo: userId).get();
    allRefs.addAll(notifications.docs.map((d) => d.reference));
    
    // Clean up subcollections
    final portfolio = await _firestore.collection('users').doc(userId).collection('portfolio').get();
    allRefs.addAll(portfolio.docs.map((d) => d.reference));
    final settings = await _firestore.collection('users').doc(userId).collection('settings').get();
    allRefs.addAll(settings.docs.map((d) => d.reference));
    
    allRefs.add(_firestore.collection('users').doc(userId));
    
    for (var i = 0; i < allRefs.length; i += 400) {
      final batch = _firestore.batch();
      final end = (i + 400 < allRefs.length) ? i + 400 : allRefs.length;
      for (var j = i; j < end; j++) batch.delete(allRefs[j]);
      await batch.commit();
    }
  }
  // Update user profile images across posts (Legacy/Batch)
  Future<void> updateUserProfileImages(String userId, String? imageUrl, String? userName) async {
    final batch = _firestore.batch();
    final postsQuery = await _firestore.collection('posts').where('userId', isEqualTo: userId).get();
    for (var doc in postsQuery.docs) {
      final updates = <String, dynamic>{};
      if (imageUrl != null) updates['userImageUrl'] = imageUrl;
      if (userName != null) updates['userName'] = userName;
      if (updates.isNotEmpty) batch.update(doc.reference, updates);
    }
    await batch.commit();
  }
}
