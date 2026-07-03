import 'dart:async';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/filter_model.dart';
import '../services/smart_search_service.dart';
import '../services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/analytics_service.dart';

class SearchProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final AnalyticsService _analytics = AnalyticsService();

  List<UserModel> _searchResults = [];
  List<String> _suggestions = [];
  List<String> _recentSearches = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = false;
  DocumentSnapshot? _lastDoc;
  UserRole? _currentRole;
  String? _currentQuery;

  String? _errorMessage;
  List<UserModel> _cachedProviders = [];

  // ─── Active filter ───────────────────────────────────────────────────────
  SearchFilter _currentFilter = const SearchFilter();
  SearchFilter get currentFilter => _currentFilter;

  // Debounce timer to avoid firing a search on every keystroke
  Timer? _debounceTimer;
  static const _debounceDuration = Duration(milliseconds: 300);

  List<UserModel> get searchResults => _searchResults;
  List<String> get suggestions => _suggestions;
  List<String> get recentSearches => _recentSearches;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;

  /// Fetch and cache providers for suggestions
  Future<void> _ensureCached() async {
    if (_cachedProviders.isNotEmpty) return;
    final result = await _firestoreService.getProvidersPaginated(limit: 50);
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
    UserRole? role,
  }) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      searchFreelancers(
        query: query,
        state: state,
        locality: locality,
        minRating: minRating,
        category: category,
        role: role,
      );
    });
  }

  Future<void> searchFreelancers({
    String? query,
    String? state,
    String? locality,
    double? minRating,
    String? category,
    UserRole? role,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _lastDoc = null;
    _hasMore = false;
    _currentRole = role;
    _currentQuery = query;
    notifyListeners();

    try {
      await _ensureCached();
      List<UserModel> users = List<UserModel>.from(_cachedProviders);

      if (query != null && query.isNotEmpty) {
        final normalizedQuery = _normalize(query);
        final words = normalizedQuery
            .split(RegExp(r'\s+'))
            .where((w) => w.length >= 2)
            .toList();

        // Fetch from Firestore to ensure we get users beyond the first 50 cached
        if (words.isNotEmpty) {
          try {
            // Firestore array-contains can only check one word, so we use the first meaningful word
            final firstWord = words.first;

            Query fsQuery = FirebaseFirestore.instance
                .collection('users')
                .where('searchKeywords', arrayContains: firstWord);

            if (role != null) {
              fsQuery = fsQuery.where('role', isEqualTo: role.name);
            } else {
              fsQuery = fsQuery.where('role', whereIn: [
                'freelancer',
                'techService',
                'privateService',
                'shop'
              ]);
            }

            final queryResult = await fsQuery.limit(50).get();
            if (queryResult.docs.isNotEmpty) {
              _lastDoc = queryResult.docs.last;
              _hasMore = queryResult.docs.length == 50;
            }

            final firestoreUsers = queryResult.docs.map((d) {
              final data = d.data() as Map<String, dynamic>;
              data['id'] = d.id; // ضروري! بدونه يكون id فارغاً
              return UserModel.fromMap(data);
            }).toList();

            // Merge with cached users to ensure we don't miss local fuzzy matches
            for (var u in _cachedProviders) {
              if (!firestoreUsers.any((element) => element.id == u.id)) {
                firestoreUsers.add(u);
              }
            }
            users = firestoreUsers;
          } catch (e) {
            debugPrint("Firestore search arrayContains error: $e");
            // If index error or anything, fallback to cached users
          }
        }

        users = users.where((u) {
          // 1. Check searchKeywords first (fastest - uses pre-computed index)
          for (final keyword in u.searchKeywords) {
            if (keyword.contains(normalizedQuery) ||
                normalizedQuery.contains(keyword)) {
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
        // Track search analytics
        _analytics.logSearchQuery(query, users.length);
      } else if (role != null) {
        // If query is empty but a role filter is applied, fetch first batch
        try {
          final queryResult = await FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: role.name)
              .limit(50) // Reduced to 50 for performance and pagination
              .get();
          if (queryResult.docs.isNotEmpty) {
            _lastDoc = queryResult.docs.last;
            _hasMore = queryResult.docs.length == 50;
          }
          users = queryResult.docs.map((d) {
            final data = d.data();
            data['id'] = d.id;
            return UserModel.fromMap(data);
          }).toList();
        } catch (e) {
          debugPrint("Error fetching role only: $e");
        }
      }

      if (state != null) users = users.where((u) => u.state == state).toList();
      if (locality != null) {
        users = users.where((u) => u.locality == locality).toList();
      }
      // Merge incoming minRating param with active filter (take the stricter one)
      final effectiveMinRating = _maxNull(minRating, _currentFilter.minRating);
      if (effectiveMinRating != null) {
        users = users.where((u) => u.rating >= effectiveMinRating).toList();
      }
      final effectiveCategory = category ?? _currentFilter.category;
      if (effectiveCategory != null) {
        users = users.where((u) => u.jobTitle == effectiveCategory).toList();
      }

      // ── SearchFilter conditions ──────────────────────────────────────────

      // Availability
      if (_currentFilter.availability != null) {
        switch (_currentFilter.availability) {
          case 'now':
            users = users.where((u) => u.isAvailable).toList();
            break;
          case 'today':
            // Treat same as "now" — isAvailable flag is the best signal
            users = users.where((u) => u.isAvailable).toList();
            break;
          case '48h':
            // Within 48h: keep available users OR those active in last 2 days
            final cutoff = DateTime.now().subtract(const Duration(hours: 48));
            users = users
                .where((u) =>
                    u.isAvailable ||
                    (u.lastActive != null && u.lastActive!.isAfter(cutoff)))
                .toList();
            break;
        }
      }

      // Price range
      if (_currentFilter.priceRange != null) {
        switch (_currentFilter.priceRange) {
          case 'free':
            users = users
                .where((u) => u.hourlyRate == null || u.hourlyRate == 0)
                .toList();
            break;
          case '0-5000':
            users = users
                .where((u) =>
                    u.hourlyRate != null &&
                    u.hourlyRate! > 0 &&
                    u.hourlyRate! <= 5000)
                .toList();
            break;
          case '5000-20000':
            users = users
                .where((u) =>
                    u.hourlyRate != null &&
                    u.hourlyRate! > 5000 &&
                    u.hourlyRate! <= 20000)
                .toList();
            break;
          case '20000+':
            users = users
                .where(
                    (u) => u.hourlyRate != null && u.hourlyRate! > 20000)
                .toList();
            break;
        }
      }

      // If query was not empty, role is filtered here locally. If query was empty, we already fetched by role from DB.
      if (role != null && (query != null && query.isNotEmpty)) {
        users = users.where((u) => u.role == role).toList();
      }

      // ── Sort override (only when no text query, which already sorts by relevance) ──
      if (_currentFilter.sortBy != null &&
          (query == null || query.isEmpty)) {
        switch (_currentFilter.sortBy) {
          case 'rating':
            users.sort((a, b) => b.rating.compareTo(a.rating));
            break;
          case 'newest':
            users.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            break;
          case 'cheapest':
            users.sort((a, b) {
              final ra = a.hourlyRate ?? double.maxFinite;
              final rb = b.hourlyRate ?? double.maxFinite;
              return ra.compareTo(rb);
            });
            break;
          // 'nearest' requires geolocation — skip if no lat/lng available
          case 'nearest':
            // Best-effort: sort by those who have coordinates first
            users.sort((a, b) {
              final aHas =
                  (a.latitude != null && a.longitude != null) ? 0 : 1;
              final bHas =
                  (b.latitude != null && b.longitude != null) ? 0 : 1;
              return aHas.compareTo(bHas);
            });
            break;
        }
      } else if (_currentFilter.sortBy != null &&
          query != null &&
          query.isNotEmpty) {
        // When text search is active, only apply non-relevance sorts
        switch (_currentFilter.sortBy) {
          case 'rating':
            users.sort((a, b) => b.rating.compareTo(a.rating));
            break;
          case 'cheapest':
            users.sort((a, b) {
              final ra = a.hourlyRate ?? double.maxFinite;
              final rb = b.hourlyRate ?? double.maxFinite;
              return ra.compareTo(rb);
            });
            break;
          default:
            break; // keep relevance sort for 'nearest' and 'newest'
        }
      }

      _searchResults = users;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore || _lastDoc == null) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      List<UserModel> newUsers = [];

      if (_currentQuery != null && _currentQuery!.isNotEmpty) {
        final normalizedQuery = _normalize(_currentQuery!);
        final words = normalizedQuery
            .split(RegExp(r'\s+'))
            .where((w) => w.length >= 2)
            .toList();
        if (words.isNotEmpty) {
          final firstWord = words.first;
          Query fsQuery = FirebaseFirestore.instance
              .collection('users')
              .where('searchKeywords', arrayContains: firstWord);

          if (_currentRole != null) {
            fsQuery = fsQuery.where('role', isEqualTo: _currentRole!.name);
          } else {
            fsQuery = fsQuery.where('role', whereIn: [
              'freelancer',
              'techService',
              'privateService',
              'shop'
            ]);
          }

          final queryResult =
              await fsQuery.startAfterDocument(_lastDoc!).limit(50).get();
          if (queryResult.docs.isNotEmpty) {
            _lastDoc = queryResult.docs.last;
            _hasMore = queryResult.docs.length == 50;
            newUsers = queryResult.docs.map((d) {
              final data = d.data() as Map<String, dynamic>;
              data['id'] = d.id;
              return UserModel.fromMap(data);
            }).toList();
          } else {
            _hasMore = false;
          }
        }
      } else if (_currentRole != null) {
        final queryResult = await FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: _currentRole!.name)
            .startAfterDocument(_lastDoc!)
            .limit(50)
            .get();
        if (queryResult.docs.isNotEmpty) {
          _lastDoc = queryResult.docs.last;
          _hasMore = queryResult.docs.length == 50;
          newUsers = queryResult.docs.map((d) {
            final data = d.data();
            data['id'] = d.id;
            return UserModel.fromMap(data);
          }).toList();
        } else {
          _hasMore = false;
        }
      }

      if (newUsers.isNotEmpty) {
        _searchResults.addAll(newUsers);
      }
      _isLoadingMore = false;
      notifyListeners();
    } catch (e) {
      _isLoadingMore = false;
      _hasMore = false;
      debugPrint("Search loadMore error: $e");
      notifyListeners();
    }
  }

  void clearSearch() {
    _debounceTimer?.cancel();
    _searchResults = [];
    _suggestions = [];
    _errorMessage = null;
    _lastDoc = null;
    _hasMore = false;
    notifyListeners();
  }

  // ─── Filter helpers ───────────────────────────────────────────────────────

  /// Apply a new [SearchFilter] and re-run the last search with it.
  void applyFilter(SearchFilter filter) {
    _currentFilter = filter;
    // Re-run the last search so results update immediately.
    searchFreelancers(
      query: _currentQuery,
      role: _currentRole,
    );
  }

  /// Clear all active filters and re-run the last search.
  void clearFilter() {
    _currentFilter = const SearchFilter();
    searchFreelancers(
      query: _currentQuery,
      role: _currentRole,
    );
  }

  /// Invalidate cache (call when data might have changed)
  void invalidateCache() {
    _cachedProviders = [];
  }

  /// Returns the larger of two nullable doubles.
  /// Used to pick the stricter minRating between what a caller passes and the
  /// currently active filter.
  double? _maxNull(double? a, double? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a > b ? a : b;
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
