import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';
import '../models/notification_model.dart';
import '../services/firestore_service.dart';
import '../services/cache_service.dart';
import '../services/cloudinary_service.dart';
import '../services/analytics_service.dart';

class PostsProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final CacheService _cacheService = CacheService();
  final AnalyticsService _analytics = AnalyticsService();
  
  List<PostModel> _posts = [];
  StreamSubscription? _postsSubscription;
  bool _isLoading = false;    // for feed loading only
  bool _isCreating = false;   // for createPost
  bool _isUpdating = false;   // for updatePost/deletePost
  String? _errorMessage;
  
  // Pagination & New Posts State
  DocumentSnapshot? _lastDoc;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  bool _hasNewPosts = false;
  StreamSubscription? _newPostsSubscription;
  DateTime? _latestPostDate;
  
  // Caching
  bool _postsLoaded = false;

  // Rate Limiting: prevent flooding notifications
  // Key: "${postId}_${notifType}" → last sent time
  final Map<String, DateTime> _notifCooldown = {};
  static const Duration _notifCooldownDuration = Duration(minutes: 5);

  bool _canSendNotif(String key) {
    final last = _notifCooldown[key];
    if (last == null) return true;
    return DateTime.now().difference(last) > _notifCooldownDuration;
  }

  void _markNotifSent(String key) {
    _notifCooldown[key] = DateTime.now();
  }

  List<PostModel> get posts => _posts;
  bool get isLoading => _isLoading;
  bool get isCreating => _isCreating;
  bool get isUpdating => _isUpdating;
  String? get errorMessage => _errorMessage;
  bool get hasPosts => _posts.isNotEmpty;

  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasNewPosts => _hasNewPosts;

  Future<void> fetchPosts({bool forceRefresh = false}) async {
    if (_posts.isEmpty && !forceRefresh) {
      final cached = _cacheService.getCachedPosts();
      if (cached != null && cached.isNotEmpty) {
         _posts = cached.map((e) => PostModel.fromMap(e)).toList();
         _postsLoaded = true;
         if (_posts.isNotEmpty) _latestPostDate = _posts.first.createdAt;
         notifyListeners(); 
      }
    }

    if (_postsLoaded && !forceRefresh && _posts.isNotEmpty) {
      return; 
    }
    
    if (_posts.isEmpty) {
      _isLoading = true;
      notifyListeners();
    }
    
    debugPrint('PostsProvider: Fetching paginated posts...');
    try {
      final result = await _firestoreService.getFeedPostsPaginated(limit: 15);
      
      // Safe type extraction with null checks
      final fetchedPosts = result['posts'];
      if (fetchedPosts is! List<PostModel>) {
        throw TypeError();
      }
      
      _posts = fetchedPosts;
      _lastDoc = result['lastDoc'] as DocumentSnapshot?;
      
      final hasMore = result['hasMore'];
      if (hasMore is! bool) {
        throw TypeError();
      }
      _hasMore = hasMore;
      
      _hasNewPosts = false; // Reset new posts indicator
      _isLoading = false;
      _postsLoaded = true;
      
      if (_posts.isNotEmpty) {
        _latestPostDate = _posts.first.createdAt;
      }
      
      // _listenForNewPosts(); // Temporarily disabled for efficiency
      
      try {
        _cacheService.cachePosts(_posts.map((e) => e.toJsonMap()).toList());
      } catch (e) {
        debugPrint('PostsProvider: Cache Error: $e');
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('PostsProvider: Error: $e');
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> fetchMorePosts() async {
    if (!_hasMore || _isLoadingMore || _isLoading) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final result = await _firestoreService.getFeedPostsPaginated(
        startAfterDoc: _lastDoc,
        limit: 15,
      );
      
      // Safe type extraction with null checks
      final morePosts = result['posts'];
      if (morePosts is! List<PostModel>) {
        throw TypeError();
      }
      
      if (morePosts.isNotEmpty) {
        // Deduplicate: only add posts not already in the list
        final existingIds = _posts.map((p) => p.id).toSet();
        final uniquePosts = morePosts.where((p) => !existingIds.contains(p.id)).toList();
        _posts.addAll(uniquePosts);
        _lastDoc = result['lastDoc'] as DocumentSnapshot?;
        
        final hasMore = result['hasMore'];
        if (hasMore is! bool) {
          throw TypeError();
        }
        _hasMore = hasMore;
        
        try {
          _cacheService.cachePosts(_posts.map((e) => e.toJsonMap()).toList());
        } catch (e) { debugPrint('PostsProvider: Cache error: $e'); }
      } else {
        _hasMore = false;
      }
    } catch (e) {
      debugPrint('PostsProvider: Load More Error: $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  void _listenForNewPosts() {
    _newPostsSubscription?.cancel();
    // Lightweight stream: listens only to the single most recent post
    _newPostsSubscription = FirebaseFirestore.instance
        .collection('posts')
        .where('showInCommunity', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final newestPostDate = (snapshot.docs.first.data()['createdAt'] as Timestamp).toDate();
        if (_latestPostDate != null && newestPostDate.isAfter(_latestPostDate!)) {
          if (!_hasNewPosts) {
            _hasNewPosts = true;
            notifyListeners();
          }
        }
      }
    });
  }

  Future<String?> uploadPostImage(File imageFile) async {
    return await CloudinaryService().uploadImage(imageFile, folder: 'posts');
  }

  Future<bool> createPost({
    required String userId,
    required String userName,
    String? userRole,
    String? userJobTitle,
    String? userImageUrl,
    File? imageFile,
    List<File>? imageFiles,
    String? caption,
    String? category,
    List<String>? mentionedUsers,
    bool showInCommunity = true,
    bool showInProfile = true,
    double? price,
    List<String>? productSizes,
    String? productCondition,
    String? productAgeGroup,
    List<String>? productColors,
    int? quantity,
    bool hasShipping = false,
  }) async {
    try {
      _isCreating = true;
      _errorMessage = null;
      notifyListeners();

      String? imageUrl;
      List<String> imageUrls = [];

      // Support both single imageFile (legacy) and multiple imageFiles
      final filesToUpload = <File>[];
      if (imageFiles != null && imageFiles.isNotEmpty) {
        filesToUpload.addAll(imageFiles);
      } else if (imageFile != null) {
        filesToUpload.add(imageFile);
      }

      if (filesToUpload.isNotEmpty) {
        // Upload all images in parallel
        final futures = filesToUpload.map((f) => uploadPostImage(f));
        final results = await Future.wait(futures);
        for (final url in results) {
          if (url == null) {
            throw Exception("فشل رفع الصورة برجاء التحقق من اتصالك بالإنترنت");
          }
          imageUrls.add(url);
        }
        // Keep first image as imageUrl for backward compatibility
        imageUrl = imageUrls.first;
      }

      final post = PostModel(
        id: '',
        userId: userId,
        userName: userName,
        userRole: userRole,
        userJobTitle: userJobTitle,
        userImageUrl: userImageUrl,
        imageUrl: imageUrl,
        imageUrls: imageUrls,
        caption: caption,
        category: category,
        mentionedUsers: mentionedUsers ?? [],
        showInCommunity: showInCommunity,
        showInProfile: showInProfile,
        price: price,
        productSizes: productSizes ?? [],
        productCondition: productCondition,
        productAgeGroup: productAgeGroup,
        productColors: productColors ?? [],
        quantity: quantity,
        hasShipping: hasShipping,
        createdAt: DateTime.now(),
      );

      final newPostId = await _firestoreService.createPost(post);
      
      // Notify mentioned users
      if (mentionedUsers != null && mentionedUsers.isNotEmpty) {
        for (final mentionedId in mentionedUsers) {
          final notification = NotificationModel(
             id: '',
             userId: mentionedId,
             type: NotificationType.mention,
             title: 'إشارة جديدة 📢',
             message: 'قام $userName بالإشارة إليك في منشور',
             createdAt: Timestamp.now(),
             relatedId: newPostId,
          );
          
          await _firestoreService.sendNotification(notification);
        }
      }

      // Notify Followers if it's a Shop
      if (userRole == 'shop') {
        final userDoc = await _firestoreService.getUser(userId);
        if (userDoc != null && userDoc.followers.isNotEmpty) {
          for (final followerId in userDoc.followers) {
            final notification = NotificationModel(
              id: '',
              userId: followerId,
              type: NotificationType.follow,
              title: 'منتج جديد من $userName 🛍️',
              message: 'قام $userName بإضافة منتج جديد، تفقد المتجر الآن!',
              createdAt: Timestamp.now(),
              relatedId: userId,
            );
            await _firestoreService.sendNotification(notification);
          }
        }
      }

      _isCreating = false;
      notifyListeners();

      // Track post creation analytics
      _analytics.logPostCreated(newPostId, category, imageUrl != null);

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isCreating = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> addComment({
    required String postId,
    required String postOwnerId,
    required String userId,
    required String userName,
    String? userImageUrl,
    required String content,
    String? parentId,
    String? parentUserName,
    String? parentUserId,
    List<String> mentionedNames = const [],
  }) async {
    final comment = CommentModel(
      id: '',
      postId: postId,
      userId: userId,
      userName: userName,
      userImageUrl: userImageUrl,
      content: content,
      createdAt: DateTime.now(),
      parentId: parentId,
      parentUserName: parentUserName,
      isReply: parentId != null,
      mentionedNames: mentionedNames,
    );

    // Optimistic Update Locally
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index != -1) {
      final post = _posts[index];
      _posts[index] = post.copyWith(commentsCount: post.commentsCount + 1);
      notifyListeners();
    }

    await _firestoreService.addComment(comment, postOwnerId: postOwnerId, parentUserId: parentUserId);
  }

  /// Optimistic decrement of comment count when deleting a comment
  void decrementCommentCount(String postId) {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index != -1) {
      final post = _posts[index];
      _posts[index] = post.copyWith(commentsCount: (post.commentsCount - 1).clamp(0, 999999));
      notifyListeners();
    }
  }

  Future<void> reactToPost(String postId, String userId, String userName, String postOwnerId, String reactionType) async {
    // Optimistic Update Locally
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index != -1) {
      final post = _posts[index];
      if (reactionType == 'unlike') {
        post.reactions.remove(userId);
      } else {
        post.reactions[userId] = reactionType;
      }
      notifyListeners();
    }

    if (reactionType == 'unlike') {
      await _firestoreService.removeReaction(postId, userId);
    } else {
      await _firestoreService.reactToPost(postId, userId, reactionType);
    }
    
    // Send notification to post owner (only on like, not unlike) with rate limiting
    if (reactionType != 'unlike' && userId != postOwnerId) {
      final rateLimitKey = '${postId}_like_$userId';
      if (_canSendNotif(rateLimitKey)) {
        _markNotifSent(rateLimitKey);
        final notification = NotificationModel(
          id: '',
          userId: postOwnerId,
          type: NotificationType.like,
          title: 'تفاعل جديد',
          message: 'أعجب $userName بمنشورك',
          createdAt: Timestamp.now(),
          relatedId: postId,
        );
        await _firestoreService.sendNotification(notification);
      }
    }
  }

  Future<void> removeReaction(String postId, String userId) async {
    await _firestoreService.removeReaction(postId, userId);
  }

  Future<void> toggleReaction(String postId, String userId, String userName, String reactionType, String postOwnerId, String? currentReaction) async {
    // 1. Check if post exists locally
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    final post = _posts[index];
    final oldReactions = Map<String, String>.from(post.reactions);
    
    // 2. Optimistic Update (Immediate Feedback)
    if (currentReaction == reactionType) {
      // Remove reaction
      post.reactions.remove(userId);
    } else {
      // Add/Update reaction
      post.reactions[userId] = reactionType;
    }
    
    // Notify listeners to update UI instantly
    notifyListeners();

    // 3. Perform Network Request
    try {
      if (currentReaction == reactionType) {
        await removeReaction(postId, userId);
      } else {
        await reactToPost(postId, userId, userName, postOwnerId, reactionType);
      }
    } catch (e) {
      // 4. Rollback on Error
      post.reactions.clear();
      post.reactions.addAll(oldReactions);
      notifyListeners();
      _errorMessage = 'Failed to update reaction: $e';
      notifyListeners();
    }
  }

  Future<bool> deletePost(String postId) async {
    try {
      _isUpdating = true;
      notifyListeners();

      await _firestoreService.deletePost(postId);
      _posts.removeWhere((p) => p.id == postId);
      
      _isUpdating = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isUpdating = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> togglePin(String postId) async {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    final post = _posts[index];
    final oldStatus = post.isPinned;
    
    // Optimistic Update
    _posts[index] = post.copyWith(isPinned: !oldStatus);
    notifyListeners();

    try {
      await _firestoreService.togglePin(postId, !oldStatus);
    } catch (e) {
      // Rollback
      _posts[index] = post.copyWith(isPinned: oldStatus);
      notifyListeners();
      _errorMessage = 'Failed to update pin status: $e';
      notifyListeners();
    }
  }

  Future<bool> updatePost({
    required String postId,
    File? imageFile,
    List<File>? imageFiles,
    String? caption,
    String? category,
    List<String>? mentionedUsers,
    bool? showInCommunity,
    bool? showInProfile,
    double? price,
    List<String>? productSizes,
    String? productCondition,
    String? productAgeGroup,
    List<String>? productColors,
    int? quantity,
    bool? hasShipping,
  }) async {
    try {
      _isUpdating = true;
      notifyListeners();

      final updates = <String, dynamic>{};
      if (caption != null) updates['caption'] = caption;
      if (category != null) updates['category'] = category;
      if (mentionedUsers != null) updates['mentionedUsers'] = mentionedUsers;
      if (showInCommunity != null) updates['showInCommunity'] = showInCommunity;
      if (showInProfile != null) updates['showInProfile'] = showInProfile;
      if (price != null) updates['price'] = price;
      if (productSizes != null) updates['productSizes'] = productSizes;
      if (productCondition != null) updates['productCondition'] = productCondition;
      if (productAgeGroup != null) updates['productAgeGroup'] = productAgeGroup;
      if (productColors != null) updates['productColors'] = productColors;
      if (quantity != null) updates['quantity'] = quantity;
      if (hasShipping != null) updates['hasShipping'] = hasShipping;

      // Handle multiple images
      final filesToUpload = <File>[];
      if (imageFiles != null && imageFiles.isNotEmpty) {
        filesToUpload.addAll(imageFiles);
      } else if (imageFile != null) {
        filesToUpload.add(imageFile);
      }

      if (filesToUpload.isNotEmpty) {
        final futures = filesToUpload.map((f) => uploadPostImage(f));
        final results = await Future.wait(futures);
        final uploadedUrls = <String>[];
        for (final url in results) {
          if (url != null) uploadedUrls.add(url);
        }
        if (uploadedUrls.isNotEmpty) {
          updates['imageUrl'] = uploadedUrls.first;
          updates['imageUrls'] = uploadedUrls;
        }
      }

      await _firestoreService.updatePost(postId, updates);
      
      _isUpdating = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isUpdating = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> incrementPostShares(String postId) async {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    final post = _posts[index];
    
    // Optimistic Update
    _posts[index] = post.copyWith(sharesCount: post.sharesCount + 1);
    notifyListeners();

    try {
      await _firestoreService.incrementPostShares(postId);
      // Track share analytics
      _analytics.logPostShared(postId);
    } catch (e) {
      // Rollback
      _posts[index] = post;
      notifyListeners();
      debugPrint('Error incrementing shares: $e');
    }
  }

  void clear() {
    _postsSubscription?.cancel();
    _newPostsSubscription?.cancel();
    _posts = [];
    _isLoading = false;
    _isCreating = false;
    _isUpdating = false;
    _errorMessage = null;
    _postsLoaded = false;
    _lastDoc = null;
    _hasMore = true;
    _hasNewPosts = false;
    _latestPostDate = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _postsSubscription?.cancel();
    _newPostsSubscription?.cancel();
    super.dispose();
  }
}
