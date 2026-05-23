import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/app_error_handler.dart';
import '../../providers/auth_provider.dart';
import '../../providers/posts_provider.dart';
import '../../models/post_model.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/mentions/mention_overlay.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/cloudinary_service.dart';

class CreatePostScreen extends StatefulWidget {
  final PostModel? post;
  final bool showInCommunity;
  final bool showInProfile;
  final PostModel? linkedProduct; // منتج مرتبط (من شاشة تفاصيل المنتج)

  const CreatePostScreen({
    super.key,
    this.post,
    this.showInCommunity = true,  // Default: show in community
    this.showInProfile = true,    // Default: show in profile
    this.linkedProduct,           // منتج مرتبط اختياري
  });

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _captionController = TextEditingController();
  final _priceController = TextEditingController(); // New field for shop products
  final List<File> _selectedImages = [];
  PostCategory? _selectedCategory;
  late bool _showInCommunity;
  late bool _showInProfile;
  bool _isPosting = false;
  
  // Mentions
  List<UserModel> _partners = [];
  List<UserModel> _filteredPartners = [];
  bool _showMentions = false;
  final Set<String> _mentionedUserIds = {}; // Use Set to avoid duplicates

  @override
  void initState() {
    super.initState();
    if (widget.post != null) {
      _captionController.text = widget.post!.caption ?? '';
      // عند التعديل: نحافظ على نوع المنشور الأصلي بدون تغيير
      _showInCommunity = widget.post!.showInCommunity;
      _showInProfile = widget.post!.showInProfile;
      if (widget.post!.category != null) {
        try {
          _selectedCategory = PostCategory.values.firstWhere((e) => e.name == widget.post!.category);
        } catch (_) {}
      }
      if (widget.post!.price != null) {
        _priceController.text = widget.post!.price.toString();
      }
    } else {
      _showInCommunity = widget.showInCommunity;
      
      // إذا كان النشر من صفحة الملف الشخصي → معرض أعمال فقط
      if (widget.showInProfile && !widget.showInCommunity) {
        _showInProfile = true;
        _showInCommunity = false;
      } else if (widget.showInCommunity) {
        // إذا كان النشر من المجتمع → مجتمع أساسي، ومعرض الأعمال اختياري (غير مفعل افتراضياً)
        _showInCommunity = true;
        _showInProfile = false; // لا يظهر تلقائياً في المعرض
      } else {
        _showInProfile = widget.showInProfile;
      }
    }

    // Fetch Partners for Mentions
    _fetchPartners();
    
    // Listen for mentions
    _captionController.addListener(_checkForMentions);
  }

  Future<void> _fetchPartners() async {
    final user = context.read<AuthProvider>().user;
    if (user != null && user.partnerIds.isNotEmpty) {
      try {
        final partners = await FirestoreService().getUsersByIds(user.partnerIds);
        if (mounted) {
          setState(() {
            _partners = partners;
          });
        }
      } catch (e) {
        debugPrint('Error fetching partners: $e');
      }
    }
  }

  void _checkForMentions() {
    final text = _captionController.text;
    final selection = _captionController.selection;
    if (selection.baseOffset < 0) return;

    final textBeforeCursor = text.substring(0, selection.baseOffset);
    // Find the word being typed
    final words = textBeforeCursor.split(RegExp(r'[\s\n]+')); // Split by space or newline
    final lastWord = words.isNotEmpty ? words.last : '';

    if (lastWord.startsWith('@')) {
      final query = lastWord.substring(1).toLowerCase(); // Remove @
      setState(() {
        _filteredPartners = _partners.where((u) => u.name.toLowerCase().contains(query)).toList();
        _showMentions = _filteredPartners.isNotEmpty;
      });
    } else {
      if (_showMentions) {
        setState(() => _showMentions = false);
      }
    }
  }

