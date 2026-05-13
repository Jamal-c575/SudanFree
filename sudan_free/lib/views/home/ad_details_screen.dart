import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/ad_model.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/common/image_carousel.dart';
import '../../services/firestore/ad_service.dart';

class AdDetailsScreen extends StatelessWidget {
  final AdModel ad;

  const AdDetailsScreen({super.key, required this.ad});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Fallback for mediaUrls
    final List<String> images = ad.mediaUrls.isNotEmpty 
        ? ad.mediaUrls 
        : (ad.mediaUrl.isNotEmpty ? [ad.mediaUrl] : []);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 48,
        title: const Text('تفاصيل الإعلان', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black.withValues(alpha: 0.45),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
      ),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero Image or Carousel
            if (images.isNotEmpty)
              images.length == 1
                  ? CachedNetworkImage(
                      imageUrl: images.first,
                      height: 350,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 350,
                        color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 350,
                        color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                        child: const Icon(Icons.error, size: 50, color: Colors.grey),
                      ),
                    )
                  : ImageCarousel(
                      imageUrls: images,
                      height: 350,
                      fit: BoxFit.cover,
                    )
            else
              Container(
                height: 350,
                color: isDark ? Colors.grey.shade900 : Colors.grey.shade300,
                child: const Center(
                  child: Icon(Icons.campaign, size: 80, color: Colors.grey),
                ),
              ),

            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Advertiser Badge
                  if (ad.advertiserName != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.storefront, color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            ad.advertiserName!,
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Title
                  Text(
                    ad.title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description
                  Text(
                    ad.description,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 24),



                  // Action Button
                  if (ad.actionUrl != null && ad.actionUrl!.isNotEmpty)
                    SizedBox(
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
                          AdService().recordClick(ad.id);
                          final uri = Uri.tryParse(ad.actionUrl!);
                          if (uri != null) {
                            try {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            } catch (_) {}
                          }
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
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
                    ),
                    
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


}
