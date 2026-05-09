import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/request_model.dart';
import '../../models/offer_model.dart';
import '../../models/user_model.dart';
import '../../models/contact_log_model.dart';
import '../../services/firestore_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/locale_provider.dart';
import '../chat/chat_screen.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/linkable_text.dart';
import '../profile/profile_screen.dart';

class RequestDetailsScreen extends StatefulWidget {
  final RequestModel request;

  const RequestDetailsScreen({super.key, required this.request});

  @override
  State<RequestDetailsScreen> createState() => _RequestDetailsScreenState();
}

class _RequestDetailsScreenState extends State<RequestDetailsScreen> {
  final _offerController = TextEditingController();
  final _priceController = TextEditingController();
  bool _isApplying = false;

  @override
  void dispose() {
    _offerController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _showOfferSheet(BuildContext context, UserModel currentUser, String locale) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(locale == 'ar' ? 'قدم عرضك' : 'Submit your offer', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _offerController,
                      hint: locale == 'ar' ? 'مرحباً، أنا مستعد لتنفيذ طلبك. لدي خبرة سابقة...' : 'Hello, I am ready to fulfill your request. I have previous experience...',
                      maxLines: 4,
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: _priceController,
                      hint: locale == 'ar' ? 'السعر التقديري (اختياري)' : 'Estimated Price (Optional)',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.attach_money,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isApplying ? null : () async {
                          if (_offerController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(locale == 'ar' ? 'الرجاء كتابة تفاصيل العرض' : 'Please write offer details'), backgroundColor: AppColors.warning),
                            );
                            return;
                          }
  
                        setSheetState(() => _isApplying = true);
                        final nav = Navigator.of(context);
                        final messenger = ScaffoldMessenger.of(context);
  
                          try {
                            // Server-side bid limit check
                            final existingCount = await FirestoreService().getUserOfferCount(widget.request.id, currentUser.id);
                            if (existingCount >= 2) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(locale == 'ar' ? 'لقد قدمت الحد الأقصى من العروض (عرضين) على هذا الطلب' : 'You have reached the maximum offers (2)'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                              nav.pop();
                              return;
                            }

                            final offer = OfferModel(
                              id: '',
                              requestId: widget.request.id,
                              providerId: currentUser.id,
                              providerName: currentUser.name,
                              providerRole: currentUser.role.name,
                              providerImageUrl: currentUser.profileImageUrl,
                              providerJobTitle: currentUser.jobTitle ?? currentUser.getShopCategoryName(locale),
                              title: locale == 'ar' ? 'عرض جديد' : 'New Offer',
                              text: _offerController.text.trim(),
                              price: _priceController.text.isNotEmpty ? double.tryParse(_priceController.text) : null,
                              createdAt: DateTime.now(),
                            );
  
                            await FirestoreService().createOffer(offer);
  
                            if (mounted) {
                              _offerController.clear();
                              _priceController.clear();
                              messenger.showSnackBar(
                                SnackBar(content: Text(locale == 'ar' ? 'تم تقديم العرض بنجاح!' : 'Offer submitted successfully!'), backgroundColor: AppColors.success),
                              );
                              nav.pop();
                              // Refresh the page to update bid count
                              setState(() {});
                            }
                          } catch (e) {
                            if (mounted) {
                              messenger.showSnackBar(
                                SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                              );
                            }
                          } finally {
                            if (mounted) setSheetState(() => _isApplying = false);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isApplying 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(locale == 'ar' ? 'إرسال العرض' : 'Submit Offer', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openWhatsApp(String? number) async {
    if (number == null || number.isEmpty) return;
    
    String cleaned = number.replaceAll(RegExp(r'[^\d]'), '');
    
    // Smart Format for Sudan
    if (cleaned.startsWith('0')) {
      // Remove leading zero and add country code
      cleaned = '249${cleaned.substring(1)}';
    } else if (!cleaned.startsWith('249') && cleaned.length == 9) {
      // Add country code if missing (assuming 9 digits standard)
      cleaned = '249$cleaned';
    }
    
    final message = Uri.encodeComponent(
      'مرحباً، أتواصل معك من خلال منصة سودان فري بخصوص طلبك.' 
    );
    final url = 'https://wa.me/$cleaned?text=$message';
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalNonBrowserApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final currentUser = authProvider.user;
    final locale = context.watch<LocaleProvider>().locale.languageCode;
    
    final isMyRequest = currentUser?.id == widget.request.clientId;
    final canApply = currentUser != null && currentUser.role != UserRole.client && !isMyRequest;

    return Scaffold(
      appBar: AppBar(
        title: Text(locale == 'ar' ? 'تفاصيل الطلب' : 'Request Details'),
        actions: [
          if (isMyRequest)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _confirmDelete(context),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Request Header
            Container(
              padding: const EdgeInsets.all(20),
              color: Theme.of(context).cardColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        backgroundImage: widget.request.clientImageUrl != null ? NetworkImage(widget.request.clientImageUrl!) : null,
                        child: widget.request.clientImageUrl == null ? const Icon(Icons.person, color: AppColors.primary) : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.request.clientName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            Text(
                              _formatTimeAgo(widget.request.createdAt, locale),
                              style: TextStyle(color: Colors.grey[600], fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      if (widget.request.category != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            widget.request.category!,
                            style: const TextStyle(color: AppColors.secondary, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  LinkableText(
                    text: widget.request.text,
                    style: const TextStyle(fontSize: 16, height: 1.6),
                  ),
                  // ═══ Attached Images ═══
                  if (widget.request.allImageUrls.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 180,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.request.allImageUrls.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final url = widget.request.allImageUrls[index];
                          return GestureDetector(
                            onTap: () => _showFullImage(context, widget.request.allImageUrls, index),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CachedNetworkImage(
                                imageUrl: url,
                                width: 220,
                                height: 180,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(
                                  width: 220,
                                  height: 180,
                                  color: Colors.grey.withValues(alpha: 0.1),
                                  child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                                ),
                                errorWidget: (_, __, ___) => Container(
                                  width: 220,
                                  height: 180,
                                  color: Colors.grey.withValues(alpha: 0.1),
                                  child: const Icon(Icons.broken_image, color: Colors.grey),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.photo_library_outlined, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          locale == 'ar' 
                              ? '${widget.request.allImageUrls.length} صور مرفقة • اضغط للتكبير' 
                              : '${widget.request.allImageUrls.length} attached • tap to enlarge',
                          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ],
                  if (widget.request.state != null || widget.request.locality != null) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 18, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.request.locality ?? ''} ${widget.request.state != null ? '- ${widget.request.state}' : ''}',
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            
            // Delete Reminder for Client
            if (isMyRequest)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.warning),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.notifications_active_outlined, color: AppColors.warning),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        locale == 'ar' 
                            ? 'يرجى حذف الطلب من أيقونة السلة بالاعلى عند اكتفاءك وتلقي الخدمة المطلوبة.' 
                            : 'Please delete the request from the trash icon above when you are satisfied and received the service.',
                        style: TextStyle(color: AppColors.warning.withValues(alpha: 0.9), fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

            // Provider Submission Button
            if (canApply)
              FutureBuilder<int>(
                future: FirestoreService().getUserOfferCount(widget.request.id, currentUser.id),
                builder: (context, snapshot) {
                  final existingOffers = snapshot.data ?? 0;
                  if (existingOffers >= 2) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(child: Text(
                            locale == 'ar' ? 'لقد قدمت الحد الأقصى من العروض (عرضين) على هذا الطلب' : 'You have reached the maximum offers (2) on this request',
                            style: const TextStyle(color: Colors.orange, fontSize: 13, fontWeight: FontWeight.w600),
                          )),
                        ],
                      ),
                    );
                  }
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    width: double.infinity,
                    child: Column(
                      children: [
                        if (existingOffers == 1)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 18),
                                  const SizedBox(width: 6),
                                  Expanded(child: Text(
                                    locale == 'ar' ? 'هذا آخر عرض يمكنك تقديمه على هذا الطلب' : 'This is your last offer on this request',
                                    style: TextStyle(color: Colors.amber.shade800, fontSize: 12, fontWeight: FontWeight.w600),
                                  )),
                                ],
                              ),
                            ),
                          ),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _showOfferSheet(context, currentUser, locale),
                            icon: const Icon(Icons.local_offer_outlined),
                            label: Text(locale == 'ar' ? 'قدم عرضك' : 'Submit Offer', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

            // List of Offers or Summary Banner
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                locale == 'ar' ? 'العروض المقدمة (${widget.request.offersCount})' : 'Submitted Offers (${widget.request.offersCount})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            
            if (!isMyRequest)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.privacy_tip_outlined, color: AppColors.primary, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        locale == 'ar' 
                            ? 'هذا الطلب عليه ${widget.request.offersCount} عروض حالياً. كن من أوائل المتقدمين!'
                            : 'This request currently has ${widget.request.offersCount} offers. Be among the first to apply!',
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, height: 1.5),
                      ),
                    ),
                  ],
                ),
              )
            else
              StreamBuilder<List<OfferModel>>(
                stream: FirestoreService().getOffers(widget.request.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const LoadingIndicator();
                  }
                  final offers = snapshot.data ?? [];
                  
                  if (offers.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Text(locale == 'ar' ? 'لم يتم تقديم عروض بعد' : 'No offers submitted yet', style: TextStyle(color: Colors.grey[600])),
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: offers.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final offer = offers[index];
                      return _OfferCard(
                        offer: offer, 
                        isMyRequest: isMyRequest,
                        locale: locale,
                        currentUserId: currentUser?.id,
                        currentUserName: currentUser?.name,
                        onContact: () => _openWhatsApp(currentUser?.whatsappNumber ?? currentUser?.phoneNumber),
                      );
                    },
                  );
                },
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final locale = context.read<LocaleProvider>().locale.languageCode;
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(locale == 'ar' ? 'حذف الطلب' : 'Delete Request'),
        content: Text(locale == 'ar' 
            ? 'هل أنت متأكد أنك تريد حذف هذا الطلب؟ لا يمكن التراجع عن هذا الإجراء.' 
            : 'Are you sure you want to delete this request? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(locale == 'ar' ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(locale == 'ar' ? 'حذف' : 'Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await FirestoreService().deleteRequest(widget.request.id);
        if (!mounted) return;
        nav.pop(); // Go back to List
        messenger.showSnackBar(
          SnackBar(content: Text(locale == 'ar' ? 'تم الحذف بنجاح' : 'Deleted Successfully'), backgroundColor: AppColors.success),
        );
      } catch (e) {
        if (!mounted) return;
         messenger.showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
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

  void _showFullImage(BuildContext context, List<String> imageUrls, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullScreenImageViewer(imageUrls: imageUrls, initialIndex: initialIndex),
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  final OfferModel offer;
  final bool isMyRequest;
  final String locale;
  final VoidCallback onContact;
  final String? currentUserId;
  final String? currentUserName;

  const _OfferCard({required this.offer, required this.isMyRequest, required this.locale, required this.onContact, this.currentUserId, this.currentUserName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => _navigateToProfile(context, offer),
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  backgroundImage: offer.providerImageUrl != null ? NetworkImage(offer.providerImageUrl!) : null,
                  child: offer.providerImageUrl == null ? const Icon(Icons.person, color: AppColors.primary, size: 22) : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: GestureDetector(
                            onTap: () => _navigateToProfile(context, offer),
                            child: Text(
                              offer.providerName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        if (offer.providerJobTitle != null && offer.providerJobTitle!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: offer.providerRole == 'shop' ? Colors.amber.withValues(alpha: 0.2) : AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              offer.providerJobTitle!,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: offer.providerRole == 'shop' ? Colors.amber.shade800 : AppColors.primary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (offer.price != null && offer.price! > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${offer.price} SDG',
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: LinkableText(
                  text: offer.text,
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
              ),
              if (isMyRequest)
                Container(
                  margin: const EdgeInsetsDirectional.only(start: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: () => _showContactSheet(context),
                    icon: const Icon(Icons.support_agent, size: 20),
                    color: AppColors.primary,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    padding: EdgeInsets.zero,
                    tooltip: locale == 'ar' ? 'تواصل' : 'Contact',
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
  void _showContactSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                locale == 'ar' ? 'تواصل مع مقدم الخدمة' : 'Contact Provider',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Color(0xFF25D366), child: Icon(Icons.chat, color: Colors.white)),
                title: Text(locale == 'ar' ? 'واتساب' : 'WhatsApp'),
                onTap: () async {
                  Navigator.pop(ctx);
                  try {
                    final provider = await FirestoreService().getUser(offer.providerId);
                    if (provider != null) {
                      if (currentUserId != null && currentUserId != offer.providerId) {
                        try {
                          final log = ContactLogModel(
                            id: '',
                            contacterId: currentUserId!,
                            contacterName: currentUserName ?? '',
                            freelancerId: offer.providerId,
                            freelancerName: offer.providerName,
                            contactType: 'whatsapp',
                            createdAt: DateTime.now(),
                          );
                          await FirestoreService().createContactLog(log);
                        } catch (e) {
                          debugPrint('Error creating contact log: $e');
                        }
                      }
                      _openWhatsApp(provider.whatsappNumber ?? provider.phoneNumber);
                    }
                  } catch (e) {
                    debugPrint('Error getting provider contact details');
                  }
                },
              ),
              ListTile(
                leading: CircleAvatar(backgroundColor: AppColors.primary, child: const Icon(Icons.call, color: Colors.white)),
                title: Text(locale == 'ar' ? 'اتصال مباشر' : 'Direct Call'),
                onTap: () async {
                  Navigator.pop(ctx);
                  try {
                    final provider = await FirestoreService().getUser(offer.providerId);
                    if (provider != null) {
                      final phone = provider.phoneNumber ?? provider.whatsappNumber;
                      if (phone != null && phone.isNotEmpty) {
                        final uri = Uri.parse('tel:$phone');
                        try {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        } catch (_) {}
                      }
                    }
                  } catch (e) {
                    debugPrint('Error calling provider');
                  }
                },
              ),
              ListTile(
                leading: CircleAvatar(backgroundColor: Colors.blue.shade600, child: const Icon(Icons.handshake, color: Colors.white)),
                title: Text(locale == 'ar' ? 'قبول والاتفاق (إنشاء عقد)' : 'Accept & Agree (Create Contract)'),
                onTap: () async {
                  Navigator.pop(ctx);
                  if (currentUserId == null) return;

                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => const Center(child: CircularProgressIndicator()),
                  );

                  // Capture before async gap
                  final chatProvider = context.read<ChatProvider>();
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);

                  try {
                    final provider = await FirestoreService().getUser(offer.providerId);

                    final chat = await chatProvider.getOrCreateChat(
                      currentUserId: currentUserId!,
                      currentUserName: currentUserName ?? '',
                      otherUserId: offer.providerId,
                      otherUserName: offer.providerName,
                      otherUserImageUrl: provider?.profileImageUrl,
                    );

                    navigator.pop(); // Close loading dialog

                    if (chat != null) {
                      navigator.push(
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(chat: chat, autoOpenContractDialog: true),
                        ),
                      );
                    }
                  } catch (e) {
                    navigator.pop(); // Close loading dialog on error
                    messenger.showSnackBar(
                      SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                    );
                  }
                },
              ),
              ListTile(
                leading: CircleAvatar(backgroundColor: Colors.grey.shade600, child: const Icon(Icons.person, color: Colors.white)),
                title: Text(locale == 'ar' ? 'عرض الملف الشخصي' : 'View Profile'),
                onTap: () {
                  Navigator.pop(ctx);
                  _navigateToProfile(context, offer);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openWhatsApp(String? number) async {
    if (number == null || number.isEmpty) return;
    
    String cleaned = number.replaceAll(RegExp(r'[^\d]'), '');
    
    // Smart Format for Sudan
    if (cleaned.startsWith('0')) {
      // Remove leading zero and add country code
      cleaned = '249${cleaned.substring(1)}';
    } else if (!cleaned.startsWith('249') && cleaned.length == 9) {
      // Add country code if missing (assuming 9 digits standard)
      cleaned = '249$cleaned';
    }
    
    final message = Uri.encodeComponent(
      'مرحباً، أتواصل معك من خلال منصة سودان فري بخصوص طلبك.' 
    );
    final url = 'https://wa.me/$cleaned?text=$message';
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalNonBrowserApplication);
    } catch (_) {}
  }

  void _navigateToProfile(BuildContext context, OfferModel offer) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(userId: offer.providerId)));
  }
}

// ═══ Full Screen Image Viewer ═══
class _FullScreenImageViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const _FullScreenImageViewer({required this.imageUrls, required this.initialIndex});

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: widget.imageUrls.length > 1
            ? Text('${_currentIndex + 1} / ${widget.imageUrls.length}', style: const TextStyle(fontSize: 16))
            : null,
        elevation: 0,
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.imageUrls.length,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemBuilder: (context, index) {
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: CachedNetworkImage(
                imageUrl: widget.imageUrls[index],
                fit: BoxFit.contain,
                placeholder: (_, __) => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                errorWidget: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.grey, size: 64),
              ),
            ),
          );
        },
      ),
    );
  }
}
