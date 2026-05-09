import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/post_model.dart';
import '../../widgets/common/linkable_text.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/locale_provider.dart';
import 'package:provider/provider.dart';
import '../../widgets/common/full_screen_image_viewer.dart';

class ProductDetailScreen extends StatefulWidget {
  final PostModel product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>().locale.languageCode;
    final isArabic = locale == 'ar';
    
    // We get all images (images and videos if any)
    final allMedia = widget.product.allImageUrls;

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'تفاصيل المنتج' : 'Product Details'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section at the top
            if (allMedia.isNotEmpty)
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.45,
                width: double.infinity,
                child: PageView.builder(
                  itemCount: allMedia.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FullScreenImageViewer(
                              imageUrls: allMedia,
                              initialIndex: index,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        color: Colors.black,
                        child: CachedNetworkImage(
                          imageUrl: allMedia[index],
                          fit: BoxFit.contain,
                          placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.broken_image, color: Colors.grey, size: 50),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              )
            else
              Container(
                height: MediaQuery.of(context).size.height * 0.45,
                width: double.infinity,
                color: Colors.grey[200],
                child: const Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
              ),

            // Page indicator for multiple images
            if (allMedia.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    allMedia.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentIndex == index ? 10 : 8,
                      height: _currentIndex == index ? 10 : 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentIndex == index 
                            ? AppColors.primary 
                            : Colors.grey[300],
                      ),
                    ),
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Name ──────────────────────────────────────────────
                  if (widget.product.caption != null && widget.product.caption!.isNotEmpty)
                    Text(
                      widget.product.caption!.split('\n').first,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    )
                  else
                    Text(
                      isArabic ? 'منتج بدون اسم' : 'Unnamed Product',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey[600]),
                    ),

                  const SizedBox(height: 10),

                  // ── Price + badges row ─────────────────────────────────
                  Row(
                    children: [
                      if (widget.product.price != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            '${widget.product.price!.toStringAsFixed(0)} SDG',
                            style: const TextStyle(color: AppColors.primary, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ),
                      if (widget.product.productCondition != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: widget.product.productCondition == 'new'
                                ? Colors.green.withValues(alpha: 0.1)
                                : Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: widget.product.productCondition == 'new'
                                  ? Colors.green.withValues(alpha: 0.5)
                                  : Colors.orange.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Text(
                            widget.product.productCondition == 'new'
                                ? (isArabic ? '✨ جديد' : '✨ New')
                                : (isArabic ? '♻️ مستعمل' : '♻️ Used'),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: widget.product.productCondition == 'new' ? Colors.green[700] : Colors.orange[700],
                            ),
                          ),
                        ),
                      ],
                      if (widget.product.hasShipping) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.teal.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.teal.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            isArabic ? '🚚 توصيل' : '🚚 Ships',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.teal[700]),
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),

                  // ── Description ────────────────────────────────────────
                  if (widget.product.caption != null && widget.product.caption!.contains('\n')) ...[
                    Text(isArabic ? 'الوصف' : 'Description',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    LinkableText(
                      text: widget.product.caption!.split('\n').skip(1).join('\n').trim(),
                      style: TextStyle(fontSize: 15, color: Colors.grey[800], height: 1.5),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Age Group ──────────────────────────────────────────
                  if (widget.product.productAgeGroup != null) ...[
                    _detailRow(
                      isArabic ? 'الفئة العمرية' : 'Age Group',
                      Icons.people_outline,
                      _getAgeGroupLabel(widget.product.productAgeGroup!, isArabic),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // ── Quantity ───────────────────────────────────────────
                  if (widget.product.quantity != null) ...[
                    _detailRow(
                      isArabic ? 'الكمية المتاحة' : 'Available Qty',
                      Icons.inventory_2_outlined,
                      '${widget.product.quantity}',
                    ),
                    const SizedBox(height: 12),
                  ],

                  // ── Sizes ──────────────────────────────────────────────
                  if (widget.product.productSizes.isNotEmpty) ...[
                    Text(isArabic ? 'المقاسات المتوفرة' : 'Available Sizes',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: widget.product.productSizes.map((s) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.secondary.withValues(alpha: 0.35)),
                        ),
                        child: Text(s, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      )).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Colors / Variants ──────────────────────────────────
                  if (widget.product.productColors.isNotEmpty) ...[
                    Text(isArabic ? 'الألوان / التنوعات' : 'Colors / Variants',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: widget.product.productColors.map((c) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                        ),
                        child: Text(c, style: const TextStyle(fontSize: 13)),
                      )).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, IconData icon, String value) {
    return Row(children: [
      Icon(icon, size: 18, color: AppColors.secondary),
      const SizedBox(width: 8),
      Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      Text(value, style: const TextStyle(fontSize: 14)),
    ]);
  }

  String _getAgeGroupLabel(String group, bool isAr) {
    const labels = {
      'baby':    {'ar': '👶 رضيع',   'en': '👶 Baby'},
      'child':   {'ar': '🧒 طفل',    'en': '🧒 Child'},
      'youth':   {'ar': '👦 شباب',   'en': '👦 Youth'},
      'adult':   {'ar': '👨 بالغ',   'en': '👨 Adult'},
      'elderly': {'ar': '👴 كبار',   'en': '👴 Elderly'},
      'all':     {'ar': '👨‍👩‍👧 الكل', 'en': '👨‍👩‍👧 All Ages'},
    };
    return labels[group]?[isAr ? 'ar' : 'en'] ?? group;
  }
}

