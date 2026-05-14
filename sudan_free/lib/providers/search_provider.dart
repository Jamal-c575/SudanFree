import 'dart:async';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/smart_search_service.dart';
import '../services/firestore_service.dart';
import '../services/analytics_service.dart';

class SearchProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final AnalyticsService _analytics = AnalyticsService();

  List<UserModel> _searchResults = [];
  List<String> _suggestions = [];
  List<String> _recentSearches = [];
  bool _isLoading = false;
  String? _errorMessage;
  List<UserModel> _cachedProviders = [];

  // Debounce timer to avoid firing a search on every keystroke
  Timer? _debounceTimer;
  static const _debounceDuration = Duration(milliseconds: 300);

  List<UserModel> get searchResults => _searchResults;
  List<String> get suggestions => _suggestions;
  List<String> get recentSearches => _recentSearches;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Fetch and cache providers for suggestions
  Future<void> _ensureCached() async {
    if (_cachedProviders.isNotEmpty) return;
    final result = await _firestoreService.getProvidersPaginated(limit: 200);
    _cachedProviders = List<UserModel>.from(result['users']);
  }

  /// Save search to recent searches
  void _addToRecentSearches(String query) {
    if (query.isEmpty) return;
    
    _recentSearches.remove(query); // Remove if already exists
    _recentSearches.insert(0, query); // Add to beginning
    
    // Keep only last 10 searches
    if (_recentSearches.length > 10) {
      _recentSearches = _recentSearches.sublist(0, 10);
    }
    
    notifyListeners();
  }

  /// Generate keyword suggestions based on partial query
  Future<void> updateSuggestions(String query) async {
    if (query.isEmpty) {
      _suggestions = [];
      notifyListeners();
      return;
    }

    // استخدم الكلمات المحفوظة داخل التطبيق (سريعة جداً ولا تعتمد على المستخدمين المحملين)
    _suggestions = SmartSearchService.getPredefinedSuggestions(query);
    notifyListeners();
  }

  /// Debounced search — waits 300ms after the last keystroke before executing
  void searchFreelancersDebounced({
    String? query,
    String? state,
    String? locality,
    double? minRating,
    String? category,
  }) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      searchFreelancers(
        query: query,
        state: state,
        locality: locality,
        minRating: minRating,
        category: category,
      );
    });
  }

  Future<void> searchFreelancers({
    String? query,
    String? state,
    String? locality,
    double? minRating,
    String? category,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _ensureCached();
      List<UserModel> users = List<UserModel>.from(_cachedProviders);

      if (query != null && query.isNotEmpty) {
        final normalizedQuery = _normalize(query);
        
        users = users.where((u) {
          // 1. Check searchKeywords first (fastest - uses pre-computed index)
          for (final keyword in u.searchKeywords) {
            if (keyword.contains(normalizedQuery) || normalizedQuery.contains(keyword)) {
              return true;
            }
          }
          
          // 2. Fallback to smart search (synonym matching, fuzzy, etc.)
          return SmartSearchService.matchesSmartSearch(
            query,
            name: u.name,
            skills: u.skills,
            jobTitle: u.jobTitle,
            bio: u.bio,
            state: u.state,
            locality: u.locality,
          );
        }).toList();

        // Sort by relevance score
        users.sort((a, b) {
          final scoreA = SmartSearchService.calculateRelevanceScore(
            query,
            name: a.name,
            skills: a.skills,
            jobTitle: a.jobTitle,
            bio: a.bio,
          );
          final scoreB = SmartSearchService.calculateRelevanceScore(
            query,
            name: b.name,
            skills: b.skills,
            jobTitle: b.jobTitle,
            bio: b.bio,
          );
          return scoreB.compareTo(scoreA); // Higher score first
        });

        // Add to recent searches
        _addToRecentSearches(query);

        // Track search analytics
        _analytics.logSearchQuery(query, users.length);
      }

      if (state != null) users = users.where((u) => u.state == state).toList();
      if (locality != null) users = users.where((u) => u.locality == locality).toList();
      if (minRating != null) users = users.where((u) => u.rating >= minRating).toList();
      if (category != null) users = users.where((u) => u.jobTitle == category).toList();

      _searchResults = users;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void clearSearch() {
    _debounceTimer?.cancel();
    _searchResults = [];
    _suggestions = [];
    _errorMessage = null;
    notifyListeners();
  }

  /// Invalidate cache (call when data might have changed)
  void invalidateCache() {
    _cachedProviders = [];
  }

  String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .replaceAll(RegExp(r'[\u064B-\u065F]'), '')
        .trim();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
