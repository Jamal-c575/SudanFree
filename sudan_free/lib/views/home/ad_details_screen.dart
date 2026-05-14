import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/ad_model.dart';
import '../../core/constants/app_colors.dart';
import '../../services/firestore/ad_service.dart';

class AdDetailsScreen extends StatefulWidget {
  final AdModel ad;

  const AdDetailsScreen({super.key, required this.ad});

  @override
  State<AdDetailsScreen> createState() => _AdDetailsScreenState();
}

class _AdDetailsScreenState extends State<AdDetailsScreen> {
  int _selectedImageIndex = 0;
  List<String> _images = [];
  bool _showFullDescription = false;

  @override
  void initState() {
    super.initState();
    _images = widget.ad.mediaUrls.isNotEmpty 
        ? widget.ad.mediaUrls 
        : (widget.ad.mediaUrl.isNotEmpty ? [widget.ad.mediaUrl] : []);
        
    // Limit to maximum 5 images as requested
    if (_images.length > 5) {
      _images = _images.sublist(0, 5);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
      body: SafeArea(
        top: false, // Allow app bar to extend behind, but protect content below
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Main Hero Image - Now properly positioned below status bar
              if (_images.isNotEmpty)
                Container(
                  height: 350,
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 48), // Account for app bar height
                  child: CachedNetworkImage(
                    imageUrl: _images[_selectedImageIndex],
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
                  ),
                )
              else
                Container(
                  height: 350,
                  margin: const EdgeInsets.only(top: 48), // Account for app bar height
                  color: isDark ? Colors.grey.shade900 : Colors.grey.shade300,
                  child: const Center(
                    child: Icon(Icons.campaign, size: 80, color: Colors.grey),
                  ),
                ),

            // Thumbnails Row
            if (_images.length > 1)
              Container(
                height: 80,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_images.length, (index) {
                    final isSelected = index == _selectedImageIndex;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedImageIndex = index;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : Colors.transparent,
                            width: 2.5,
                          ),
                          boxShadow: isSelected 
                              ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 4)]
                              : null,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: CachedNetworkImage(
                            imageUrl: _images[index],
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
                            errorWidget: (context, url, error) => const Icon(Icons.error, size: 20),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),

            // Content
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Advertiser Badge
                  if (widget.ad.advertiserName != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      margin: const EdgeInsets.only(bottom: 20),
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
                            widget.ad.advertiserName!,
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
                    widget.ad.title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Category/Location info
                  if (widget.ad.targetCategory != 'all')
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        widget.ad.targetCategory,
                        style: TextStyle(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),

                  // Description with Read More
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الوصف',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.ad.description,
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.6,
                          color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                        ),
                        maxLines: _showFullDescription ? null : 4,
                        overflow: _showFullDescription ? null : TextOverflow.ellipsis,
                      ),
                      if (widget.ad.description.length > 200)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _showFullDescription = !_showFullDescription;
                            });
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            _showFullDescription ? 'عرض أقل' : 'قراءة المزيد',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Action Button
                  if (widget.ad.actionUrl != null && widget.ad.actionUrl!.isNotEmpty)
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
                          AdService().recordClick(widget.ad.id);
                          final uri = Uri.tryParse(widget.ad.actionUrl!);
                          if (uri != null) {
                            try {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            } catch (_) {}
                          }
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
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
                    
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
