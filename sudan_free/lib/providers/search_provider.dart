import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/smart_search_service.dart';
import '../services/firestore_service.dart';

class SearchProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<UserModel> _searchResults = [];
  List<String> _suggestions = [];
  bool _isLoading = false;
  String? _errorMessage;
  List<UserModel> _cachedProviders = [];

  List<UserModel> get searchResults => _searchResults;
  List<String> get suggestions => _suggestions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Fetch and cache providers for suggestions
  Future<void> _ensureCached() async {
    if (_cachedProviders.isNotEmpty) return;
    final result = await _firestoreService.getProvidersPaginated(limit: 200);
    _cachedProviders = List<UserModel>.from(result['users']);
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
          // 1. Check searchKeywords first (fastest)
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
}
