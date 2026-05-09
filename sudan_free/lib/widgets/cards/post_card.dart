import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../models/post_model.dart';
import '../../providers/posts_provider.dart';
import '../../providers/auth_provider.dart';
import '../../views/posts/comments_sheet.dart';
import '../../views/posts/create_post_screen.dart';
import '../../services/cloudinary_service.dart';
import '../../views/profile/profile_screen.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/user_model.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../common/verification_badge.dart';
import '../common/linkable_text.dart';
import '../../views/posts/post_details_screen.dart';


class PostCard extends StatefulWidget {
  final PostModel post;
  final String currentUserId;
  final String locale;
  final bool enableHero;
  final bool showActions;

  const PostCard({
    super.key,
    required this.post,
    required this.currentUserId,
    required this.locale,
    this.enableHero = true,
    this.showActions = true,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool _isSharing = false;
  int _currentImageIndex = 0;

  String _getTimeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) {
      return widget.locale == 'ar' ? '${diff.inMinutes} د' : '${diff.inMinutes}m';
    } else if (diff.inHours < 24) {
      return widget.locale == 'ar' ? '${diff.inHours} س' : '${diff.inHours}h';
    } else {
      return widget.locale == 'ar' ? '${diff.inDays} ي' : '${diff.inDays}d';
    }
  }

