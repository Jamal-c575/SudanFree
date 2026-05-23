import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/post_model.dart';
import '../../widgets/common/linkable_text.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/locale_provider.dart';
import '../../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import '../../widgets/common/full_screen_image_viewer.dart';
import '../../models/user_model.dart';
import '../posts/create_post_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final PostModel product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _currentIndex = 0;

  String _buildProductLink() =>
      'https://jamall123.github.io/HOME_WEB/sudan-free.html?productId=${widget.product.id}';

  Future<void> _copyProductLink(bool isArabic) async {
    await Clipboard.setData(ClipboardData(text: _buildProductLink()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Text(isArabic ? 'تم نسخ رابط المنتج ✅' : 'Product link copied ✅'),
      ]),
      backgroundColor: Colors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    ));
  }

  void _shareInCommunity() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreatePostScreen(
          showInCommunity: true,
          showInProfile: false,
          linkedProduct: widget.product,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>().locale.languageCode;
    final isArabic = locale == 'ar';
    final currentUser = context.watch<AuthProvider>().user;
    final isMyProduct = currentUser?.id == widget.product.userId;
    final isShopOwner = currentUser?.role == UserRole.shop;
    final allMedia = widget.product.allImageUrls;

    final productTitle = widget.product.caption?.split('\n').first ?? '';
    final productDesc = widget.product.caption != null &&
            widget.product.caption!.contains('\n')
        ? widget.product.caption!.split('\n').skip(1).join('\n').trim()
        : '';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          isArabic ? 'تفاصيل المنتج' : 'Product Details',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.link_rounded),
            tooltip: isArabic ? 'نسخ رابط المنتج' : 'Copy link',
            onPressed: () => _copyProductLink(isArabic),
          ),
        ],
      ),

      bottomNavigationBar: (isMyProduct && isShopOwner) ? SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _shareInCommunity,
              icon: const Icon(Icons.group_rounded, size: 18),
              label: Text(
                isArabic ? 'نشر في المجتمع' : 'Post to Community',
                style: const TextStyle(fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
      ) : null,

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── معرض الصور ──────────────────────────────────────────
            _buildImageGallery(context, allMedia),

            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── بطاقة الاسم + السعر ────────────────────────────
                  _InfoCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // اسم المنتج
                        if (productTitle.isNotEmpty)
                          Text(
                            productTitle,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              height: 1.3,
                            ),
                          ),

                        if (productTitle.isNotEmpty) const SizedBox(height: 14),

                        // السعر + الحالة + التوصيل
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (widget.product.price != null)
                              _PriceBadge(
                                  price: widget.product.price!,
                                  isArabic: isArabic),
                            if (widget.product.productCondition != null)
                              _ConditionBadge(
                                  condition: widget.product.productCondition!,
                                  isArabic: isArabic),
                            if (widget.product.hasShipping)
                              _ShippingBadge(isArabic: isArabic),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── بطاقة الوصف ────────────────────────────────────
                  if (productDesc.isNotEmpty)
                    _InfoCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionTitle(
                            icon: Icons.description_outlined,
                            label: isArabic ? 'الوصف' : 'Description',
                          ),
                          const SizedBox(height: 10),
                          LinkableText(
                            text: productDesc,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey[800],
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (productDesc.isNotEmpty) const SizedBox(height: 12),

                  // ── بطاقة التفاصيل (الفئة العمرية + الكمية) ────────
                  if (widget.product.productAgeGroup != null ||
                      widget.product.quantity != null)
                    _InfoCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionTitle(
                            icon: Icons.info_outline_rounded,
                            label: isArabic ? 'تفاصيل المنتج' : 'Product Info',
                          ),
                          const SizedBox(height: 12),
                          if (widget.product.productAgeGroup != null)
                            _DetailRow(
                              label: isArabic ? 'الفئة العمرية' : 'Age Group',
                              icon: Icons.people_outline,
                              value: _getAgeGroupLabel(
                                  widget.product.productAgeGroup!, isArabic),
                            ),
                          if (widget.product.productAgeGroup != null &&
                              widget.product.quantity != null)
                            const SizedBox(height: 10),
                          if (widget.product.quantity != null)
                            _DetailRow(
                              label: isArabic
                                  ? 'الكمية المتاحة'
                                  : 'Available Qty',
                              icon: Icons.inventory_2_outlined,
                              value: '${widget.product.quantity}',
                            ),
                        ],
                      ),
                    ),

                  if (widget.product.productAgeGroup != null ||
                      widget.product.quantity != null)
                    const SizedBox(height: 12),

                  // ── بطاقة المقاسات ─────────────────────────────────
                  if (widget.product.productSizes.isNotEmpty)
                    _InfoCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionTitle(
                            icon: Icons.straighten_rounded,
                            label: isArabic
                                ? 'المقاسات المتوفرة'
                                : 'Available Sizes',
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: widget.product.productSizes
                                .map((s) => _SizeChip(size: s))
                                .toList(),
                          ),
                        ],
                      ),
                    ),

                  if (widget.product.productSizes.isNotEmpty)
                    const SizedBox(height: 12),

                  // ── بطاقة الألوان ──────────────────────────────────
                  if (widget.product.productColors.isNotEmpty)
                    _InfoCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionTitle(
                            icon: Icons.palette_outlined,
                            label: isArabic
                                ? 'الألوان / التنوعات'
                                : 'Colors / Variants',
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: widget.product.productColors
                                .map((c) => _ColorChip(color: c))
                                .toList(),
                          ),
                        ],
                      ),
                    ),

                  if (widget.product.productColors.isNotEmpty)
                    const SizedBox(height: 12),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── معرض الصور ──────────────────────────────────────────────────────────
  Widget _buildImageGallery(BuildContext context, List<String> allMedia) {
    if (allMedia.isEmpty) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.4,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
        child: const Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
      );
    }

    return Stack(
      children: [
        // صور بشاشة كاملة العرض
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.42,
          width: double.infinity,
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
            child: PageView.builder(
              itemCount: allMedia.length,
              onPageChanged: (i) => setState(() => _currentIndex = i),
              itemBuilder: (context, index) => GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FullScreenImageViewer(
                      imageUrls: allMedia,
                      initialIndex: index,
                    ),
                  ),
                ),
                child: CachedNetworkImage(
                  imageUrl: allMedia[index],
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image,
                        color: Colors.grey, size: 50),
                  ),
                ),
              ),
            ),
          ),
        ),

        // مؤشرات الصفحات
        if (allMedia.length > 1)
          Positioned(
            bottom: 14,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                allMedia.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _currentIndex == i ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _currentIndex == i
                        ? AppColors.primary
                        : Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4)
                    ],
                  ),
                ),
              ),
            ),
          ),

        // عداد الصور
        if (allMedia.length > 1)
          Positioned(
            top: 12,
            right: 16,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_currentIndex + 1} / ${allMedia.length}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }

  String _getAgeGroupLabel(String group, bool isAr) {
    const labels = {
      'baby': {'ar': '👶 رضيع', 'en': '👶 Baby'},
      'child': {'ar': '🧒 طفل', 'en': '🧒 Child'},
      'youth': {'ar': '👦 شباب', 'en': '👦 Youth'},
      'adult': {'ar': '👨 بالغ', 'en': '👨 Adult'},
      'elderly': {'ar': '👴 كبار', 'en': '👴 Elderly'},
      'all': {'ar': '👨‍👩‍👧 الكل', 'en': '👨‍👩‍👧 All Ages'},
    };
    return labels[group]?[isAr ? 'ar' : 'en'] ?? group;
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Helper Widgets
// ══════════════════════════════════════════════════════════════════════════════

/// بطاقة معلومات عامة بحواف دائرية وظل خفيف
class _InfoCard extends StatelessWidget {
  final Widget child;
  const _InfoCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// عنوان القسم مع أيقونة
class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionTitle({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: AppColors.primary),
      ),
      const SizedBox(width: 8),
      Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    ]);
  }
}

