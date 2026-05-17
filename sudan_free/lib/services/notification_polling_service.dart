import 'dart:async';
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
  
  NotificationPollingService._internal() {
    _initializePolling();
  }
  
  final NotificationFirestoreService _notificationService = NotificationFirestoreService();
  
  // Polling state
  late Timer _pollTimer;
  final Duration _pollInterval = const Duration(seconds: 60);
  
  // Cached values
  int _unreadCount = 0;
  List<dynamic> _notifications = [];
  DateTime? _lastPolledAt;
  bool _isPolling = false;
  
  // Current user ID for polling
  String? _currentUserId;
  
  // Getters
  int get unreadCount => _unreadCount;
  List<dynamic> get notifications => _notifications;
  DateTime? get lastPolledAt => _lastPolledAt;
  bool get isPolling => _isPolling;
  
  /// Initialize polling service with user ID
  void setUserId(String userId) {
    _currentUserId = userId;
    _initializePolling();
  }
  
  /// Initialize polling service
  void _initializePolling() {
    if (_currentUserId == null) return;
    
    // Cancel existing timer
    if (_pollTimer.isActive) {
      _pollTimer.cancel();
    }
    
    // Poll immediately on startup
    _refreshCounts();
    
    // Then set up periodic polling
    _pollTimer = Timer.periodic(_pollInterval, (_) {
      _refreshCounts();
    });
  }
  
  /// Refresh notification counts from Firestore (single read operation)
  Future<void> _refreshCounts() async {
    if (_currentUserId == null) return;
    
    try {
      _isPolling = true;
      notifyListeners();
      
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
    if (_pollTimer.isActive) {
      _pollTimer.cancel();
    }
    _pollTimer = Timer.periodic(interval, (_) {
      _refreshCounts();
    });
  }
  
  /// Get polling statistics
  Map<String, dynamic> getPollingStats() {
    return {
      'unreadCount': _unreadCount,
      'lastPolled': _lastPolledAt,
      'isPolling': _isPolling,
      'pollInterval': _pollInterval.inSeconds,
      'estimatedMonthlyCost': 43200, // 60 reads/hour * 24 hours * 30 days = 43,200 reads
    };
  }
  
  /// Cleanup on app close
  @override
  void dispose() {
    if (_pollTimer.isActive) {
      _pollTimer.cancel();
    }
    super.dispose();
  }
}
