import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/request_model.dart';
import '../../services/firestore_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../core/constants/app_colors.dart';

import '../../widgets/common/loading_widget.dart';
import 'add_request_screen.dart';
import 'request_details_screen.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  bool _showMyRequestsOnly = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final currentUser = authProvider.user;
    final locale = context.watch<LocaleProvider>().locale.languageCode;
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
      body: StreamBuilder<List<RequestModel>>(
        stream: FirestoreService().getRequests(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: LoadingIndicator());
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

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final request = requests[index];
              return _RequestCard(
                request: request, 
                locale: locale, 
                currentUserId: currentUser?.id,
              );
            },
          );
        },
      ),
      floatingActionButton: currentUser != null
          ? FloatingActionButton.extended(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => AddRequestBottomSheet(user: currentUser),
                );
              },
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                locale == 'ar' ? 'أضف طلبك' : 'Add Request',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              backgroundColor: AppColors.primary,
            )
          : null,
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(locale == 'ar' ? 'تم حذف الطلب بنجاح' : 'Request deleted successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
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
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  backgroundImage: request.clientImageUrl != null ? NetworkImage(request.clientImageUrl!) : null,
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
                    const Icon(Icons.local_offer_outlined, size: 18, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      '${request.offersCount} ${locale == 'ar' ? 'عروض' : 'Offers'}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ],
                ),
                Text(
                  locale == 'ar' ? 'عرض التفاصيل' : 'View Details',
                  style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.bold, fontSize: 13),
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
