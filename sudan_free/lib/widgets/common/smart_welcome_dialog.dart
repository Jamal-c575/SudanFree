import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sudan_free/widgets/common/glass_container.dart';
import 'package:sudan_free/views/profile/product_detail_screen.dart';
import 'package:sudan_free/models/post_model.dart';
import 'package:sudan_free/core/utils/navigation_utils.dart';
import 'package:url_launcher/url_launcher.dart';

class SmartWelcomeDialog extends StatefulWidget {
  const SmartWelcomeDialog({super.key});

  @override
  State<SmartWelcomeDialog> createState() => _SmartWelcomeDialogState();
}

class _SmartWelcomeDialogState extends State<SmartWelcomeDialog> {
  bool _loading = true;
  int _newUsersCount = 0;
  Map<String, dynamic>? _adData;
  PostModel? _productData;
  int _displayType = 1; // 1: Ad, 2: Product

  @override
  void initState() {
    super.initState();
    _displayType = Random().nextInt(2) + 1; 
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    try {
      // 1. Fetch Stats (Newly joined users in 7 days)
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      final countSnap = await FirebaseFirestore.instance
          .collection('users')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo))
          .count()
          .get();
      _newUsersCount = countSnap.count ?? 0;

      // 2. Fetch Ad or Product based on display type
      if (_displayType == 1) {
        final adSnap = await FirebaseFirestore.instance
            .collection('ads')
            .where('isActive', isEqualTo: true)
            .limit(5)
            .get();
        if (adSnap.docs.isNotEmpty) {
           _adData = adSnap.docs[Random().nextInt(adSnap.docs.length)].data();
        } else {
           _displayType = 2; // Fallback to product if no active ads
        }
      }
      
      if (_displayType == 2) {
         final postSnap = await FirebaseFirestore.instance
            .collection('posts')
            .orderBy('createdAt', descending: true)
            .limit(10)
            .get();
         if (postSnap.docs.isNotEmpty) {
           final randomDoc = postSnap.docs[Random().nextInt(postSnap.docs.length)];
           final data = randomDoc.data();
           data['id'] = randomDoc.id;
           _productData = PostModel.fromMap(data);
         }
      }

      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: GlassContainer(
        enableBlur: true,
        color: Colors.black, 
        opacity: 0.85,        
        padding: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(child: CircularProgressIndicator(color: Colors.white)),
                  )
                else ...[
                  const SizedBox(height: 16),
                  _buildStatsBanner(),
                  const SizedBox(height: 16),
                  if (_newUsersCount > 0)
                    const Divider(color: Colors.white24, height: 1),
                  if (_newUsersCount > 0)
                    const SizedBox(height: 16),
                  if (_displayType == 1 && _adData != null)
                    _buildAd(_adData!)
                  else if (_displayType == 2 && _productData != null)
                    _buildProduct(_productData!),
                ]
              ],
            ),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 24),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsBanner() {
    if (_newUsersCount == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.group_add, color: Theme.of(context).primaryColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'مجتمعنا ينمو!',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'انضم إلينا $_newUsersCount عضو وحرفي جديد هذا الأسبوع. اكتشف خدماتهم الآن!',
                  style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAd(Map<String, dynamic> ad) {
    final title = ad['title'] ?? 'إعلان مميز';
    final description = ad['description'] ?? '';
    final imageUrl = ad['imageUrl'];
    final link = ad['link'] as String?;

    return GestureDetector(
      onTap: () async {
        if (link != null && link.isNotEmpty) {
          Navigator.pop(context);
          final uri = Uri.parse(link);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
          }
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(imageUrl, height: 170, width: double.infinity, fit: BoxFit.cover),
            )
          else
            Container(
              height: 170,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.campaign, size: 50, color: Colors.white38),
            ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 16),
          const Text(
            'اضغط للتفاصيل',
            style: TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildProduct(PostModel post) {
    final images = post.allImageUrls;
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        NavigationUtils.navigateSafely(context, ProductDetailScreen(product: post));
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.local_fire_department, color: Colors.amber, size: 22),
              const SizedBox(width: 8),
              const Text(
                'عرض مؤقت!',
                style: TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (images.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(images.first, height: 170, width: double.infinity, fit: BoxFit.cover),
            )
          else
            Container(
              height: 170,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.shopping_bag, size: 50, color: Colors.white38),
            ),
          const SizedBox(height: 16),
          Text(
            post.caption ?? 'منتج مميز بانتظارك',
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (post.price != null && post.price! > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${post.price} جنيه',
                style: const TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Text(
            'اضغط للتفاصيل',
            style: TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
