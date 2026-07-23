import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/constants/app_colors.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/ai_guide_service.dart';
import '../../services/osrm_service.dart';
import '../../models/filter_model.dart';
import '../profile/profile_screen.dart';
import '../../core/utils/job_titles_utils.dart';
import '../../widgets/common/premium_glass_card.dart';
import '../../widgets/common/premium_button.dart';
import '../../widgets/common/filter_bottom_sheet.dart';
import '../../widgets/common/pulsing_marker.dart';
import 'package:sudan_free/l10n/generated/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../utils/animation_utils.dart';
import 'package:sudan_free/utils/app_haptics.dart';

class CachedTileProvider extends TileProvider {
  CachedTileProvider();

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    return CachedNetworkImageProvider(
      getTileUrl(coordinates, options),
      headers: const {
        'User-Agent': 'com.sudan.free',
      },
      errorListener: (err) {
        debugPrint('Tile Network Error: $err');
      },
    );
  }
}

class MapExplorerScreen extends StatefulWidget {
  final UserModel? targetUser;
  const MapExplorerScreen({super.key, this.targetUser});

  @override
  State<MapExplorerScreen> createState() => _MapExplorerScreenState();
}

class _MapExplorerScreenState extends State<MapExplorerScreen>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  List<UserModel> _allMapUsers = [];
  List<UserModel> _filteredUsers = [];
  bool _isLoading = true;
  bool _isSearching = false;
  String _searchQuery = '';
  RouteData? _currentRoute;
  bool _isLoadingRoute = false;

  SearchFilter _currentFilter = const SearchFilter();
  bool _showOnlyAvailable = false;

  // حدود السودان التقريبية (وسعناها قليلاً لتجنب الأخطاء)
  final LatLngBounds _sudanBounds = LatLngBounds(
    const LatLng(8.0, 21.0),
    const LatLng(23.0, 39.0),
  );

  final LatLng _defaultCenter =
      const LatLng(15.5007, 32.5599); // الخرطوم كموقع افتراضي

  Timer? _debounceTimer;
  Position? _currentUserPosition;
  StreamSubscription<Position>? _positionStreamSubscription;

  bool _isValidSudanCoordinate(double? lat, double? lng) {
    if (lat == null || lng == null) return false;
    return lat >= 8.0 && lat <= 23.0 && lng >= 21.0 && lng <= 39.0;
  }

  @override
  void initState() {
    super.initState();
    if (widget.targetUser != null) {
      // If a specific target user is provided, only show this user
      // Check privacy setting
      final user = widget.targetUser!;
      double? lat = user.latitude;
      double? lng = user.longitude;

      if (lat != null && lng != null) {
        if (user.showOnMap != true) {
          // Add a random offset for privacy (approx 2-3km)
          // 0.02 degrees is approx 2km
          lat += (DateTime.now().millisecond % 4 - 2) * 0.01;
          lng += (DateTime.now().microsecond % 4 - 2) * 0.01;
          // Set a flag to indicate it's approximate (we can use a custom property or just standard)
        }

        // Ensure it's valid
        if (_isValidSudanCoordinate(lat, lng)) {
          // create a copy of the user with modified coords
          final displayUser = user.copyWith(latitude: lat, longitude: lng);
          _allMapUsers = [displayUser];
          _filteredUsers = [displayUser];
          _isLoading = false;
        }
      } else {
        _isLoading = false;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (lat != null && lng != null) {
          _animatedMapMove(LatLng(lat, lng), 14.5);
        }

        if (user.showOnMap != true) {
          final scaffoldMessenger = ScaffoldMessenger.of(context);
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(
                context.read<LocaleProvider>().isArabic
                    ? 'الموقع تقريبي لحماية خصوصية المستخدم'
                    : 'Location is approximate to protect user privacy',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      });
    } else {
      _fetchUsersInBounds(_sudanBounds);

      // تحريك الخريطة لموقع المستخدم الفعلي بعد بناء الواجهة
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _locateUser();

        // Using dynamic AI Guide instead of hardcoded MicroTip
        AiGuideService.showPageGuide(
          context,
          'الخريطة والمتاجر',
          context.read<AuthProvider>().user?.name ?? 'عزيزي',
        );
      });
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  // الحصول على موقع المستخدم الحالي وتحريك الكاميرا إليه
  Future<void> _locateUser() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    try {
      // Try to get last known position first for instant response
      Position? position = await Geolocator.getLastKnownPosition();
      if (position != null) {
        if (mounted) setState(() => _currentUserPosition = position);
        _animatedMapMove(LatLng(position.latitude, position.longitude), 14.5);
      }

      // Start listening to location updates
      _positionStreamSubscription?.cancel();
      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Update every 10 meters
        ),
      ).listen((Position pos) {
        if (mounted) {
          setState(() => _currentUserPosition = pos);
        }
      });

      // Then get current with high accuracy for precise location
      position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      ));

      if (mounted) setState(() => _currentUserPosition = position);

      // التوجه إلى موقع المستخدم الفعلي بزووم قريب
      _animatedMapMove(LatLng(position.latitude, position.longitude), 15.5);
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  // حركة سينمائية ناعمة للكاميرا
  void _animatedMapMove(LatLng destLocation, double destZoom) {
    if (!mounted) return;

    final latTween = Tween<double>(
        begin: _mapController.camera.center.latitude,
        end: destLocation.latitude);
    final lngTween = Tween<double>(
        begin: _mapController.camera.center.longitude,
        end: destLocation.longitude);
    final zoomTween =
        Tween<double>(begin: _mapController.camera.zoom, end: destZoom);

    final controller = AnimationController(
        duration: const Duration(milliseconds: 1200), vsync: this);

    final Animation<double> animation =
        CurvedAnimation(parent: controller, curve: Curves.easeInOutCubic);

    controller.addListener(() {
      _mapController.move(
          LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
          zoomTween.evaluate(animation));
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    controller.forward();
  }

  Future<void> _fetchUsersInBounds(LatLngBounds bounds) async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final users = await FirestoreService().getUsersInMapBounds(
        bounds.south - 0.1,
        bounds.north + 0.1,
        bounds.west - 0.1,
        bounds.east + 0.1,
      );
      if (mounted) {
        setState(() {
          final seen = <String>{};
          _allMapUsers = users.where((user) => seen.add(user.id)).toList();
          _applyFilters(setStateOnly: false);
          _rebuildMarkerCache();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching map users: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onMapPositionChanged(MapPosition position, bool hasGesture) {
    if (!hasGesture) return;
    if (position.bounds == null) return;

    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      if (_mapController.camera.zoom > 5.5) {
        _fetchUsersInBounds(position.bounds!);
      }
    });
  }

  void _applyFilters({bool setStateOnly = true}) {
    final filtered = _allMapUsers.where((user) {
      if (_currentFilter.category != null) {
        if (user.shopCategory?.name != _currentFilter.category && user.jobTitle != _currentFilter.category) {
            return false;
        }
      }
      if (_currentFilter.minRating != null && user.rating < _currentFilter.minRating!) {
        return false;
      }
      if (_currentFilter.availability != null) {
         if (_currentFilter.availability == 'now' && !_getUserIsActive(user)) return false;
      }
      if (_currentFilter.maxDistanceKm != null && _currentUserPosition != null && user.latitude != null && user.longitude != null) {
        final distance = Geolocator.distanceBetween(
            _currentUserPosition!.latitude, _currentUserPosition!.longitude,
            user.latitude!, user.longitude!);
        if (distance / 1000 > _currentFilter.maxDistanceKm!) return false;
      }
      if (_showOnlyAvailable && !_getUserIsActive(user)) {
        return false;
      }
      return true;
    }).toList();

    if (setStateOnly) {
      setState(() {
        _filteredUsers = filtered;
        _rebuildMarkerCache();
      });
    } else {
      _filteredUsers = filtered;
    }
  }

  // Pre-computed valid markers list for performance
  List<UserModel> _validMarkerUsers = [];

  void _rebuildMarkerCache() {
    _validMarkerUsers = _filteredUsers
        .where((user) => _isValidSudanCoordinate(user.latitude, user.longitude))
        .where((user) => widget.targetUser != null || user.showOnMap == true)
        .toList();
  }

  // ترجمة المسمى الوظيفي إذا كان من قائمة النظام، أو إرجاعه كما هو إذا كان مخصصاً
  String _getTranslatedSkill(String skill, bool isAr) {
    return JobTitlesUtils.getLocalizedTitle(
        skill, AppLocalizations.of(context)!.en);
  }

  // تحديد المهنة أو تصنيف المتجر - المسمى الوظيفي الفعلي فقط
  String? _getUserProfession(UserModel user, bool isAr) {
    if (user.isShop) {
      final category =
          user.getShopCategoryName(AppLocalizations.of(context)!.en);
      if (category.isNotEmpty) return category;
      return null;
    }
    // حرفي / تقني / خاص - المسمى الوظيفي الحقيقي فقط
    if (user.jobTitle != null && user.jobTitle!.isNotEmpty) {
      return JobTitlesUtils.getLocalizedTitle(
          user.jobTitle!, AppLocalizations.of(context)!.en);
    }
    if (user.skills.isNotEmpty) {
      return _getTranslatedSkill(user.skills.first,
          isAr); // أخذ المسمى الذي اختاره عند التسجيل وترجمته
    }
    return null;
  }

  // تحديد حالة التوفر أو الفتح/الإغلاق
  bool _getUserIsActive(UserModel user) {
    if (user.isShop) return user.isShopCurrentlyOpen;
    return user.isAvailable;
  }

  String _getUserStatusText(UserModel user, bool isAr, bool isActive) {
    if (user.isShop) {
      return isActive
          ? (AppLocalizations.of(context)!.openNow)
          : (AppLocalizations.of(context)!.closedNow);
    }
    return isActive
        ? (AppLocalizations.of(context)!.available)
        : (AppLocalizations.of(context)!.unavailable);
  }

  void _showUserPopup(UserModel user) {
    final isAr = context.read<LocaleProvider>().locale.languageCode == 'ar';
    final profession = _getUserProfession(user, isAr);
    final isActive = _getUserIsActive(user);
    final statusText = _getUserStatusText(user, isAr, isActive);
    final statusColor = isActive ? Colors.green : Colors.red;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => PremiumGlassCard(
        padding: const EdgeInsets.all(24),
        blur: 20,
        opacity: Theme.of(context).brightness == Brightness.dark ? 0.7 : 0.85,
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: true,
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Grab Handle (مؤشر السحب)
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              
              // Compact Layout: Header Block
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // صورة المستخدم
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 1.5),
                    ),
                    child: ClipOval(
                      child: user.profileImageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: user.profileImageUrl!,
                              fit: BoxFit.cover,
                              memCacheWidth: 120,
                              placeholder: (_, __) => Container(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                child: Icon(
                                    user.isShop ? Icons.store : Icons.person,
                                    size: 30,
                                    color: AppColors.primary),
                              ),
                              errorWidget: (_, __, ___) => Icon(
                                  user.isShop ? Icons.store : Icons.person,
                                  size: 30,
                                  color: AppColors.primary),
                            )
                          : Icon(user.isShop ? Icons.store : Icons.person,
                              size: 30, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // الاسم وحالة العمل
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                user.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 18),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: statusColor,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    statusText,
                                    style: TextStyle(
                                      color: statusColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (profession != null) ...[
                          const SizedBox(height: 2),
                          // المسمى الوظيفي
                          Text(
                            profession,
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 4),
                        // التقييم
                        Row(
                          children: [
                            Icon(Icons.star_rounded,
                                size: 16, color: Colors.amber[600]),
                            const SizedBox(width: 2),
                            Text(
                              user.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              ' (${user.completedJobs} ${AppLocalizations.of(context)!.jobs1})',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Quick Action Icons: Location and Work Hours in one line
              if ((user.state != null && user.state!.isNotEmpty) ||
                  (user.locality != null && user.locality!.isNotEmpty) ||
                  (user.openingHours != null && user.openingHours!.isNotEmpty))
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      if ((user.state != null && user.state!.isNotEmpty) ||
                          (user.locality != null && user.locality!.isNotEmpty)) ...[
                        Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            [user.state, user.locality]
                                .where((e) => e != null && e.isNotEmpty)
                                .join(' - '),
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (user.openingHours != null && user.openingHours!.isNotEmpty) ...[
                        Icon(Icons.access_time_outlined, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '${user.openingHours} - ${user.closingHours ?? ''}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

              // Bio
              if (user.bio != null && user.bio!.isNotEmpty) ...[
                Text(
                  user.bio!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey[700], height: 1.3),
                ),
                const SizedBox(height: 8),
              ],

              // Skills / Tags
              if (user.skills.isNotEmpty) ...[
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: user.skills.take(3).map((skill) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _getTranslatedSkill(skill, isAr),
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w600),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ] else ...[
                const SizedBox(height: 8),
              ],

              // Inline Actions: Buttons side by side
              Row(
                children: [
                  if (_currentUserPosition != null && user.latitude != null && user.longitude != null) ...[
                    Expanded(
                      child: PremiumButton(
                        onPressed: () => _calculateAndShowRoute(user),
                        label: isAr ? 'الطريق' : 'Route',
                        icon: Icons.directions_outlined,
                        isPrimary: false,
                        isLoading: _isLoadingRoute,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: PremiumButton(
                      onPressed: () {
                        if (context.mounted) Navigator.pop(context);
                        Navigator.push(
                          context,
                          AnimationUtils.createPremiumRoute(ProfileScreen(userId: user.id)),
                        );
                      },
                      label: isAr ? 'الملف' : 'Profile',
                      icon: Icons.person_outline,
                      isPrimary: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _calculateAndShowRoute(UserModel user) async {
    if (context.mounted) Navigator.pop(context);
    if (_currentUserPosition == null || user.latitude == null || user.longitude == null) return;
    
    setState(() => _isLoadingRoute = true);
    
    final start = LatLng(_currentUserPosition!.latitude, _currentUserPosition!.longitude);
    final end = LatLng(user.latitude!, user.longitude!);
    
    final routeData = await OSRMService.getRoute(start, end);
    
    if (mounted) {
      setState(() {
        _isLoadingRoute = false;
        if (routeData != null) {
          _currentRoute = routeData;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.read<LocaleProvider>().isArabic ? 'حدث خطأ أثناء جلب المسار' : 'Failed to fetch route'),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
    }
  }

  // بناء شريط البحث
  Widget _buildSearchBar(bool isAr) {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: PremiumGlassCard(
                    blur: 12,
                    opacity: Theme.of(context).brightness == Brightness.dark
                        ? 0.6
                        : 0.75,
                    borderRadius: BorderRadius.circular(14),
                    border: false,
                    padding: EdgeInsets.zero,
                    child: _currentRoute != null 
                        ? Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.directions_car, color: AppColors.primary, size: 22),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${_currentRoute!.distanceKm.toStringAsFixed(1)} ${isAr ? 'كم' : 'km'}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                  ],
                                ),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _currentRoute = null;
                                    });
                                  },
                                  child: Icon(Icons.close, color: Colors.red.shade300, size: 22),
                                ),
                              ],
                            ),
                          )
                        : TextField(
                            controller: _searchController,
                            onChanged: (val) {
                              setState(() {
                                _searchQuery = val.toLowerCase();
                                _isSearching = _searchQuery.isNotEmpty;
                              });
                            },
                            decoration: InputDecoration(
                              hintText: AppLocalizations.of(context)!
                                  .searchShopsOrFreelancers,
                              prefixIcon:
                                  const Icon(Icons.search, color: AppColors.primary),
                              suffixIcon: _isSearching
                                  ? IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {
                                          _searchQuery = '';
                                          _isSearching = false;
                                        });
                                        FocusScope.of(context).unfocus();
                                      })
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 15),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 10),
                // Available Only Toggle
                GestureDetector(
                  onTap: () {
                    AppHaptics.lightImpact();
                    setState(() {
                      _showOnlyAvailable = !_showOnlyAvailable;
                      _applyFilters();
                    });
                  },
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: PremiumGlassCard(
                      blur: 12,
                      opacity: _showOnlyAvailable
                          ? 0.85
                          : (Theme.of(context).brightness == Brightness.dark
                              ? 0.6
                              : 0.75),
                      color: _showOnlyAvailable ? AppColors.primary : null,
                      borderRadius: BorderRadius.circular(14),
                      border: false,
                      padding: EdgeInsets.zero,
                      child: Icon(
                      Icons.bolt_rounded,
                      color:
                          _showOnlyAvailable ? Colors.white : AppColors.primary,
                      size: 24,
                    ),
                    ),
                  ),
                ).animate().fade().scale(),
              ],
            ),

            // قائمة النتائج
            if (_isSearching)
              Container(
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 10)
                  ],
                ),
                constraints: const BoxConstraints(maxHeight: 280),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: ListView(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    children: _allMapUsers
                        .where(
                            (u) => u.name.toLowerCase().contains(_searchQuery))
                        .map((user) {
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: user.profileImageUrl != null
                              ? NetworkImage(user.profileImageUrl!)
                              : null,
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.1),
                          child: user.profileImageUrl == null
                              ? Icon(
                                  user.role == UserRole.shop
                                      ? Icons.store
                                      : Icons.person,
                                  color: AppColors.primary)
                              : null,
                        ),
                        title: Text(user.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          user.jobTitle != null && user.jobTitle!.isNotEmpty
                              ? JobTitlesUtils.getLocalizedTitle(user.jobTitle!,
                                  AppLocalizations.of(context)!.en)
                              : (user.role == UserRole.shop
                                  ? (AppLocalizations.of(context)!.shop)
                                  : (AppLocalizations.of(context)!.freelancer)),
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        onTap: () {
                          AppHaptics.lightImpact();
                          FocusScope.of(context).unfocus();
                          setState(() {
                            _searchQuery = '';
                            _isSearching = false;
                            _searchController.clear();
                          });
                          if (user.latitude != null && user.longitude != null) {
                            // الذهاب فوراً لمكان الشخص في الخريطة وفتح بطاقته
                            _animatedMapMove(
                                LatLng(user.latitude!, user.longitude!), 16.0);
                            Future.delayed(const Duration(milliseconds: 1000),
                                () {
                              _showUserPopup(user);
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                ),
              )
          ],
        ),
      ).animate().slideY(begin: -0.5, curve: Curves.easeOut).fade(),
    );
  }

  void _showFilterSheet() async {
    final filter = await FilterBottomSheet.show(
      context,
      current: _currentFilter,
      isAr: context.read<LocaleProvider>().isArabic,
    );
    if (filter != null) {
      setState(() {
        _currentFilter = filter;
        _applyFilters();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.read<LocaleProvider>().locale.languageCode == 'ar';

    return Scaffold(
      extendBodyBehindAppBar:
          true, // يجعل التطبيق يغطي الشاشة بالكامل تحت الـ AppBar
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(
            color: Colors.white), // لون الأزرار أبيض ليناسب الستايل الداكن
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8, left: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.filter_list, color: Colors.white),
              onPressed: () {
                AppHaptics.lightImpact();
                _showFilterSheet();
              },
            ),
          ).animate().fade().scale(),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _defaultCenter,
              initialZoom: 5.5,
              minZoom: 5.0,
              maxZoom: 18.0,
              cameraConstraint: CameraConstraint.contain(bounds: _sudanBounds),
              onPositionChanged: _onMapPositionChanged,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.sudan.free',
                tileProvider: CachedTileProvider(),
                tileBuilder: Theme.of(context).brightness == Brightness.dark
                    ? (context, tileWidget, tile) {
                        return ColorFiltered(
                          colorFilter: const ColorFilter.matrix(<double>[
                            -1,  0,  0, 0, 255,
                             0, -1,  0, 0, 255,
                             0,  0, -1, 0, 255,
                             0,  0,  0, 1,   0,
                          ]),
                          child: tileWidget,
                        );
                      }
                    : null,
              ),
              if (_currentRoute != null)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _currentRoute!.points,
                      color: AppColors.accent,
                      strokeWidth: 5.0,
                    ),
                  ],
                ),
              MarkerClusterLayerWidget(
                options: MarkerClusterLayerOptions(
                  maxClusterRadius: 45,
                  size: const Size(40, 40),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(50),
                  maxZoom: 15,
                  markers: _validMarkerUsers.map((user) {
                    final isShop = user.isShop;
                    final isPrivacyProtected = user.showOnMap != true;
                    final markerColor = isPrivacyProtected
                        ? Colors.yellow
                        : (isShop ? Colors.amber : Colors.cyanAccent);
                    return Marker(
                      key: ValueKey('marker_${user.id}'),
                      point: LatLng(user.latitude!, user.longitude!),
                      width: 70,
                      height: 70,
                      child: RepaintBoundary(
                        child: GestureDetector(
                          onTap: () {
                            AppHaptics.lightImpact();
                            _animatedMapMove(
                                LatLng(user.latitude!, user.longitude!), 16.0);
                            _showUserPopup(user);
                          },
                          child: PulsingMarker(
                            isPulsing: _getUserIsActive(user) && !isPrivacyProtected,
                            pulseColor: markerColor,
                            baseSize: 50,
                            pulseSize: 70,
                            child: Center(
                              child: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: markerColor, width: 2.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: markerColor.withValues(alpha: 0.5),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: user.profileImageUrl != null
                                      ? CachedNetworkImage(
                                          imageUrl: user.profileImageUrl!,
                                          fit: BoxFit.cover,
                                          memCacheWidth: 100,
                                          fadeInDuration:
                                              const Duration(milliseconds: 150),
                                          placeholder: (_, __) => Container(
                                            color: Colors.grey[900],
                                            child: Icon(
                                                isShop ? Icons.store : Icons.work,
                                                color: Colors.white,
                                                size: 22),
                                          ),
                                          errorWidget: (_, __, ___) => Container(
                                            color: Colors.grey[900],
                                            child: Icon(
                                                isShop ? Icons.store : Icons.work,
                                                color: Colors.white,
                                                size: 22),
                                          ),
                                        )
                                      : Container(
                                          color: Colors.grey[900],
                                          child: Icon(
                                              isShop ? Icons.store : Icons.work,
                                              color: Colors.white,
                                              size: 22),
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                  builder: (context, markers) {
                    return Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 5,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          markers.length.toString(),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (_currentUserPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(_currentUserPosition!.latitude,
                          _currentUserPosition!.longitude),
                      width: 44,
                      height: 44,
                      child: PulsingMarker(
                        isPulsing: true,
                        pulseColor: Colors.blue,
                        baseSize: 24,
                        pulseSize: 44,
                        child: Center(
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.blue,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // شريط البحث المخصص
          _buildSearchBar(isAr),

          // معلومات المسار تم دمجها في شريط البحث
          // زر "تحديد موقعي"
          Positioned(
            bottom: 24,
            right: 16,
            child: FloatingActionButton.small(
              heroTag: 'myLocationBtn',
              backgroundColor: Theme.of(context).cardColor,
              onPressed: () {
                AppHaptics.lightImpact();
                _locateUser();
              },
              child: const Icon(Icons.my_location, color: AppColors.primary, size: 20),
            ).animate().scale().fade(),
          ),

          if (_isLoading)
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2)),
                      SizedBox(width: 12),
                      Text('جاري تحميل البيانات...',
                          style: TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),
          if (_isLoadingRoute)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
