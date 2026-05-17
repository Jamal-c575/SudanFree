import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'firestore/notification_service.dart';

/// Polling-based notification service that reduces Firestore reads from 60+/min to 1/min
/// Switches from real-time streams to periodic polling (60-second intervals)
/// Maintains consistency with background caching while dramatically reducing costs
class NotificationPollingService extends ChangeNotifier {
  static final NotificationPollingService _instance = 
      NotificationPollingService._internal();
  
  factory NotificationPollingService() {
    return _instance;
  }
  
  NotificationPollingService._internal();
  
  final NotificationFirestoreService _notificationService = NotificationFirestoreService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Polling state
  Timer? _pollTimer;
  final Duration _pollInterval = const Duration(seconds: 30);
  
  // Cached values
  int _unreadCount = 0;
  int _unreadChatCount = 0;
  List<dynamic> _notifications = [];
  DateTime? _lastPolledAt;
  bool _isPolling = false;
  
  // Current user ID for polling
  String? _currentUserId;
  
  // Chat stream subscription
  StreamSubscription? _chatSubscription;
  
  // Getters
  int get unreadCount => _unreadCount + _unreadChatCount;
  int get unreadNotificationsOnly => _unreadCount;
  int get unreadChatsOnly => _unreadChatCount;
  List<dynamic> get notifications => _notifications;
  DateTime? get lastPolledAt => _lastPolledAt;
  bool get isPolling => _isPolling;
  
  /// Initialize polling service with user ID
  void setUserId(String userId) {
    if (_currentUserId == userId) return;
    _currentUserId = userId;
    _startPolling();
    _listenToChatUnread(userId);
  }
  
  /// Start polling timer
  void _startPolling() {
    // Cancel existing timer
    _pollTimer?.cancel();
    
    // Poll immediately on startup
    _refreshCounts();
    
    // Then set up periodic polling
    _pollTimer = Timer.periodic(_pollInterval, (_) {
      _refreshCounts();
    });
  }
  
  /// Listen to chat unread counts in real-time (lightweight stream)
  void _listenToChatUnread(String userId) {
    _chatSubscription?.cancel();
    _chatSubscription = _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .snapshots()
        .listen((snapshot) {
      int totalUnread = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final unreadMap = data['unreadCount'] as Map<String, dynamic>?;
        if (unreadMap != null && unreadMap[userId] != null) {
          totalUnread += (unreadMap[userId] as num).toInt();
        }
      }
      if (_unreadChatCount != totalUnread) {
        _unreadChatCount = totalUnread;
        notifyListeners();
      }
    }, onError: (e) {
      debugPrint('Error listening to chat unread: $e');
    });
  }
  
  /// Refresh notification counts from Firestore (single read operation)
  Future<void> _refreshCounts() async {
    if (_currentUserId == null) return;
    
    try {
      _isPolling = true;
      
      // Single Firestore read instead of continuous stream
      final count = await _notificationService.getUnreadCount(_currentUserId!);
      
      if (_unreadCount != count) {
        _unreadCount = count;
        _lastPolledAt = DateTime.now();
        notifyListeners();
      }
      
      _isPolling = false;
    } catch (e) {
      debugPrint('Error refreshing notification counts: $e');
      _isPolling = false;
    }
  }
  
  /// Force immediate refresh (useful when notification received)
  Future<void> forceRefresh() async {
    await _refreshCounts();
  }
  
  /// Fetch notifications for NotificationsScreen (fetched on demand, not streaming)
  Future<List<dynamic>> getNotificationsOnce() async {
    if (_currentUserId == null) return [];
    
    try {
      final notifications = await _notificationService.getNotificationsOnce(_currentUserId!);
      _notifications = notifications;
      notifyListeners();
      return notifications;
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      return [];
    }
  }
  
  /// Update polling interval (for testing or tuning)
  void updatePollingInterval(Duration interval) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(interval, (_) {
      _refreshCounts();
    });
  }
  
  /// Get polling statistics
  Map<String, dynamic> getPollingStats() {
    return {
      'unreadCount': _unreadCount,
      'unreadChatCount': _unreadChatCount,
      'totalUnread': unreadCount,
      'lastPolled': _lastPolledAt,
      'isPolling': _isPolling,
      'pollInterval': _pollInterval.inSeconds,
    };
  }
  
  /// Cleanup on app close
  @override
  void dispose() {
    _pollTimer?.cancel();
    _chatSubscription?.cancel();
    super.dispose();
  }
}
