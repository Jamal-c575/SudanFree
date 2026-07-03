import 'package:flutter/material.dart';
import '../../models/filter_model.dart';
import '../../core/constants/app_colors.dart';
import 'glass_container.dart';

/// A premium glassmorphic bottom sheet for controlling search filters.
///
/// Usage:
/// ```dart
/// final filter = await FilterBottomSheet.show(context, current: myFilter);
/// if (filter != null) applyFilter(filter);
/// ```
class FilterBottomSheet extends StatefulWidget {
  final SearchFilter current;
  final bool isAr;

  const FilterBottomSheet({
    super.key,
    required this.current,
    required this.isAr,
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Static entry-point
  // ─────────────────────────────────────────────────────────────────────────

  /// Shows the filter bottom sheet and returns the new [SearchFilter] when the
  /// user taps "Apply", or `null` when they dismiss without confirming.
  static Future<SearchFilter?> show(
    BuildContext context, {
    SearchFilter? current,
    bool isAr = true,
  }) {
    return showModalBottomSheet<SearchFilter>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => FilterBottomSheet(
        current: current ?? const SearchFilter(),
        isAr: isAr,
      ),
    );
  }

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late SearchFilter _filter;

  // ── local mutable selections ──────────────────────────────────────────────
  double? _selectedDistance;
  double? _selectedRating;
  String? _selectedPrice;
  String? _selectedAvailability;
  String? _selectedSort;

  @override
  void initState() {
    super.initState();
    _filter = widget.current;
    _selectedDistance = _filter.maxDistanceKm;
    _selectedRating = _filter.minRating;
    _selectedPrice = _filter.priceRange;
    _selectedAvailability = _filter.availability;
    _selectedSort = _filter.sortBy;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  String _t(String ar, String en) => widget.isAr ? ar : en;

  void _reset() {
    setState(() {
      _selectedDistance = null;
      _selectedRating = null;
      _selectedPrice = null;
      _selectedAvailability = null;
      _selectedSort = null;
    });
  }

  void _apply() {
    Navigator.of(context).pop(SearchFilter(
      maxDistanceKm: _selectedDistance,
      minRating: _selectedRating,
      priceRange: _selectedPrice,
      availability: _selectedAvailability,
      sortBy: _selectedSort,
      category: _filter.category, // pass through any category set upstream
    ));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;

    return GlassContainer(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      color: isDark ? AppColors.surfaceDark : Colors.white,
      opacity: isDark ? 0.92 : 0.96,
      enableBlur: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: screenHeight * 0.88),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHandle(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(isDark),
                    const SizedBox(height: 20),
                    _buildSection(
                      icon: Icons.location_on_outlined,
                      title: _t('المسافة', 'Distance'),
                      child: _buildDistanceChips(),
                    ),
                    const SizedBox(height: 20),
                    _buildSection(
                      icon: Icons.attach_money_rounded,
                      title: _t('نطاق السعر', 'Price Range'),
                      child: _buildPriceChips(),
                    ),
                    const SizedBox(height: 20),
                    _buildSection(
                      icon: Icons.star_outline_rounded,
                      title: _t('التقييم', 'Rating'),
                      child: _buildRatingChips(),
                    ),
                    const SizedBox(height: 20),
                    _buildSection(
                      icon: Icons.schedule_rounded,
                      title: _t('التوفر', 'Availability'),
                      child: _buildAvailabilityChips(),
                    ),
                    const SizedBox(height: 20),
                    _buildSection(
                      icon: Icons.sort_rounded,
                      title: _t('الترتيب حسب', 'Sort By'),
                      child: _buildSortChips(),
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
            _buildActions(isDark),
          ],
        ),
      ),
    );
  }

  // ── Drag handle ──────────────────────────────────────────────────────────