  void _addMention(UserModel partner) {
    final text = _captionController.text;
    final selection = _captionController.selection;
    final textBeforeCursor = text.substring(0, selection.baseOffset);
    
    final words = textBeforeCursor.split(RegExp(r'[\s\n]+'));
    final lastWord = words.last; // This is the @query
    
    final mentionText = '@${partner.name} ';
    
    // Replace the last word (the incomplete mention) with the full mention
    final newTextBefore = textBeforeCursor.substring(0, textBeforeCursor.length - lastWord.length) + mentionText;
    final newTextAfter = text.substring(selection.baseOffset);
    
    final newText = newTextBefore + newTextAfter;
    
    _captionController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newTextBefore.length),
    );
    
    setState(() {
      _mentionedUserIds.add(partner.id);
      _showMentions = false;
    });
  }

  @override
  void dispose() {
    _captionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final messenger = ScaffoldMessenger.of(context);
    final isArabic = context.read<LocaleProvider>().isArabic;
    final remaining = 7 - _selectedImages.length;
    if (remaining <= 0) {
      messenger.showSnackBar(SnackBar(
        content: Text(isArabic ? 'الحد الأقصى 7 صور' : 'Maximum 7 images'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2))),
            ListTile(
              leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.photo_library_outlined, color: AppColors.primary)),
              title: Text(isArabic ? 'المعرض' : 'Gallery'),
              subtitle: Text(isArabic ? 'اختر عدة صور' : 'Pick multiple', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.camera_alt_outlined, color: Colors.orange)),
              title: Text(isArabic ? 'الكاميرا' : 'Camera'),
              subtitle: Text(isArabic ? 'التقط صورة' : 'Take a photo', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ]),
        ),
      ),
    );
    if (source == null) return;

    if (source == ImageSource.camera) {
      final image = await picker.pickImage(source: ImageSource.camera, imageQuality: 70, maxWidth: 1200);
      if (image != null && mounted) setState(() => _selectedImages.add(File(image.path)));
    } else {
      final images = await picker.pickMultiImage(imageQuality: 70, maxWidth: 1200);
      if (images.isNotEmpty && mounted) {
        setState(() {
          _selectedImages.addAll(images.take(remaining).map((img) => File(img.path)));
        });
      }
    }
  }

  Future<void> _handleSubmit() async {
    final locale = context.read<LocaleProvider>().locale.languageCode;
    
    if (_captionController.text.trim().isEmpty && _selectedImages.isEmpty && widget.post?.imageUrl == null && widget.post?.allImageUrls.isEmpty != false) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(locale == 'ar' 
              ? 'يرجى كتابة نص أو إضافة صورة' 
              : 'Please write text or add image'),
        ),
      );
      return;
    }

    // التحقق من تصنيف المنشور للمنشورات المجتمعية
    if (_showInCommunity && _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(locale == 'ar' 
              ? 'يرجى تصنيف منشورك (عام، نقاش، بيع/شراء، مساعدة، إعلان، أو سؤال)' 
              : 'Please classify your post (General, Discussion, Buy/Sell, Help, Announcement, or Question)'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    // prevent double-tap
    if (_isPosting) return;
    setState(() => _isPosting = true);

    bool success = false;
    try {
      if (widget.post != null) {
        // Update
        success = await context.read<PostsProvider>().updatePost(
          postId: widget.post!.id,
          imageFiles: _selectedImages.isNotEmpty ? _selectedImages : null,
          caption: _captionController.text.trim(),
          category: _selectedCategory?.name,
          mentionedUsers: _mentionedUserIds.toList(),
          showInCommunity: _showInCommunity,
          showInProfile: _showInProfile,
          price: double.tryParse(_priceController.text.trim()),
        );
      } else {
        // Create
        final user = context.read<AuthProvider>().user!;
        success = await context.read<PostsProvider>().createPost(
          userId: user.id,
          userName: user.name,
          userRole: user.role.name,
          userJobTitle: user.jobTitle ?? (user.role == UserRole.shop 
              ? user.getShopCategoryName(context.read<LocaleProvider>().locale.languageCode)
              : user.getRoleDisplayName(context.read<LocaleProvider>().locale.languageCode)),
          userImageUrl: user.profileImageUrl,
          imageFiles: _selectedImages.isNotEmpty ? _selectedImages : null,
          caption: _captionController.text.trim(),
          category: _selectedCategory?.name,
          mentionedUsers: _mentionedUserIds.toList(),
          showInCommunity: _showInCommunity,
          showInProfile: _showInProfile,
          price: double.tryParse(_priceController.text.trim()),
          // إرفاق بيانات المنتج المرتبط إن وجد
          linkedProductId: widget.linkedProduct?.id,
          linkedProductName: widget.linkedProduct?.caption?.split('\n').first,
          linkedProductImage: widget.linkedProduct?.allImageUrls.firstOrNull,
          linkedProductPrice: widget.linkedProduct?.price,
        );
      }
    } catch (e, stack) {
      if (mounted) {
        await AppErrorHandler.show(
          context,
          e,
          stack,
          logContext: 'CreatePostScreen._handleSubmit',
        );
      }
      success = false;
    }

    if (!mounted) return;
    setState(() => _isPosting = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.post != null 
              ? (locale == 'ar' ? 'تم تحديث المنشور بنجاح ✅' : 'Post updated successfully ✅')
              : (locale == 'ar' ? 'تم نشر العمل بنجاح ✅' : 'Post published successfully ✅')),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else if (!success && mounted) {
      final errorMsg = context.read<PostsProvider>().errorMessage ?? 
          (locale == 'ar' ? 'حدث خطأ، حاول مرة أخرى' : 'An error occurred, please try again');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    
    String appBarTitle;
    if (widget.post != null) {
      appBarTitle = context.read<LocaleProvider>().isArabic ? 'تعديل منشور' : 'Edit Post';
    } else {
      if (!widget.showInCommunity && widget.showInProfile) {
        // From profile
        if (user?.role == UserRole.shop) {
          appBarTitle = context.read<LocaleProvider>().isArabic ? 'إضافة منتج' : 'Add Product';
        } else {
          appBarTitle = context.read<LocaleProvider>().isArabic ? 'إضافة عمل منجز' : 'Add Completed Work';
        }
      } else {
        appBarTitle = AppLocalizations.of(context)!.createPost;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // User info
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: user?.profileImageUrl != null
                            ? CachedNetworkImageProvider(user!.profileImageUrl!)
                            : null,
                        child: user?.profileImageUrl == null
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        user?.name ?? '',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Portfolio-only enforcement banner (when posting from profile)
                  if (!widget.showInCommunity && widget.showInProfile)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              context.read<LocaleProvider>().isArabic
                                  ? 'يرجى نشر أعمالك المنجزة فقط هنا. هذا القسم مخصص لعرض إنجازاتك للعملاء.'
                                  : 'Please only post your completed work here. This section showcases your portfolio to clients.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.primary,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // Caption Input
                  TextField(
                    controller: _captionController,
                    maxLines: null,
                    decoration: InputDecoration(
                      hintText: (!widget.showInCommunity && widget.showInProfile)
                          ? (context.read<LocaleProvider>().isArabic ? 'ما هو آخر عمل أنجزته؟' : 'What is the latest work you completed?')
                          : (context.read<LocaleProvider>().isArabic ? 'بماذا تفكر؟' : "What's on your mind?"),
                      border: InputBorder.none,
                      hintStyle: TextStyle(
                        color: AppColors.textSecondary.withValues(alpha: 0.5),
                        fontSize: 18,
                      ),
                    ),
                    style: const TextStyle(fontSize: 18),
                  ),

                  const SizedBox(height: 16),

                  // Price Input (Only for Shops)
                  if (user?.role == UserRole.shop && !widget.showInCommunity && widget.showInProfile) ...[
                    TextField(
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        hintText: context.read<LocaleProvider>().isArabic ? 'السعر (اختياري)' : 'Price (Optional)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        prefixIcon: const Icon(Icons.attach_money),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Category Selection (Only for Community Posts)
                  if (_showInCommunity) ...[ 
                    SizedBox(
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.read<LocaleProvider>().isArabic ? 'تصنيف المنشور:' : 'Post Category:',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 10),
                          // Step 1: Main Group Selection
                          SizedBox(
                            height: 44,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: PostCategoryGroup.values.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                final group = PostCategoryGroup.values[index];
                                final isSelected = _selectedCategory != null && _selectedCategory!.group == group;
                                return GestureDetector(
                                  onTap: () => _showSubcategoryPicker(group),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected ? group.color : group.color.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: isSelected ? group.color : group.color.withValues(alpha: 0.3)),
                                    ),
                                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                                      Icon(group.icon, size: 16, color: isSelected ? Colors.white : group.color),
                                      const SizedBox(width: 6),
                                      Text(group.getName(context.read<LocaleProvider>().locale.languageCode), style: TextStyle(
                                        color: isSelected ? Colors.white : group.color,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                        fontSize: 13,
                                      )),
                                    ]),
                                  ),
                                );
                              },
                            ),
                          ),
                          // Selected Category Display
                          if (_selectedCategory != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: _selectedCategory!.group.color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: _selectedCategory!.group.color.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle, size: 16, color: _selectedCategory!.group.color),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${_selectedCategory!.group.getName(context.read<LocaleProvider>().locale.languageCode)} › ${_selectedCategory!.getName(context.read<LocaleProvider>().locale.languageCode)}',
                                      style: TextStyle(
                                        color: _selectedCategory!.group.color,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () => setState(() => _selectedCategory = null),
                                      child: Icon(Icons.close, size: 16, color: _selectedCategory!.group.color),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // ─── خيار الإضافة لمعرض الأعمال ───────────────────────────────
                  // يظهر فقط عند النشر في المجتمع وللمستخدمين الذين لديهم معرض (غير المتاجر لأن المتاجر تضيف المنتجات في الملف)
                  if (_showInCommunity && (user?.role != UserRole.shop))
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.1)),
                      ),
                      child: CheckboxListTile(
                        value: _showInProfile,
                        onChanged: (v) => setState(() => _showInProfile = v ?? false),
                        title: Text(
                          context.read<LocaleProvider>().isArabic ? 'إضافة إلى معرض أعمالي (الملف الشخصي)' : 'Add to my portfolio (Profile)',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        activeColor: AppColors.secondary,
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ),
                  
                  // ─── بطاقة المنتج المرتبط ────────────────────────────
                  // تظهر عندما يأتي صاحب المتجر من شاشة تفاصيل المنتج
                  if (widget.linkedProduct != null)
                    _LinkedProductCard(
                      product: widget.linkedProduct!,
                      isArabic: context.read<LocaleProvider>().isArabic,
                    ),

                  const SizedBox(height: 24),


                  // Images Preview (Mosaic Grid)
                  if (_selectedImages.isNotEmpty)
                    AspectRatio(
                      aspectRatio: 1.1,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _buildSelectedMosaic(_selectedImages),
                      ),
                    )
                  else if (widget.post != null && widget.post!.allImageUrls.isNotEmpty)
                    AspectRatio(
                      aspectRatio: 1.1,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _buildExistingMosaic(widget.post!.allImageUrls),
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // Mentions List (Suggestions)
          if (_showMentions)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: MentionOverlay(
                partners: _filteredPartners,
                locale: context.read<LocaleProvider>().locale.languageCode,
                onSelectUser: _addMention,
              ),
            ),
          
          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(top: BorderSide(color: AppColors.border.withValues(alpha: 0.3))),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, -2))],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Camera button
                  Material(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: _pickImage,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.add_photo_alternate_outlined, color: AppColors.primary, size: 22),
                          if (_selectedImages.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                              child: Text('${_selectedImages.length}/7', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ]),
                      ),
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Submit Button
                  GestureDetector(
                    onTap: _isPosting ? null : _handleSubmit,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF5f3dc4)]),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))],
                      ),
                      child: _isPosting
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(widget.post != null ? Icons.check : Icons.send, color: Colors.white, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                widget.post != null
                                    ? (context.read<LocaleProvider>().isArabic ? 'تحديث' : 'Update')
                                    : (context.read<LocaleProvider>().isArabic ? 'نشر' : 'Post'),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedMosaic(List<File> files) {
    if (files.length == 1) return _buildSelectedFileItem(files[0], 0);
    
    if (files.length == 2) {
      return Row(
        children: [
          Expanded(child: _buildSelectedFileItem(files[0], 0)),
          const SizedBox(width: 2),
          Expanded(child: _buildSelectedFileItem(files[1], 1)),
        ],
      );
    }

    if (files.length == 3) {
      return Column(
        children: [
          Expanded(child: _buildSelectedFileItem(files[0], 0)),
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(child: _buildSelectedFileItem(files[1], 1)),
              const SizedBox(width: 2),
              Expanded(child: _buildSelectedFileItem(files[2], 2)),
            ],
          ),
        ],
      );
    }

    // 4+ images
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(child: _buildSelectedFileItem(files[0], 0)),
              const SizedBox(width: 2),
              Expanded(child: _buildSelectedFileItem(files[1], 1)),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Expanded(
          child: Row(
            children: [
              Expanded(child: _buildSelectedFileItem(files[2], 2)),
              const SizedBox(width: 2),
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildSelectedFileItem(files[3], 3),
                    if (files.length > 4)
                      Container(
                        color: Colors.black45,
                        child: Center(
                          child: Text('+${files.length - 4}', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedFileItem(File file, int index) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.file(file, fit: BoxFit.cover),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => setState(() => _selectedImages.removeAt(index)),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExistingMosaic(List<String> urls) {
     if (urls.length == 1) return _buildExistingUrlItem(urls[0], true);
    
    if (urls.length == 2) {
      return Row(
        children: [
          Expanded(child: _buildExistingUrlItem(urls[0])),
          const SizedBox(width: 2),
          Expanded(child: _buildExistingUrlItem(urls[1])),
        ],
      );
    }

    if (urls.length == 3) {
      return Column(
        children: [
          Expanded(child: _buildExistingUrlItem(urls[0])),
          const SizedBox(height: 2),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildExistingUrlItem(urls[1])),
                const SizedBox(width: 2),
                Expanded(child: _buildExistingUrlItem(urls[2])),
              ],
            ),
          ),
        ],
      );
    }

    // 4+ images
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(child: _buildExistingUrlItem(urls[0])),
              const SizedBox(width: 2),
              Expanded(child: _buildExistingUrlItem(urls[1])),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Expanded(
          child: Row(
            children: [
              Expanded(child: _buildExistingUrlItem(urls[2])),
              const SizedBox(width: 2),
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildExistingUrlItem(urls[3]),
                    if (urls.length > 4)
                      Container(
                        color: Colors.black45,
                        child: Center(
                          child: Text('+${urls.length - 4}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExistingUrlItem(String url, [bool showEdit = false]) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: CloudinaryService.getOptimizedUrl(url, width: 400, quality: 'auto'),
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(color: Colors.grey[200]),
          errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
        ),
        if (showEdit)
          Positioned(
            bottom: 4,
            right: 4,
            child: IconButton(
              onPressed: _pickImage,
              icon: const CircleAvatar(
                backgroundColor: Colors.white70,
                radius: 14,
                child: Icon(Icons.add_photo_alternate, color: AppColors.primary, size: 18),
              ),
            ),
          ),
      ],
    );
  }

  void _showSubcategoryPicker(PostCategoryGroup group) {
    final locale = context.read<LocaleProvider>().locale.languageCode;
    final subcategories = PostCategory.getCategoriesForGroup(group);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2))),
                Row(
                  children: [
                    Icon(group.icon, color: group.color, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      group.getName(locale),
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: group.color),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: subcategories.length,
                    itemBuilder: (ctx, index) {
                      final cat = subcategories[index];
                      final isSelected = _selectedCategory == cat;
                      return ListTile(
                        leading: Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: isSelected ? group.color : group.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isSelected ? Icons.check : group.icon,
                            color: isSelected ? Colors.white : group.color,
                            size: 18,
                          ),
                        ),
                        title: Text(
                          cat.getName(locale),
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? group.color : null,
                          ),
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        tileColor: isSelected ? group.color.withValues(alpha: 0.06) : null,
                        onTap: () {
                          setState(() => _selectedCategory = cat);
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
/// بطاقة المنتج المرتبط — تظهر في شاشة إنشاء المنشور
// ════════════════════════════════════════════════════════════════════════════
class _LinkedProductCard extends StatelessWidget {
  final PostModel product;
  final bool isArabic;

  const _LinkedProductCard({required this.product, required this.isArabic});

  @override
  Widget build(BuildContext context) {
    final productName = product.caption?.split('\n').first ??
        (isArabic ? 'منتج' : 'Product');
    final imageUrl = product.allImageUrls.firstOrNull;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.08),
            AppColors.secondary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // صورة المنتج المصغرة
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        width: 64,
                        height: 64,
                        color: Colors.grey[200],
                      ),
                      errorWidget: (_, __, ___) => Container(
                        width: 64,
                        height: 64,
                        color: Colors.grey[200],
                        child: const Icon(Icons.image, color: Colors.grey),
                      ),
                    )
                  : Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.shopping_bag_outlined,
                          color: AppColors.primary, size: 28),
                    ),
            ),
            const SizedBox(width: 12),

            // تفاصيل المنتج
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isArabic ? '🛍️ منتج مرتبط' : '🛍️ Linked Product',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    productName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (product.price != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${product.price!.toStringAsFixed(0)} SDG',
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),

            // أيقونة الربط
            const Icon(Icons.link_rounded,
                color: AppColors.primary, size: 22),
          ],
        ),
      ),
    );
  }
}
