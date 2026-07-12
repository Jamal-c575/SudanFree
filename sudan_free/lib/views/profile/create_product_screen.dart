import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/app_error_handler.dart';
import '../../providers/auth_provider.dart';
import '../../providers/posts_provider.dart';
import '../../providers/locale_provider.dart';
import '../../models/post_model.dart';
import '../../services/cloudinary_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/smart_guide_service.dart';
import '../../services/ai_service.dart';
import '../../widgets/common/smart_ai_input_button.dart';
import 'package:sudan_free/l10n/generated/app_localizations.dart';
import 'package:sudan_free/utils/app_haptics.dart';

class CreateProductScreen extends StatefulWidget {
  final PostModel? product; // for editing
  const CreateProductScreen({super.key, this.product});

  @override
  State<CreateProductScreen> createState() => _CreateProductScreenState();
}

class _CreateProductScreenState extends State<CreateProductScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _customSizeController = TextEditingController();
  final _customColorController = TextEditingController();

  final List<File> _selectedImages = [];
  final List<String> _selectedSizes = [];
  final List<String> _selectedColors = [];
  String? _condition; // 'new' | 'used'
  String? _ageGroup; // 'baby' | 'child' | 'youth' | 'adult' | 'elderly'
  bool _hasShipping = false;
  bool _isPosting = false;
  bool _isEnhancing = false;

  static const _predefinedSizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL', '3XL'];
  static const _predefinedColors = [
    'أبيض',
    'أسود',
    'رمادي',
    'أحمر',
    'أزرق',
    'أخضر',
    'أصفر',
    'بني',
    'وردي',
    'برتقالي',
    'بنفسجي',
    'ذهبي',
    'فضي'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      final p = widget.product!;
      _nameController.text = p.caption ?? '';
      _priceController.text = p.price?.toString() ?? '';
      _quantityController.text = p.quantity?.toString() ?? '';
      _condition = p.productCondition;
      _ageGroup = p.productAgeGroup;
      _hasShipping = p.hasShipping;
      _selectedSizes.addAll(p.productSizes);
      _selectedColors.addAll(p.productColors);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      SmartGuideService.showMicroTip(
        context,
        messageAr: 'الصورة الجذابة والوصف الدقيق هما مفتاحك لمبيعات أسرع 📸',
        messageEn:
            'Great photos and clear descriptions are the key to faster sales 📸',
        tipId: 'product_create_tip',
        icon: Icons.add_photo_alternate_rounded,
      );
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _customSizeController.dispose();
    _customColorController.dispose();
    super.dispose();
  }

  Future<void> _enhanceWithAi() async {
    final currentText = _descController.text.trim();
    if (currentText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.localeName == 'ar' ? 'الرجاء كتابة وصف مبدئي أولاً' : 'Please write an initial description first')),
      );
      return;
    }

    setState(() => _isEnhancing = true);
    try {
      final enhanced = await AiService().enhanceProductDescription(currentText);
      if (mounted) {
        setState(() {
          _descController.text = enhanced;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.localeName == 'ar' ? 'فشل تحسين النص: $e' : 'Failed to enhance text: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isEnhancing = false);
      }
    }
  }

  Future<void> _pickImages() async {
    final remaining = 7 - _selectedImages.length;
    if (remaining <= 0) return;
    final picker = ImagePicker();
    final images =
        await picker.pickMultiImage(imageQuality: 80, maxWidth: 1200);
    if (images.isNotEmpty && mounted) {
      setState(() => _selectedImages
          .addAll(images.take(remaining).map((e) => File(e.path))));
    }
  }

  Future<void> _handleSubmit() async {
    AppHaptics.lightImpact();

    if (_nameController.text.trim().isEmpty) {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      scaffoldMessenger.showSnackBar(SnackBar(
        content: Text(
            AppLocalizations.of(context)!.pleaseEnterAProductName),
        backgroundColor: Colors.orange,
      ));
      return;
    }
    if (_selectedImages.isEmpty &&
        (widget.product?.allImageUrls.isEmpty ?? true)) {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      scaffoldMessenger.showSnackBar(SnackBar(
        content: Text(
            AppLocalizations.of(context)!.pleaseAddAProductImage),
        backgroundColor: Colors.orange,
      ));
      return;
    }
    if (_isPosting) return;
    setState(() => _isPosting = true);

    final caption =
        '${_nameController.text.trim()}\n\n${_descController.text.trim()}'
            .trim();

    try {
      final user = context.read<AuthProvider>().user!;
      final provider = context.read<PostsProvider>();
      bool success;

      if (widget.product != null) {
        success = await provider.updatePost(
          postId: widget.product!.id,
          imageFiles: _selectedImages.isNotEmpty ? _selectedImages : null,
          caption: caption,
          showInCommunity: false,
          showInProfile: true,
          price: double.tryParse(_priceController.text.trim()),
          productSizes: _selectedSizes,
          productCondition: _condition,
          productAgeGroup: _ageGroup,
          productColors: _selectedColors,
          quantity: int.tryParse(_quantityController.text.trim()),
          hasShipping: _hasShipping,
        );
      } else {
        success = await provider.createPost(
          userId: user.id,
          userName: user.name,
          userRole: user.role.name,
          userJobTitle: user.getShopCategoryName(AppLocalizations.of(context)!.en),
          userImageUrl: user.profileImageUrl,
          imageFiles: _selectedImages.isNotEmpty ? _selectedImages : null,
          caption: caption,
          showInCommunity: false,
          showInProfile: true,
          price: double.tryParse(_priceController.text.trim()),
          productSizes: _selectedSizes,
          productCondition: _condition,
          productAgeGroup: _ageGroup,
          productColors: _selectedColors,
          quantity: int.tryParse(_quantityController.text.trim()),
          hasShipping: _hasShipping,
        );
      }

      if (!mounted) return;
      setState(() => _isPosting = false);
      if (success) {
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        scaffoldMessenger.showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)!.productPublishedSuccessfully),
          backgroundColor: Colors.green,
        ));
        if (context.mounted) Navigator.pop(context);
      }
    } catch (e, stack) {
      if (mounted) {
        setState(() => _isPosting = false);
        AppErrorHandler.show(context, e, stack,
            logContext: 'CreateProductScreen');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.watch<LocaleProvider>().isArabic;
    final theme = Theme.of(context);
    final isEditing = widget.product != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr
            ? (isEditing ? 'تعديل المنتج' : 'إضافة منتج')
            : (isEditing ? 'Edit Product' : 'Add Product')),
        actions: [
          TextButton(
            onPressed: _isPosting ? null : _handleSubmit,
            child: _isPosting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text(
                    isAr
                        ? (isEditing ? 'حفظ' : 'نشر')
                        : (isEditing ? 'Save' : 'Publish'),
                    style: const TextStyle(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Images ──────────────────────────────────────────────
            _sectionTitle(AppLocalizations.of(context)!.productImages,
                Icons.photo_library_outlined),
            const SizedBox(height: 8),
            SizedBox(
              height: 110,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  // Add button
                  if (_selectedImages.length < 7)
                    GestureDetector(
                      onTap: _pickImages,
                      child: Container(
                        width: 100,
                        height: 100,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.secondary.withValues(alpha: 0.4),
                              style: BorderStyle.solid),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined,
                                color: AppColors.secondary, size: 32),
                            SizedBox(height: 4),
                            Text('أضف صورة',
                                style: TextStyle(
                                    fontSize: 11, color: AppColors.secondary)),
                          ],
                        ),
                      ),
                    ),
                  // Existing images (edit mode)
                  if (isEditing)
                    ...widget.product!.allImageUrls.map((url) => Container(
                          width: 100,
                          height: 100,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12)),
                          clipBehavior: Clip.hardEdge,
                          child: CachedNetworkImage(
                            imageUrl: CloudinaryService.getOptimizedUrl(url,
                                width: 200),
                            fit: BoxFit.cover,
                          ),
                        )),
                  // New images
                  ..._selectedImages.asMap().entries.map((entry) => Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12)),
                            clipBehavior: Clip.hardEdge,
                            child: Image.file(entry.value, fit: BoxFit.cover),
                          ),
                          Positioned(
                            top: 2,
                            right: 10,
                            child: GestureDetector(
                              onTap: () => setState(
                                  () => _selectedImages.removeAt(entry.key)),
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle),
                                child: const Icon(Icons.close,
                                    color: Colors.white, size: 14),
                              ),
                            ),
                          ),
                        ],
                      )),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Product Name ─────────────────────────────────────────
            _sectionTitle(
                AppLocalizations.of(context)!.productName, Icons.label_outline),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: _inputDeco(
                  AppLocalizations.of(context)!.egNikeSportsShoe,
                  Icons.label_outline),
            ),

            const SizedBox(height: 16),

            // ── Description ──────────────────────────────────────────
            _sectionTitle(
                AppLocalizations.of(context)!.description, Icons.description_outlined),
            const SizedBox(height: 8),
            TextField(
              controller: _descController,
              maxLines: 4,
              decoration: _inputDeco(
                  AppLocalizations.of(context)!.writeADetailedDescription,
                  Icons.description_outlined),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: SmartAiInputButton(
                controller: _descController,
                onEnhance: _enhanceWithAi,
                isEnhancing: _isEnhancing,
                isArabic: isAr,
              ),
            ),

            const SizedBox(height: 16),

            // ── Price & Quantity ─────────────────────────────────────
            Row(
              children: [
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle(AppLocalizations.of(context)!.priceSdg,
                        Icons.sell_outlined),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _priceController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: _inputDeco(
                          AppLocalizations.of(context)!.str000, Icons.sell_outlined),
                    ),
                  ],
                )),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle(AppLocalizations.of(context)!.quantity,
                        Icons.inventory_2_outlined),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDeco(AppLocalizations.of(context)!.eg10,
                          Icons.inventory_2_outlined),
                    ),
                  ],
                )),
              ],
            ),

            const SizedBox(height: 20),

            // ── Condition ────────────────────────────────────────────
            _sectionTitle(
                AppLocalizations.of(context)!.productCondition, Icons.star_outline),
            const SizedBox(height: 8),
            Row(
              children: [
                _conditionChip(AppLocalizations.of(context)!.strNew, 'new',
                    Icons.fiber_new_rounded, Colors.green),
                const SizedBox(width: 12),
                _conditionChip(AppLocalizations.of(context)!.used, 'used',
                    Icons.recycling_rounded, Colors.orange),
              ],
            ),

            const SizedBox(height: 20),

            // ── Age Group ────────────────────────────────────────────
            _sectionTitle(AppLocalizations.of(context)!.targetAgeGroup,
                Icons.people_outline),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ageChip('baby', AppLocalizations.of(context)!.baby),
                _ageChip('child', AppLocalizations.of(context)!.child),
                _ageChip('youth', AppLocalizations.of(context)!.youth),
                _ageChip('adult', AppLocalizations.of(context)!.adult),
                _ageChip('elderly', AppLocalizations.of(context)!.elderly),
                _ageChip('all', AppLocalizations.of(context)!.all1),
              ],
            ),

            const SizedBox(height: 20),

            // ── Sizes ────────────────────────────────────────────────
            _sectionTitle(AppLocalizations.of(context)!.availableSizes,
                Icons.straighten_outlined),
            const SizedBox(height: 4),
            Text(
                AppLocalizations.of(context)!.selectFromListOrAddCustom,
                style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._predefinedSizes.map((s) {
                  final sel = _selectedSizes.contains(s);
                  return FilterChip(
                    label: Text(s),
                    selected: sel,
                    onSelected: (v) => setState(() =>
                        v ? _selectedSizes.add(s) : _selectedSizes.remove(s)),
                    selectedColor: AppColors.secondary.withValues(alpha: 0.2),
                    checkmarkColor: AppColors.secondary,
                  );
                }),
              ],
            ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                  child: TextField(
                controller: _customSizeController,
                decoration: _inputDeco(
                    AppLocalizations.of(context)!.customSize, Icons.add),
              )),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  final s = _customSizeController.text.trim();
                  if (s.isNotEmpty && !_selectedSizes.contains(s)) {
                    setState(() {
                      _selectedSizes.add(s);
                      _customSizeController.clear();
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: Text(AppLocalizations.of(context)!.add),
              ),
            ]),
            if (_selectedSizes.any((s) => !_predefinedSizes.contains(s))) ...[
              const SizedBox(height: 8),
              Wrap(
                  spacing: 8,
                  children: _selectedSizes
                      .where((s) => !_predefinedSizes.contains(s))
                      .map((s) => Chip(
                          label: Text(s),
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () =>
                              setState(() => _selectedSizes.remove(s)),
                          backgroundColor:
                              AppColors.secondary.withValues(alpha: 0.1)))
                      .toList()),
            ],

            const SizedBox(height: 20),

            // ── Colors ───────────────────────────────────────────────
            _sectionTitle(
                AppLocalizations.of(context)!.availableColorsVariants,
                Icons.palette_outlined),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _predefinedColors.map((c) {
                final sel = _selectedColors.contains(c);
                return FilterChip(
                  label: Text(c, style: const TextStyle(fontSize: 12)),
                  selected: sel,
                  onSelected: (v) => setState(() =>
                      v ? _selectedColors.add(c) : _selectedColors.remove(c)),
                  selectedColor: AppColors.primary.withValues(alpha: 0.15),
                  checkmarkColor: AppColors.primary,
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                  child: TextField(
                controller: _customColorController,
                decoration: _inputDeco(
                    AppLocalizations.of(context)!.customColorvariant,
                    Icons.add),
              )),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  final c = _customColorController.text.trim();
                  if (c.isNotEmpty && !_selectedColors.contains(c)) {
                    setState(() {
                      _selectedColors.add(c);
                      _customColorController.clear();
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: Text(AppLocalizations.of(context)!.add),
              ),
            ]),

            const SizedBox(height: 20),

            // ── Shipping ─────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: _hasShipping
                    ? Colors.teal.withValues(alpha: 0.08)
                    : theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: _hasShipping
                        ? Colors.teal.withValues(alpha: 0.4)
                        : AppColors.border.withValues(alpha: 0.3)),
              ),
              child: SwitchListTile(
                value: _hasShipping,
                onChanged: (v) => setState(() => _hasShipping = v),
                title: Text(AppLocalizations.of(context)!.shippingAvailable,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                    AppLocalizations.of(context)!.enableIfYouOfferDeliveryService,
                    style: const TextStyle(fontSize: 12)),
                activeThumbColor: Colors.teal,
              ),
            ),

            const SizedBox(height: 32),

            // ── Submit ───────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isPosting ? null : _handleSubmit,
                icon: _isPosting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.cloud_upload_outlined),
                label: Text(
                  isAr
                      ? (isEditing ? 'حفظ التغييرات' : 'نشر المنتج')
                      : (isEditing ? 'Save Changes' : 'Publish Product'),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) => Row(children: [
        Icon(icon, size: 18, color: AppColors.secondary),
        const SizedBox(width: 6),
        Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ]);

  InputDecoration _inputDeco(String hint, IconData icon) => InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 20, color: AppColors.secondary),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                BorderSide(color: AppColors.border.withValues(alpha: 0.3))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                BorderSide(color: AppColors.border.withValues(alpha: 0.3))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppColors.secondary, width: 1.5)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );

  Widget _conditionChip(
      String label, String value, IconData icon, Color color) {
    final selected = _condition == value;
    return GestureDetector(
      onTap: () => setState(() => _condition = selected ? null : value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.15)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? color : AppColors.border.withValues(alpha: 0.3),
              width: selected ? 1.5 : 1),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 18, color: selected ? color : Colors.grey),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  color: selected ? color : null)),
        ]),
      ),
    );
  }

  Widget _ageChip(String value, String label) {
    final selected = _ageGroup == value;
    return GestureDetector(
      onTap: () => setState(() => _ageGroup = selected ? null : value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.secondary.withValues(alpha: 0.15)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected
                  ? AppColors.secondary
                  : AppColors.border.withValues(alpha: 0.3),
              width: selected ? 1.5 : 1),
        ),
        child: Text(label,
            style: TextStyle(
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? AppColors.secondary : null,
                fontSize: 13)),
      ),
    );
  }
}
