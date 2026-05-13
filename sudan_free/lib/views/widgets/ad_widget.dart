import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/ad_model.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/common/image_carousel.dart';

class AdWidget extends StatelessWidget {
  final AdModel ad;
  final VoidCallback? onTap;
  
  const AdWidget({super.key, required this.ad, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1A3A5C), const Color(0xFF0D2B45)]
              : [Colors.teal.shade50, Colors.blue.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: isDark ? Colors.teal.shade800 : Colors.teal.shade200,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withValues(alpha: isDark ? 0.05 : 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sponsored badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.teal.shade600,
                borderRadius: const BorderRadius.only(bottomRight: Radius.circular(16)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.campaign, color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    ad.advertiserName != null ? 'إعلان من ${ad.advertiserName}' : 'إعلان ممول',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            // Ad Media
            if (ad.mediaUrls.isNotEmpty)
              ad.mediaUrls.length == 1
                ? CachedNetworkImage(
                    imageUrl: ad.mediaUrls.first,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 180,
                      color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 180,
                      color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                      child: const Icon(Icons.error, color: Colors.grey),
                    ),
                  )
                : ImageCarousel(
                    imageUrls: ad.mediaUrls,
                    height: 180,
                    fit: BoxFit.cover,
                  )
            else if (ad.mediaUrl.isNotEmpty)
              CachedNetworkImage(
                imageUrl: ad.mediaUrl,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 180,
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 180,
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  child: const Icon(Icons.error, color: Colors.grey),
                ),
              ),
              
            // Ad Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ad.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ad.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                  if (ad.actionUrl != null && ad.actionUrl!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: () async {
                          onTap?.call();
                          final uri = Uri.parse(ad.actionUrl!);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        },
                        child: const Text('تصفح الآن', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    )
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
