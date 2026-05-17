// CRITICAL FIX 1: AdService Singleton + Improved Category Validation
// File: lib/services/firestore/ad_service.dart

// Add this at the top of the file after imports:

class AdService {
  static final AdService _instance = AdService._internal();
  
  factory AdService() {
    return _instance;
  }
  
  AdService._internal();
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // ... rest of class remains the same ...
  
  // ADD THIS NEW METHOD for category validation:
  
  /// Validate if a category string is valid
  static bool isValidCategory(String category) {
    if (category == 'all') return true;
    
    // Try to match against PostCategoryGroup names
    for (final group in PostCategoryGroup.values) {
      if ('PostCategoryGroup.${group.name}' == category) {
        return true;
      }
    }
    return false;
  }
  
  /// Sanitize category - returns 'all' if invalid
  static String sanitizeCategory(String? category) {
    if (category == null || category.isEmpty) return 'all';
    if (isValidCategory(category)) return category;
    
    debugPrint('⚠️ Invalid ad category: $category - falling back to "all"');
    return 'all';
  }
  
  // Update getTargetedAd to validate:
  Future<AdModel?> getTargetedAd(UserModel currentUser, {
    AdPlacement placement = AdPlacement.homeBanner,
    String? targetCategory,
  }) async {
    try {
      // VALIDATE TARGET CATEGORY
      final validatedCategory = sanitizeCategory(targetCategory);
      
      final now = Timestamp.now();
      
      // ... rest of method remains the same but use validatedCategory ...
```

## **CRITICAL FIX 2: Remove Double Click Recording**

```dart
// File: lib/views/home/ad_details_screen.dart
// Problem: recordClick is called in two places (feed + details)
// Solution: Only record in ad_details_screen, not in feed

// BEFORE (posts_feed_screen.dart, line 241-249):
if (index == 0 && _currentAd != null && _searchQuery.isEmpty) {
    return AdWidget(
      ad: _currentAd!,
      onTap: () {
        _adService.recordClick(_currentAd!.id);  // ← REMOVE THIS
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AdDetailsScreen(ad: _currentAd!)),
        );
      },
    );
}

// AFTER - Just navigate:
if (index == 0 && _currentAd != null && _searchQuery.isEmpty) {
    return AdWidget(
      ad: _currentAd!,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AdDetailsScreen(ad: _currentAd!)),
        );
      },
    );
}

// VERIFY click is recorded in ad_details_screen.dart, line 276:
onPressed: () async {
    AdService().recordClick(widget.ad.id);  // ✅ Keep this
    // ... rest of action ...
}
```

## **HIGH PRIORITY FIX 3: Add Promoted Badge Visibility**

```dart
// File: lib/views/home/dashboard_screen.dart
// Around line 800+, in _buildFeaturedFreelancers method

// BEFORE:
child: Container(
  width: 140,
  margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
  decoration: BoxDecoration(
    color: isDark ? AppColors.surfaceDark : Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(...),
    boxShadow: [...],
  ),
  child: Column(
    children: [
      // Profile image
      ClipRRect(...),
      // Name, rating, etc.
    ],
  ),
),

