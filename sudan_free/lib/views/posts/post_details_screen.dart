import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

import '../../models/post_model.dart';
import '../../widgets/common/linkable_text.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../models/user_model.dart';
import '../../widgets/mentions/mention_overlay.dart';
import '../../services/cloudinary_service.dart';
import '../../widgets/common/full_screen_image_viewer.dart';
/// شاشة تفاصيل المنشور/المنتج مع إمكانية التعليق والتفاعل
class PostDetailsScreen extends StatefulWidget {
  final PostModel post;

  const PostDetailsScreen({super.key, required this.post});

  @override
  State<PostDetailsScreen> createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {
  String _getTimeAgo(DateTime time, BuildContext context) {
    final diff = DateTime.now().difference(time);
    final locale = context.read<LocaleProvider>().locale.languageCode;
    if (diff.inMinutes < 60) {
      return locale == 'ar' ? 'منذ ${diff.inMinutes} دقيقة' : '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return locale == 'ar' ? 'منذ ${diff.inHours} ساعة' : '${diff.inHours}h ago';
    } else {
      return locale == 'ar' ? 'منذ ${diff.inDays} يوم' : '${diff.inDays}d ago';
    }
  }
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  // Mentions Logic
  List<UserModel> _filteredPartners = [];
  bool _showMentions = false;
  int _mentionStart = -1;
  final Map<String, String> _mentionedUsers = {}; // name -> id
  int _currentPage = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    // Fetch partners when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().fetchPartners();
    });
    _commentController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _commentController.removeListener(_onTextChanged);
    _commentController.dispose();
    _commentFocusNode.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _commentController.text;
    final selection = _commentController.selection;
    if (selection.baseOffset < 0) return;
    
    final cursorPos = selection.baseOffset;
    final textBeforeCursor = text.substring(0, cursorPos);
    
    // Check for @
    final lastAt = textBeforeCursor.lastIndexOf('@');
    if (lastAt != -1) {
      final query = textBeforeCursor.substring(lastAt + 1);
      
      // Basic validation: query shouldn't have newlines or too many spaces
      if (query.contains('\n') || query.split(' ').length > 3) {
         if (_showMentions) setState(() => _showMentions = false);
         return;
      }

      final partners = context.read<AuthProvider>().partners;
      final matches = partners.where((p) => p.name.toLowerCase().contains(query.toLowerCase())).toList();
      
      if (matches.isNotEmpty) {
        setState(() {
          _filteredPartners = matches;
          _showMentions = true;
          _mentionStart = lastAt;
        });
      } else {
        setState(() => _showMentions = false);
      }
    } else {
      if (_showMentions) setState(() => _showMentions = false);
    }
  }

  void _selectMention(UserModel user) {
     if (_mentionStart < 0) return;
     
     final text = _commentController.text;
     final selection = _commentController.selection;
     final cursorPos = selection.baseOffset;
     
     // Be safe about bounds
     // textBeforeCursor check ensured lastAt < cursorPos
     final start = _mentionStart;
     final end = cursorPos;
     
     if (start >= 0 && end > start && end <= text.length) {
       final newText = text.replaceRange(start, end, '@${user.name} ');
       _commentController.text = newText;
       _commentController.selection = TextSelection.fromPosition(TextPosition(offset: start + user.name.length + 2));
       
       _mentionedUsers['@${user.name}'] = user.id;
       setState(() => _showMentions = false);
     }
  }

  /// إشارة لجميع الشركاء دفعة واحدة
  void _selectAllPartners() {
    if (_mentionStart < 0) return;
    
    final partners = context.read<AuthProvider>().partners;
    if (partners.isEmpty) return;
    
    final text = _commentController.text;
    final selection = _commentController.selection;
    final cursorPos = selection.baseOffset;
    final start = _mentionStart;
    final end = cursorPos;
    
    if (start >= 0 && end > start && end <= text.length) {
      // Build mentions string for all partners
      final mentionsText = partners.map((p) => '@${p.name}').join(' ');
      final newText = text.replaceRange(start, end, '$mentionsText ');
      _commentController.text = newText;
      _commentController.selection = TextSelection.fromPosition(
        TextPosition(offset: start + mentionsText.length + 1),
      );
      
      // Add all partners to mentioned users map
      for (var partner in partners) {
        _mentionedUsers['@${partner.name}'] = partner.id;
      }
      
      setState(() => _showMentions = false);
    }
  }





  @override
  Widget build(BuildContext context) {

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Row(
          children: [
            const Expanded(child: Text('التفاصيل')),
            Text(
              _getTimeAgo(widget.post.createdAt, context),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image(s) Carousel
                      if (widget.post.allImageUrls.isNotEmpty)
                        Column(
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.width, // Square format
                              child: PageView.builder(
                                controller: _pageController,
                                itemCount: widget.post.allImageUrls.length,
                                onPageChanged: (index) {
                                  setState(() => _currentPage = index);
                                },
                                itemBuilder: (context, index) {
                                  final imageUrl = widget.post.allImageUrls[index];
                                  final widgetContent = GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => FullScreenImageViewer(
                                            imageUrls: widget.post.allImageUrls,
                                            initialIndex: index,
                                          ),
                                        ),
                                      );
                                    },
                                    child: CachedNetworkImage(
                                      imageUrl: CloudinaryService.getOptimizedUrl(imageUrl, width: 1200, quality: 'auto'),
                                      width: double.infinity,
                                      fit: BoxFit.contain,
                                      placeholder: (_, __) => Container(
                                        color: Colors.grey[200],
                                        child: const Center(child: CircularProgressIndicator()),
                                      ),
                                      errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
                                    ),
                                  );

                                  // Only first image gets the hero tag to match the feed
                                  if (index == 0) {
                                    return Hero(
                                      tag: widget.post.id,
                                      child: widgetContent,
                                    );
                                  }
                                  return widgetContent;
                                },
                              ),
                            ),
                            if (widget.post.allImageUrls.length > 1) ...[
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  widget.post.allImageUrls.length,
                                  (index) => Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _currentPage == index
                                          ? Theme.of(context).primaryColor
                                          : Colors.grey[300],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
    
                      // Caption / Description
                      if (widget.post.caption != null && widget.post.caption!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: LinkableText(
                            text: widget.post.caption!,
                            style: const TextStyle(fontSize: 16, height: 1.5),
                          ),
                        ),
    
                      // Stats Row (Reactions & Comments Count)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Icon(Icons.favorite, color: Colors.red[300], size: 18),
                            const SizedBox(width: 4),
                            Text('${widget.post.reactions.length}'),
                            const SizedBox(width: 16),
                            Icon(Icons.comment, color: Colors.grey[600], size: 18),
                            const SizedBox(width: 4),
                            Text('${widget.post.commentsCount}'),
                          ],
                        ),
                      ),
    
                      const SizedBox(height: 20),
                      // Comments section has been temporarily frozen/removed for display-only mode
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          // Mentions Overlay
          if (_showMentions)
            Positioned(
              bottom: 70, 
              left: 16, 
              right: 16,
              child: MentionOverlay(
                partners: _filteredPartners,
                locale: Localizations.localeOf(context).languageCode,
                onSelectAll: _filteredPartners.length > 1 ? _selectAllPartners : null,
                onSelectUser: _selectMention,
              ),
            ),
        ],
      ),
    );
  }

}

