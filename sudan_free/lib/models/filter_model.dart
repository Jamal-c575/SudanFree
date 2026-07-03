/// Model that holds all active search/filter criteria.
class SearchFilter {
  /// Maximum distance in km. `null` means "show all" regardless of distance.
  final double? maxDistanceKm;

  /// Minimum rating (1-5). `null` means "show all" regardless of rating.
  final double? minRating;

  /// Price range string.
  ///   - `'free'`       → مجاني
  ///   - `'0-5000'`     → 0 – 5,000 SDG
  ///   - `'5000-20000'` → 5,000 – 20,000 SDG
  ///   - `'20000+'`     → +20,000 SDG
  ///   - `null`         → any price
  final String? priceRange;

  /// Availability window.
  ///   - `'now'`   → متوفر الآن (isAvailable == true)
  ///   - `'today'` → اليوم
  ///   - `'48h'`   → خلال 48 ساعة
  ///   - `null`    → any
  final String? availability;

  /// Sort criterion.
  ///   - `'nearest'`  → الأقرب
  ///   - `'rating'`   → الأعلى تقييماً
  ///   - `'newest'`   → الأحدث
  ///   - `'cheapest'` → الأرخص
  ///   - `null`       → default relevance sort
  final String? sortBy;

  /// Free-text category / job-title filter. `null` means any category.
  final String? category;

  const SearchFilter({
    this.maxDistanceKm,
    this.minRating,
    this.priceRange,
    this.availability,
    this.sortBy,
    this.category,
  });

  /// Returns a copy of this filter with the given fields overridden.
  SearchFilter copyWith({
    Object? maxDistanceKm = _sentinel,
    Object? minRating = _sentinel,
    Object? priceRange = _sentinel,
    Object? availability = _sentinel,
    Object? sortBy = _sentinel,
    Object? category = _sentinel,
  }) {
    return SearchFilter(
      maxDistanceKm: maxDistanceKm == _sentinel
          ? this.maxDistanceKm
          : maxDistanceKm as double?,
      minRating:
          minRating == _sentinel ? this.minRating : minRating as double?,
      priceRange:
          priceRange == _sentinel ? this.priceRange : priceRange as String?,
      availability: availability == _sentinel
          ? this.availability
          : availability as String?,
      sortBy: sortBy == _sentinel ? this.sortBy : sortBy as String?,
      category: category == _sentinel ? this.category : category as String?,
    );
  }

  /// `true` when at least one meaningful filter is set (sortBy is excluded —
  /// sorting alone is not considered "active filtering").
  bool get isActive =>
      maxDistanceKm != null ||
      minRating != null ||
      priceRange != null ||
      availability != null ||
      category != null;

  /// A blank filter — no criteria set, no sort override.
  static const SearchFilter empty = SearchFilter();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchFilter &&
          runtimeType == other.runtimeType &&
          maxDistanceKm == other.maxDistanceKm &&
          minRating == other.minRating &&
          priceRange == other.priceRange &&
          availability == other.availability &&
          sortBy == other.sortBy &&
          category == other.category;

  @override
  int get hashCode => Object.hash(
        maxDistanceKm,
        minRating,
        priceRange,
        availability,
        sortBy,
        category,
      );

  @override
  String toString() => 'SearchFilter('
      'maxDistanceKm: $maxDistanceKm, '
      'minRating: $minRating, '
      'priceRange: $priceRange, '
      'availability: $availability, '
      'sortBy: $sortBy, '
      'category: $category)';
}

/// Private sentinel used to distinguish "not provided" from `null` in copyWith.
const Object _sentinel = Object();