// AFTER - Add promoted badge:
child: Container(
  width: 140,
  margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
  decoration: BoxDecoration(
    color: isDark ? AppColors.surfaceDark : Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: _promotedUsers.any((p) => p.userId == user.id)
          ? AppColors.primary  // Gold border for promoted
          : (isDark ? AppColors.borderDark : const Color(0xFFE8ECF0)),
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  ),
  child: Stack(
    children: [
      Column(
        children: [
          // Profile image (existing code)
          ClipRRect(...),
          // Name, rating, etc. (existing code)
        ],
      ),
      // NEW: Promoted badge in corner
      if (_promotedUsers.any((p) => p.userId == user.id))
        Positioned(
          top: 4,
          right: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 4,
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star, size: 12, color: Colors.white),
                SizedBox(width: 2),
                Text(
                  'متميز',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
    ],
  ),
),
```

## **HIGH PRIORITY FIX 4: Sticky Action Button on Ad Details**

```dart
// File: lib/views/home/ad_details_screen.dart
// RESTRUCTURE the Scaffold body layout

// BEFORE (lines 48-308):
return Scaffold(
  appBar: AppBar(...),
  extendBodyBehindAppBar: true,
  body: SafeArea(
    top: false,
    child: SingleChildScrollView(
      child: Column(
        children: [
          // Image
          // Content
          // Action Button (scrolls away ❌)
        ],
      ),
    ),
  ),
);

// AFTER - Use Stack with positioned button:
return Scaffold(
  appBar: AppBar(...),
  extendBodyBehindAppBar: true,
  body: Stack(
    children: [
      // Scrollable content
      SafeArea(
        top: false,
        bottom: false,  // Leave space for button
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // All existing content EXCEPT action button
              // ... Image section ...
              // ... Content section ...
              // ... BUT REMOVE the SizedBox height 56 action button ...
              
              // Add extra padding at bottom for sticky button
              SizedBox(height: 80),
            ],
          ),
        ),
      ),
      
      // Sticky Action Button at bottom
      Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border(
              top: BorderSide(
                color: AppColors.border.withValues(alpha: 0.1),
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            12 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SafeArea(
            top: false,
            child: widget.ad.actionUrl != null && widget.ad.actionUrl!.isNotEmpty
                ? SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                      onPressed: () async {
                        AdService().recordClick(widget.ad.id);
                        final uri = Uri.tryParse(widget.ad.actionUrl!);
                        if (uri != null) {
                          try {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          } catch (_) {}
                        }
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'زيارة الرابط',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.open_in_new),
                        ],
                      ),
                    ),
                  )
                : SizedBox.shrink(),
          ),
        ),
      ),
    ],
  ),
);
```

## **MEDIUM PRIORITY FIX 5: Debounce Infinite Scroll**

```dart
// File: lib/views/posts/posts_feed_screen.dart
// Add debouncing to prevent double-fetching

// Add this at the top of _PostsFeedScreenState class:
Timer? _scrollDebounceTimer;

// Update dispose:
@override
void dispose() {
  _heartbeatTimer?.cancel();
  _scrollDebounceTimer?.cancel();  // ← ADD THIS
  _scrollController.dispose();
  _searchController.dispose();
  super.dispose();
}

// Update scroll listener initialization:
_scrollController.addListener(() {
  if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) {
    // DEBOUNCE: Only call once per 500ms
    _scrollDebounceTimer?.cancel();
    _scrollDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      context.read<PostsProvider>().fetchMorePosts();
    });
  }
});
```

## **MEDIUM PRIORITY FIX 6: Improve Ad Frequency Caching**

```dart
// File: lib/services/firestore/ad_service.dart
// Use persistent SharedPreferences instead of in-memory only

Future<void> recordImpression(String adId) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final viewedAds = prefs.getStringList('viewed_ads') ?? [];
    
    // Add timestamp to prevent same-day repetition
    final key = '${adId}_${DateTime.now().day}';
    if (viewedAds.contains(key)) return;
    
    viewedAds.add(key);
    // Keep only last 100 entries
    if (viewedAds.length > 100) {
      viewedAds.removeRange(0, viewedAds.length - 100);
    }
    await prefs.setStringList('viewed_ads', viewedAds);

    await _firestore.collection('ads').doc(adId).update({
      'impressions': FieldValue.increment(1),
    });
  } catch (e) {
    debugPrint('Error recording impression: $e');
  }
}

// Same pattern for recordClick
Future<void> recordClick(String adId) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final clickedAds = prefs.getStringList('clicked_ads') ?? [];
    
    final key = '${adId}_${DateTime.now().day}';
    if (clickedAds.contains(key)) return;
    
    clickedAds.add(key);
    if (clickedAds.length > 100) {
      clickedAds.removeRange(0, clickedAds.length - 100);
    }
    await prefs.setStringList('clicked_ads', clickedAds);

    await _firestore.collection('ads').doc(adId).update({
      'clicks': FieldValue.increment(1),
    });
  } catch (e) {
    debugPrint('Error recording click: $e');
  }
}
```

---

## IMPLEMENTATION PRIORITY

**Week 1 (Critical):**
1. Fix AdService singleton pattern
2. Add category validation
3. Remove double click recording
4. Add promoted badge visibility

**Week 2 (High Impact):**
5. Implement sticky action button
6. Add infinite scroll debounce
7. Improve ad frequency caching

**Week 3 (Medium):**
8. Add image zoom feature
9. Implement priority system for promotions
10. Add expiration cleanup job