  Widget _buildHandle() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 12, bottom: 8),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader(bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.tune_rounded, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _t('تصفية النتائج', 'Filter Results'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Text(
                _t('اضبط معايير البحث', 'Adjust search criteria'),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Section wrapper ──────────────────────────────────────────────────────

  Widget _buildSection({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }

  // ── Distance chips ───────────────────────────────────────────────────────

  Widget _buildDistanceChips() {
    final options = [
      (5.0, _t('5 كم', '5 km')),
      (10.0, _t('10 كم', '10 km')),
      (20.0, _t('20 كم', '20 km')),
      (null, _t('الكل', 'All')),
    ];
    return _ChipRow(
      options: options
          .map((o) => _ChipOption(label: o.$2, value: o.$1))
          .toList(),
      selected: _selectedDistance,
      onSelected: (v) => setState(() => _selectedDistance = v),
    );
  }

  // ── Price chips ──────────────────────────────────────────────────────────

  Widget _buildPriceChips() {
    final options = [
      (null, _t('الكل', 'All')),
      ('free', _t('مجاني', 'Free')),
      ('0-5000', '0 – 5,000 SDG'),
      ('5000-20000', '5,000 – 20,000 SDG'),
      ('20000+', _t('+20,000 SDG', '+20,000 SDG')),
    ];
    return _ChipRow(
      options: options
          .map((o) => _ChipOption<String?>(label: o.$2, value: o.$1))
          .toList(),
      selected: _selectedPrice,
      onSelected: (v) => setState(() => _selectedPrice = v),
    );
  }

  // ── Rating chips ─────────────────────────────────────────────────────────

  Widget _buildRatingChips() {
    final options = [
      (null, _t('الكل', 'All')),
      (3.0, _t('3⭐ فأكثر', '3⭐+')),
      (4.0, _t('4⭐ فأكثر', '4⭐+')),
    ];
    return _ChipRow(
      options: options
          .map((o) => _ChipOption<double?>(label: o.$2, value: o.$1))
          .toList(),
      selected: _selectedRating,
      onSelected: (v) => setState(() => _selectedRating = v),
    );
  }

  // ── Availability chips ───────────────────────────────────────────────────

  Widget _buildAvailabilityChips() {
    final options = [
      (null, _t('الكل', 'All')),
      ('now', _t('متوفر الآن', 'Available Now')),
      ('today', _t('اليوم', 'Today')),
      ('48h', _t('48 ساعة', '48 Hours')),
    ];
    return _ChipRow(
      options: options
          .map((o) => _ChipOption<String?>(label: o.$2, value: o.$1))
          .toList(),
      selected: _selectedAvailability,
      onSelected: (v) => setState(() => _selectedAvailability = v),
    );
  }

  // ── Sort chips ───────────────────────────────────────────────────────────

  Widget _buildSortChips() {
    final options = [
      (null, _t('افتراضي', 'Default')),
      ('nearest', _t('الأقرب', 'Nearest')),
      ('rating', _t('الأعلى تقييماً', 'Top Rated')),
      ('newest', _t('الأحدث', 'Newest')),
      ('cheapest', _t('الأرخص', 'Cheapest')),
    ];
    return _ChipRow(
      options: options
          .map((o) => _ChipOption<String?>(label: o.$2, value: o.$1))
          .toList(),
      selected: _selectedSort,
      onSelected: (v) => setState(() => _selectedSort = v),
    );
  }

  // ── Action buttons ───────────────────────────────────────────────────────

  Widget _buildActions(bool isDark) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    // Check if any filter is active
    final anyActive = _selectedDistance != null ||
        _selectedRating != null ||
        _selectedPrice != null ||
        _selectedAvailability != null ||
        _selectedSort != null;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottomPadding),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceDark.withValues(alpha: 0.9)
            : Colors.white.withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
      ),
      child: Row(
        children: [
          // Reset button
          Expanded(
            flex: 2,
            child: OutlinedButton.icon(
              onPressed: anyActive ? _reset : null,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(_t('إعادة تعيين', 'Reset')),
              style: OutlinedButton.styleFrom(
                foregroundColor:
                    anyActive ? AppColors.primary : Colors.grey[400],
                side: BorderSide(
                  color: anyActive
                      ? AppColors.primary.withValues(alpha: 0.5)
                      : Colors.grey.withValues(alpha: 0.3),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Apply button
          Expanded(
            flex: 3,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _apply,
                icon: const Icon(Icons.check_rounded, size: 18),
                label: Text(
                  _t('تطبيق الفلتر', 'Apply Filter'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Generic chip row
// ─────────────────────────────────────────────────────────────────────────────

class _ChipOption<T> {
  final String label;
  final T value;
  const _ChipOption({required this.label, required this.value});
}

class _ChipRow<T> extends StatelessWidget {
  final List<_ChipOption<T>> options;
  final T selected;
  final ValueChanged<T> onSelected;

  const _ChipRow({
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final isSelected = opt.value == selected;
        return _FilterChip(
          label: opt.label,
          isSelected: isSelected,
          onTap: () => onSelected(opt.value),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual animated chip
// ─────────────────────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: isSelected
            ? const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isSelected
            ? null
            : (isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.grey.withValues(alpha: 0.08)),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected
              ? AppColors.primaryLight
              : (isDark
                  ? Colors.white.withValues(alpha: 0.15)
                  : Colors.grey.withValues(alpha: 0.25)),
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
