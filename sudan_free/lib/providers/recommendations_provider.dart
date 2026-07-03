import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../services/cache_service.dart';

class RecommendationsProvider with ChangeNotifier {
  final List<Map<String, dynamic>> _recommendations = [];
  bool _isLoading = false;
  String? _error;
  DateTime? _lastFetchTime;

  List<Map<String, dynamic>> get recommendations => _recommendations;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Returns recommendation user IDs only (lightweight)
  List<String> get recommendedUserIds =>
      _recommendations.map((e) => e['userId'] as String? ?? '').where((id) => id.isNotEmpty).toList();

  bool get hasRecommendations => _recommendations.isNotEmpty;

  Future<void> fetchRecommendations({
    required String userId,
    required double lat,
    required double lng,
    String? category,
    bool forceRefresh = false,
  }) async {
    // --- Cache-first strategy: if fresh data available, use it immediately ---
    if (!forceRefresh) {
      final cache = CacheService();
      if (cache.isRecommendationsCacheValid()) {
        final cached = cache.getCachedRecommendations();
        if (cached != null && cached.isNotEmpty) {
          _recommendations.clear();
          _recommendations.addAll(cached);
          _error = null;
          notifyListeners();
          // Still refresh in background if > 15 minutes old
          _refreshInBackground(userId, lat, lng, category);
          return;
        }
      }
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    await _doFetch(userId, lat, lng, category);
  }

  Future<void> _doFetch(String userId, double lat, double lng, String? category) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'calculateRecommendations',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 15)),
      );
      final results = await callable.call<Map<String, dynamic>>({
        'userId': userId,
        'lat': lat,
        'lng': lng,
        if (category != null) 'category': category,
      });

      final Map<String, dynamic> responseData = Map<String, dynamic>.from(results.data);
      final List<dynamic> recsList = responseData['recommendations'] as List<dynamic>? ?? [];

      _recommendations.clear();
      _recommendations.addAll(recsList.map((e) => Map<String, dynamic>.from(e as Map)));
      _error = null;
      _lastFetchTime = DateTime.now();

      // Persist to Hive cache
      await CacheService().cacheRecommendations(List.from(_recommendations));
    } catch (e) {
      _error = e.toString();
      debugPrint('RecommendationsProvider error: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Silently refresh in the background without showing loading indicator
  void _refreshInBackground(String userId, double lat, double lng, String? category) {
    final lastFetch = _lastFetchTime;
    if (lastFetch != null && DateTime.now().difference(lastFetch) < const Duration(minutes: 15)) {
      return; // Too recent, skip background refresh
    }
    Future.microtask(() => _doFetch(userId, lat, lng, category));
  }

  /// Invalidate cache and force a fresh fetch on next call
  void invalidateCache() {
    _lastFetchTime = null;
    _recommendations.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _recommendations.clear();
    super.dispose();
  }
}