  void _openDetails() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PostDetailsScreen(post: widget.post),
      ),
    );
  }

  Widget _buildGridImage(String url, {double? height, bool isHero = false}) {
    // Precache the high-res version in background so details/fullscreen loads instantly
    final detailUrl = CloudinaryService.getOptimizedUrl(url, width: 1200, quality: 'auto');
    precacheImage(CachedNetworkImageProvider(detailUrl), context);

    Widget image = CachedNetworkImage(
      imageUrl: CloudinaryService.getOptimizedUrl(url, width: 600, quality: 'auto'),
      fit: BoxFit.cover,
      width: double.infinity,
      height: height,
      placeholder: (_, __) => Container(
        color: AppColors.border.withValues(alpha: 0.1),
        child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
      ),
      errorWidget: (_, __, ___) => Container(
        color: AppColors.border.withValues(alpha: 0.1),
        child: const Icon(Icons.broken_image, color: Colors.grey, size: 20),
      ),
    );

    if (isHero && widget.enableHero) {
      image = Hero(tag: widget.post.id, child: image);
    }

    return GestureDetector(onTap: _openDetails, child: image);
  }

  Widget _buildImageCarousel(List<String> urls) {
    if (urls.length == 1) {
      return ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 500, minHeight: 250),
        child: _buildGridImage(urls[0], isHero: true),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 400,
          child: PageView.builder(
            itemCount: urls.length,
            onPageChanged: (index) {
              setState(() {
                _currentImageIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return _buildGridImage(urls[index], isHero: index == 0);
            },
          ),
        ),
        if (urls.length > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(urls.length, (index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _currentImageIndex == index ? 8 : 6,
                height: _currentImageIndex == index ? 8 : 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentImageIndex == index 
                      ? AppColors.primary 
                      : AppColors.border.withValues(alpha: 0.5),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Hide post if user data is missing (deleted user)
    if (widget.post.userName.isEmpty || widget.post.userName == '?' || widget.post.userId.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      color: Theme.of(context).cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header - User Info
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProfileScreen(userId: widget.post.userId),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        // Avatar
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 1.5),
                          ),
                          child: CircleAvatar(
                            radius: 24,
                            backgroundColor: AppColors.primary.withValues(alpha: 0.05),
                            backgroundImage: widget.post.userImageUrl != null
                                ? CachedNetworkImageProvider(CloudinaryService.getOptimizedUrl(widget.post.userImageUrl!, width: 100, quality: 'auto'))
                                : null,
                            child: widget.post.userImageUrl == null
                                ? Text(
                                    widget.post.userName.isNotEmpty 
                                        ? widget.post.userName[0].toUpperCase() 
                                        : '?',
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Name and Time
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                    Flexible(
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              widget.post.userName,
                                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          VerificationBadge(isVerified: widget.post.isUserVerified, size: 16),
                                        ],
                                      ),
                                    ),
                                  if (widget.post.userJobTitle != null && widget.post.userJobTitle!.isNotEmpty) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: widget.post.userRole == 'shop' ? Colors.amber.withValues(alpha: 0.2) : AppColors.primary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        widget.post.userJobTitle!,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: widget.post.userRole == 'shop' ? Colors.amber.shade800 : AppColors.primary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    _getTimeAgo(widget.post.createdAt),
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  if (widget.post.category != null) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.secondary.withValues(alpha: 0.05),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        _getCategoryName(widget.post.category!, widget.locale),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.secondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // More Options (Only for post owner)
                if (widget.currentUserId == widget.post.userId)
                  IconButton(
                    icon: Icon(Icons.more_horiz, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    onPressed: () => _showOptions(context),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ),

          // Pinned Indicator
          if (widget.post.isPinned)
            Padding(
              padding: const EdgeInsets.only(top: 4.0, left: 16, right: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                   Icon(Icons.push_pin, size: 12, color: AppColors.secondary),
                   const SizedBox(width: 4),
                   Text(
                     widget.locale == 'ar' ? 'مُثبت' : 'Pinned',
                     style: TextStyle(fontSize: 11, color: AppColors.secondary, fontWeight: FontWeight.bold),
                   ),
                ],
              ),
            ),

          // Caption
          if (widget.post.caption != null && widget.post.caption!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ExpandableCaption(
                caption: widget.post.caption!,
                locale: widget.locale,
              ),
            ),
          ],

          // Adaptive Image Carousel Display
          if (widget.post.allImageUrls.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildImageCarousel(widget.post.allImageUrls),
          ],

          // Actions Bar
          if (widget.showActions) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildActionButton(
                    context,
                    icon: (widget.post.reactions.containsKey(widget.currentUserId)) ? Icons.favorite : Icons.favorite_border,
                    iconColor: (widget.post.reactions.containsKey(widget.currentUserId)) ? Colors.red : null,
                    label: widget.locale == 'ar' ? 'إعجاب' : 'Like',
                    count: widget.post.totalReactions,
                    onTap: () {
                      final type = widget.post.reactions.containsKey(widget.currentUserId) ? 'unlike' : 'like';
                      context.read<PostsProvider>().reactToPost(
                        widget.post.id, 
                        widget.currentUserId, 
                        context.read<AuthProvider>().user?.name ?? 'المستخدم', 
                        widget.post.userId, 
                        type
                      );
                    },
                  ),
                  _buildActionButton(
                    context,
                    icon: Icons.chat_bubble_outline,
                    label: widget.locale == 'ar' ? 'تعليق' : 'Comment',
                    count: widget.post.commentsCount,
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => CommentsSheet(
                          postId: widget.post.id,
                          postOwnerId: widget.post.userId,
                        ),
                      );
                    },
                  ),
                  _buildActionButton(
                    context,
                    icon: Icons.share_outlined,
                    label: widget.locale == 'ar' ? 'مشاركة' : 'Share',
                    count: widget.post.sharesCount,
                    onTap: () => _handleExternalShare(context),
                    isLoading: _isSharing,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int count,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
    Color? iconColor,
    bool isLoading = false,
  }) {
    final bool isRtl = widget.locale == 'ar';
    
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading) ...[
               const SizedBox(
                 width: 16, 
                 height: 16, 
                 child: CircularProgressIndicator(strokeWidth: 2)
               ),
               const SizedBox(width: 8),
            ] else if (!isRtl) ...[
              Icon(icon, size: 20, color: iconColor ?? Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
            ],
            
            Text(
              count > 0 ? '$count $label' : label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: iconColor ?? Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            
            if (!isLoading && isRtl) ...[
              const SizedBox(width: 4),
              Icon(icon, size: 20, color: iconColor ?? Theme.of(context).colorScheme.onSurfaceVariant),
            ],
          ],
        ),
      ),
    );
  }

  void _handleExternalShare(BuildContext context) async {
    if (_isSharing) return;
    
    setState(() => _isSharing = true);
    
    final String text = widget.post.caption ?? '';
    // Use the direct download link as requested
    final String appLink = 'https://jamall123.github.io/HOME_WEB/sudan-free.html';
    
    String shareContent = '${widget.post.userName} ${widget.locale == 'ar' ? 'شارك منشوراً على سودان فري' : 'shared a post on SudanFree'}:\n\n';
    
    if (text.isNotEmpty) {
      shareContent += '$text\n\n';
    }
    
    shareContent += '${widget.locale == 'ar' ? 'حمل التطبيق وشاهد المنشور' : 'Download app to view post'}: $appLink';

    try {
      if (widget.post.imageUrl != null && widget.post.imageUrl!.isNotEmpty) {
        // Show loading (optional, but good UX if feasible)
        // For now, we'll just await.
        
        // 1. Download image to temp file
        final tempDir = await getTemporaryDirectory();
        final fileName = 'share_${widget.post.id}.jpg';
        final file = File('${tempDir.path}/$fileName');
        
        // Use optimized URL for download with BLUR effect (Teaser)
        // w_300: Small size for fast download
        // e_blur:2000: Very strong blur to hide details
        final url = CloudinaryService.getOptimizedUrl(
          widget.post.imageUrl!, 
          width: 300, 
          quality: 'auto',
          extraTransformations: ['e_blur:2000'],
        );
        
        final request = await HttpClient().getUrl(Uri.parse(url));
        final response = await request.close();
        
        if (response.statusCode == 200) {
          await response.pipe(file.openWrite());
          
          // 2. Share Image + Text
          // ignore: deprecated_member_use
          await Share.shareXFiles(
            [XFile(file.path)],
            text: shareContent,
            subject: widget.locale == 'ar' ? 'منشور من سودان فري' : 'Post from SudanFree',
          );
        } else {
          // Fallback to text share if download fails
          // ignore: deprecated_member_use
          await Share.share(
            '$shareContent\n\n${widget.post.imageUrl}',
            subject: widget.locale == 'ar' ? 'منشور من سودان فري' : 'Post from SudanFree',
          );
        }
      } else {
        // Text only share
        // ignore: deprecated_member_use
        await Share.share(
          shareContent,
          subject: widget.locale == 'ar' ? 'منشور من سودان فري' : 'Post from SudanFree',
        );
      }

      if (!context.mounted) return;
      context.read<PostsProvider>().incrementPostShares(widget.post.id);
    } catch (e) {
      debugPrint('Error sharing: $e');
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final user = context.read<AuthProvider>().user;
        final bool canUsePortfolio = user?.role == UserRole.freelancer || 
                                     user?.role == UserRole.shop ||
                                     user?.role == UserRole.techService;
        
        return Wrap(
          children: [
            if (canUsePortfolio)
              ListTile(
                leading: Icon(
                  widget.post.showInProfile ? Icons.business_center_outlined : Icons.add_photo_alternate_outlined, 
                  color: AppColors.secondary
                ),
                title: Text(widget.post.showInProfile 
                    ? (widget.locale == 'ar' ? 'إزالة من معرض الأعمال' : 'Remove from Portfolio')
                    : (widget.locale == 'ar' ? 'إضافة إلى معرض الأعمال' : 'Add to Portfolio')),
                onTap: () async {
                  Navigator.pop(ctx);
                  final success = await context.read<PostsProvider>().updatePost(
                    postId: widget.post.id,
                    showInProfile: !widget.post.showInProfile,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success 
                            ? (widget.locale == 'ar' ? 'تم التحديث بنجاح' : 'Updated successfully')
                            : (widget.locale == 'ar' ? 'فشل التحديث' : 'Update failed')),
                        backgroundColor: success ? Colors.green : Colors.red,
                      ),
                    );
                  }
                },
              ),
            ListTile(
              leading: const Icon(Icons.edit, color: AppColors.primary),
              title: Text(widget.locale == 'ar' ? 'تعديل' : 'Edit'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreatePostScreen(post: widget.post),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: Text(widget.locale == 'ar' ? 'حذف' : 'Delete'),
              onTap: () async {
                Navigator.pop(ctx);
                final success = await context.read<PostsProvider>().deletePost(widget.post.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success 
                          ? (widget.locale == 'ar' ? 'تم الحذف بنجاح' : 'Deleted successfully')
                          : (widget.locale == 'ar' ? 'فشل الحذف' : 'Deletion failed')),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  String _getCategoryName(String categoryName, String locale) {
    try {
      final category = PostCategory.values.firstWhere((e) => e.name == categoryName);
      return category.getName(locale);
    } catch (_) {
      return categoryName;
    }
  }
}

class ExpandableCaption extends StatefulWidget {
  final String caption;
  final String locale;

  const ExpandableCaption({
    super.key,
    required this.caption,
    required this.locale,
  });

  @override
  State<ExpandableCaption> createState() => _ExpandableCaptionState();
}

class _ExpandableCaptionState extends State<ExpandableCaption> {
  bool _isExpanded = false;
  static const int _maxLines = 3;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinkableText(
            text: widget.caption,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.4,
            ),
            maxLines: _isExpanded ? null : _maxLines,
          ),
          if (!_isExpanded && (widget.caption.length > 150 || (widget.caption.split('\n').length > _maxLines)))
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                widget.locale == 'ar' ? 'عرض المزيد...' : 'See more...',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