/// صف تفصيل (أيقونة + تسمية + قيمة)
class _DetailRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  const _DetailRow(
      {required this.label, required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 18, color: Colors.grey[500]),
      const SizedBox(width: 10),
      Text(
        '$label:',
        style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w600),
      ),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ),
    ]);
  }
}

/// شريحة المقاس
class _SizeChip extends StatelessWidget {
  final String size;
  const _SizeChip({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.35)),
      ),
      child: Text(
        size,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
    );
  }
}

/// شريحة اللون / التنوع
class _ColorChip extends StatelessWidget {
  final String color;
  const _ColorChip({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Text(color, style: const TextStyle(fontSize: 13)),
    );
  }
}

/// شارة السعر الكبيرة
class _PriceBadge extends StatelessWidget {
  final double price;
  final bool isArabic;
  const _PriceBadge({required this.price, required this.isArabic});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF5f3dc4)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        '${price.toStringAsFixed(0)} SDG',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// شارة حالة المنتج (جديد / مستعمل)
class _ConditionBadge extends StatelessWidget {
  final String condition;
  final bool isArabic;
  const _ConditionBadge({required this.condition, required this.isArabic});

  @override
  Widget build(BuildContext context) {
    final isNew = condition == 'new';
    final color = isNew ? Colors.green : Colors.orange;
    final label = isNew
        ? (isArabic ? '✨ جديد' : '✨ New')
        : (isArabic ? '♻️ مستعمل' : '♻️ Used');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: isNew ? Colors.green[700] : Colors.orange[700],
        ),
      ),
    );
  }
}

/// شارة التوصيل
class _ShippingBadge extends StatelessWidget {
  final bool isArabic;
  const _ShippingBadge({required this.isArabic});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.teal.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.withValues(alpha: 0.4)),
      ),
      child: Text(
        isArabic ? '🚚 توصيل متاح' : '🚚 Ships',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.teal[700],
        ),
      ),
    );
  }
}
