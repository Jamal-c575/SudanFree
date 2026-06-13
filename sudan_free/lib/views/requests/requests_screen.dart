import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/request_model.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../core/constants/app_colors.dart';


import 'add_request_screen.dart';
import 'request_details_screen.dart';
import 'package:shimmer/shimmer.dart';
import '../../widgets/common/adaptive_fab_padding.dart';
import '../../widgets/buttons/smart_draggable_fab.dart';
import '../../services/smart_guide_service.dart';
import '../../widgets/common/glass_container.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  bool _showMyRequestsOnly = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      final isClient = user?.role == UserRole.client;
      
      SmartGuideService.showMicroTip(
        context,
        messageAr: isClient
            ? 'اطرح ما تحتاجه هنا، ودع أفضل المتخصصين يتنافسون لخدمتك 🎯'
            : 'فرص عمل جديدة بانتظارك! تصفح طلبات العملاء وقدم عرضك الآن 💼',
        messageEn: isClient
            ? 'Post what you need here and let the best professionals compete 🎯'
            : 'New jobs await! Browse client requests and submit your offer now 💼',
        tipId: 'requests_first_visit',
        icon: Icons.assignment_rounded,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final currentUser = authProvider.user;
    final locale = context.watch<LocaleProvider>().locale.languageCode;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text(locale == 'ar' ? 'الطلبات' : 'Requests'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          if (currentUser != null)
            IconButton(
              icon: Icon(
                _showMyRequestsOnly ? Icons.filter_alt : Icons.filter_alt_outlined,
                color: _showMyRequestsOnly ? AppColors.primary : null,
              ),
              tooltip: locale == 'ar' ? 'طلباتي فقط' : 'My Requests Only',
              onPressed: () {
                setState(() {
                  _showMyRequestsOnly = !_showMyRequestsOnly;
                });
              },
            ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: StreamBuilder<List<RequestModel>>(
              stream: FirestoreService().getRequests(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildRequestsShimmer(isDark);
                }
                if (snapshot.hasError) {
                   return Center(
                     child: Padding(
                       padding: const EdgeInsets.all(32),
                       child: Column(
                         mainAxisAlignment: MainAxisAlignment.center,
                         children: [
                           const Icon(Icons.error_outline, size: 48, color: Colors.red),
                           const SizedBox(height: 16),
                           Text(
                             locale == 'ar' ? 'حدث خطأ في تحميل الطلبات' : 'Error loading requests',
                             style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                           ),
                           const SizedBox(height: 8),
                           Text(
                             '${snapshot.error}',
                             textAlign: TextAlign.center,
                             style: TextStyle(color: Colors.grey[600], fontSize: 12),
                           ),
                           const SizedBox(height: 16),
                           ElevatedButton.icon(
                             onPressed: () => setState(() {}),
                             icon: const Icon(Icons.refresh),
                             label: Text(locale == 'ar' ? 'إعادة المحاولة' : 'Retry'),
                           ),
                         ],
                       ),
                     ),
                   );
                }

                var requests = snapshot.data ?? [];
                
                if (_showMyRequestsOnly && currentUser != null) {
                  requests = requests.where((r) => r.clientId == currentUser.id).toList();
                }

                if (requests.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.assignment_outlined, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.5)),
                        const SizedBox(height: 16),
                        Text(
                          locale == 'ar' ? 'لا توجد طلبات حالياً' : 'No requests available',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 18),
                        ),
                      ],
                    ),
                  );
                }

                // 3. منع تداخل المحتوى مع شريط التنقل
                final bottomInset = MediaQuery.of(context).padding.bottom;
                final navBarMargin = bottomInset > 30 ? bottomInset + 8 : bottomInset + 14;
                final navBarHeight = 62.0;
                final navBarTop = navBarMargin + navBarHeight;

                return ListView.separated(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, navBarTop + 80),
                  physics: const ClampingScrollPhysics(),
                  addRepaintBoundaries: true,
                  addAutomaticKeepAlives: false,
                  itemCount: requests.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final request = requests[index];
                    return RepaintBoundary(
                      child: _RequestCard(
                        request: request,
                        locale: locale,
                        currentUserId: currentUser?.id,
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          // 2. زر إضافة الطلب الذكي والمتحرك
          if (currentUser != null)
            SmartDraggableFab(
              heroTag: 'create_request_fab',
              icon: Icons.add,
              label: locale == 'ar' ? 'أضف طلبك' : 'Add Request',
              locale: locale,
              initialBottom: MediaQuery.of(context).padding.bottom + 82.0, // navBar + safe area
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => AddRequestBottomSheet(user: currentUser),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildRequestsShimmer(bool isDark) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[900] : Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Shimmer.fromColors(
            baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
            highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(radius: 20, backgroundColor: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(width: 100, height: 16, color: Colors.white),
                          const SizedBox(height: 4),
                          Container(width: 60, height: 12, color: Colors.white),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(width: double.infinity, height: 14, color: Colors.white),
                const SizedBox(height: 4),
                Container(width: 250, height: 14, color: Colors.white),
                const SizedBox(height: 16),
                Container(width: 120, height: 14, color: Colors.white),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RequestCard extends StatelessWidget {
  final RequestModel request;
  final String locale;
  final String? currentUserId;

  const _RequestCard({
    required this.request, 
    required this.locale,
    this.currentUserId,
  });

  Future<void> _deleteRequest(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(locale == 'ar' ? 'حذف الطلب' : 'Delete Request'),
        content: Text(locale == 'ar'
            ? 'هل أنت متأكد من حذف هذا الطلب نهائياً؟'
            : 'Are you sure you want to delete this request permanently?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(locale == 'ar' ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(locale == 'ar' ? 'حذف' : 'Delete', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await FirestoreService().deleteRequest(request.id);
        if (context.mounted) {
          final scaffoldMessenger = ScaffoldMessenger.of(context);
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(locale == 'ar' ? 'تم حذف الطلب بنجاح' : 'Request deleted successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          final scaffoldMessenger = ScaffoldMessenger.of(context);
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('${locale == 'ar' ? 'حدث خطأ: ' : 'Error: '}$e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => RequestDetailsScreen(request: request)),
        );
      },
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        blur: 15,
        opacity: Theme.of(context).brightness == Brightness.dark ? 0.3 : 0.7,
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  backgroundImage: request.clientImageUrl != null ? CachedNetworkImageProvider(request.clientImageUrl!) : null,
                  child: request.clientImageUrl == null ? const Icon(Icons.person, color: AppColors.primary) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.clientName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        _formatTimeAgo(request.createdAt, locale),
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (request.category != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      request.category!,
                      style: const TextStyle(color: AppColors.secondary, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                if (currentUserId != null && currentUserId == request.clientId)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                    onPressed: () => _deleteRequest(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              request.text,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, height: 1.4),
            ),
            if (request.state != null || request.locality != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${request.locality ?? ''} ${request.state != null ? '- ${request.state}' : ''}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ],
            if (request.allImageUrls.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.photo_outlined, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    locale == 'ar' 
                        ? '${request.allImageUrls.length} صور مرفقة' 
                        : '${request.allImageUrls.length} photo(s) attached',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.local_offer_outlined, 
                      size: 18, 
                      color: Theme.of(context).brightness == Brightness.dark ? AppColors.primaryLight : AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${request.offersCount} ${locale == 'ar' ? 'عروض' : 'Offers'}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        color: Theme.of(context).brightness == Brightness.dark ? AppColors.primaryLight : AppColors.primary,
                      ),
                    ),
                  ],
                ),
                Text(
                  locale == 'ar' ? 'عرض التفاصيل' : 'View Details',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.blue[300] : Colors.blue[700], 
                    fontWeight: FontWeight.bold, 
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime date, String locale) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 30) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (diff.inDays > 0) {
      return locale == 'ar' ? 'منذ ${diff.inDays} يوم' : '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return locale == 'ar' ? 'منذ ${diff.inHours} ساعة' : '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return locale == 'ar' ? 'منذ ${diff.inMinutes} دقيقة' : '${diff.inMinutes}m ago';
    } else {
      return locale == 'ar' ? 'الآن' : 'Just now';
    }
  }
}
