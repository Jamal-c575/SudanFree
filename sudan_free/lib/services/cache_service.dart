import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  static const String _jobsBoxName = 'jobs_cache';
  static const String _userBoxName = 'user_cache';
  static const String _settingsBoxName = 'settings';
  static const String _dataBoxName = 'app_data_cache';

  Box<String>? _jobsBox;
  Box<String>? _userBox;
  Box<dynamic>? _settingsBox;
  Box<String>? _dataBox;

  // Initialize Hive
  Future<void> initialize() async {
    await Hive.initFlutter();
    
    _jobsBox = await Hive.openBox<String>(_jobsBoxName);
    _userBox = await Hive.openBox<String>(_userBoxName);
    _settingsBox = await Hive.openBox<dynamic>(_settingsBoxName);
    _dataBox = await Hive.openBox<String>(_dataBoxName);
  }

  // Helper to ensure box is ready
  Future<void> _ensureReady() async {
    if (_settingsBox == null) await initialize();
  }

  // ==================== DATA CACHE (Generic Lists) ====================

  // --- Freelancers ---
  Future<void> cacheFreelancers(List<Map<String, dynamic>> data) async {
    await _ensureReady();
    await _dataBox?.put('freelancers_list', jsonEncode(data));
    await _dataBox?.put('freelancers_cached_at', DateTime.now().toIso8601String());
  }

  List<Map<String, dynamic>>? getCachedFreelancers() {
    final String? data = _dataBox?.get('freelancers_list');
    if (data == null) return null;
    try {
      return List<Map<String, dynamic>>.from(jsonDecode(data));
    } catch (e) {
      return null;
    }
  }

  bool isFreelancersCacheValid([Duration duration = const Duration(minutes: 30)]) {
    final cachedAtString = _dataBox?.get('freelancers_cached_at');
    if (cachedAtString == null) return false;
    try {
      final cachedAt = DateTime.parse(cachedAtString);
      return DateTime.now().difference(cachedAt) < duration;
    } catch (e) {
      return false;
    }
  }

  // --- Shops ---
  Future<void> cacheShops(List<Map<String, dynamic>> data) async {
    await _ensureReady();
    await _dataBox?.put('shops_list', jsonEncode(data));
    await _dataBox?.put('shops_cached_at', DateTime.now().toIso8601String());
  }

  List<Map<String, dynamic>>? getCachedShops() {
    final String? data = _dataBox?.get('shops_list');
    if (data == null) return null;
    try {
      return List<Map<String, dynamic>>.from(jsonDecode(data));
    } catch (e) {
      return null;
    }
  }

  bool isShopsCacheValid([Duration duration = const Duration(minutes: 30)]) {
    final cachedAtString = _dataBox?.get('shops_cached_at');
    if (cachedAtString == null) return false;
    try {
      final cachedAt = DateTime.parse(cachedAtString);
      return DateTime.now().difference(cachedAt) < duration;
    } catch (e) {
      return false;
    }
  }

  // --- Posts ---
  Future<void> cachePosts(List<Map<String, dynamic>> data) async {
    await _ensureReady();
    await _dataBox?.put('posts_list', jsonEncode(data));
    await _dataBox?.put('posts_cached_at', DateTime.now().toIso8601String());
  }

  List<Map<String, dynamic>>? getCachedPosts() {
    final String? data = _dataBox?.get('posts_list');
    if (data == null) return null;
    try {
      return List<Map<String, dynamic>>.from(jsonDecode(data));
    } catch (e) {
      return null;
    }
  }

  bool isPostsCacheValid([Duration duration = const Duration(minutes: 15)]) {
    final cachedAtString = _dataBox?.get('posts_cached_at');
    if (cachedAtString == null) return false;
    try {
      final cachedAt = DateTime.parse(cachedAtString);
      return DateTime.now().difference(cachedAt) < duration;
    } catch (e) {
      return false;
    }
  }

  // ==================== JOBS CACHE ====================

  Future<void> cacheJobs(List<Map<String, dynamic>> jobs) async {
    await _ensureReady();
    final jsonString = jsonEncode(jobs);
    await _jobsBox?.put('all_jobs', jsonString);
    await _jobsBox?.put('jobs_cached_at', DateTime.now().toIso8601String());
  }

  List<Map<String, dynamic>>? getCachedJobs() {
    final jsonString = _jobsBox?.get('all_jobs');
    if (jsonString != null) {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return null;
  }

  bool isJobsCacheValid([Duration duration = const Duration(hours: 24)]) {
    final cachedAtString = _jobsBox?.get('jobs_cached_at');
    if (cachedAtString == null) return false;
    
    final cachedAt = DateTime.parse(cachedAtString);
    final now = DateTime.now();
    return now.difference(cachedAt) < duration;
  }

  // ==================== USER PROFILE CACHE ====================

  Future<void> cacheUserProfile(String userId, Map<String, dynamic> user) async {
    await _ensureReady();
    await _userBox?.put('user_$userId', jsonEncode(user));
  }

  Map<String, dynamic>? getCachedUserProfile(String userId) {
    final jsonString = _userBox?.get('user_$userId');
    if (jsonString != null) {
      return Map<String, dynamic>.from(jsonDecode(jsonString));
    }
    return null;
  }

  Future<void> clearUserCache() async {
    await _ensureReady();
    await _userBox?.clear();
  }

  /// حذف جميع البيانات المخزنة عند تسجيل الخروج (ما عدا الإعدادات)
  Future<void> clearAllData() async {
    await _ensureReady();
    await _userBox?.clear();
    await _dataBox?.clear();
    await _jobsBox?.clear();
  }

  // ==================== SETTINGS (CRITICAL) ====================

  Future<void> saveLanguage(String languageCode) async {
    await _ensureReady();
    await _settingsBox?.put('language', languageCode);
  }

  String? getLanguage() {
    if (_settingsBox == null) return null;
    return _settingsBox?.get('language') as String?;
  }

  Future<void> saveThemeMode(String mode) async {
    await _ensureReady();
    await _settingsBox?.put('theme_mode', mode);
  }

  String? getThemeMode() {
    if (_settingsBox == null) return null;
    return _settingsBox?.get('theme_mode') as String?;
  }

  Future<void> saveNotificationsEnabled(bool enabled) async {
    await _ensureReady();
    await _settingsBox?.put('notifications_enabled', enabled);
  }

  bool getNotificationsEnabled() {
    if (_settingsBox == null) return true;
    return _settingsBox?.get('notifications_enabled', defaultValue: true) as bool;
  }

  // Close all boxes
  Future<void> close() async {
    await Hive.close();
  }
}
