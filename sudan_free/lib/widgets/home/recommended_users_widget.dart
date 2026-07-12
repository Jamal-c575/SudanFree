import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../../widgets/common/glass_container.dart';
import '../../services/recommendation_service.dart';

class RecommendedUsersWidget extends StatefulWidget {
  final bool isAr;
  final bool showTitle;
  const RecommendedUsersWidget({super.key, this.isAr = true, this.showTitle = true});

  @override
  State<RecommendedUsersWidget> createState() => _RecommendedUsersWidgetState();
}

class _RecommendedUsersWidgetState extends State<RecommendedUsersWidget> {
  List<UserModel> _recommendations = [];
  bool _isLoading = true;
  final _recommendationService = RecommendationService();

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Get cached recommendation IDs
      final cachedIds = await _recommendationService.getCachedRecommendations(user.id);

      List<UserModel> users = [];
      if (cachedIds.isNotEmpty) {
        for (final id in cachedIds.take(6)) {
          final doc = await FirebaseFirestore.instance.collection('users').doc(id).get();
          if (doc.exists && doc.data() != null) {
            users.add(UserModel.fromFirestore(doc));
          }
        }
      }

      // Fallback: load top-rated users if no cache
      if (users.isEmpty) {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('role', whereIn: ['freelancer', 'shop'])
            .where('isAvailable', isEqualTo: true)
            .orderBy('rating', descending: true)
            .limit(6)
            .get();
        users = snapshot.docs.map((d) => UserModel.fromFirestore(d)).toList();
      }

      if (mounted) setState(() { _recommendations = users; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return SizedBox(
        height: 180,
        child: Shimmer.fromColors(
          baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
          highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      );
    }
    if (_recommendations.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showTitle)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Color(0xFFFFB300), size: 20),
                const SizedBox(width: 8),
                Text(
                  widget.isAr ? 'موصى لك' : 'Recommended for You',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _recommendations.length,
            itemBuilder: (context, index) {
              final user = _recommendations[index];
              return _RecommendationCard(user: user, isAr: widget.isAr, onTap: () {
                _recommendationService.trackInteraction(
                  currentUserId: context.read<AuthProvider>().user?.id ?? '',
                  targetUserId: user.id,
                  interactionType: 'view',
                );
              });
            },
          ),
        ),
      ],
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final UserModel user;
  final bool isAr;
  final VoidCallback onTap;

  const _RecommendationCard({required this.user, required this.isAr, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        child: GlassContainer(
          borderRadius: BorderRadius.circular(16),
          padding: const EdgeInsets.all(12),
          enableBlur: true,
          blur: 10,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: user.profileImageUrl != null
                    ? NetworkImage(user.profileImageUrl!)
                    : null,
                backgroundColor: const Color(0xFF1a6b6b),
                child: user.profileImageUrl == null
                    ? Text(user.name.isNotEmpty ? user.name[0] : '?',
                        style: const TextStyle(fontSize: 20, color: Colors.white))
                    : null,
              ),
              const SizedBox(height: 8),
              Text(
                user.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 12),
                  const SizedBox(width: 2),
                  Text(
                    user.rating.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 11, color: Colors.amber),
                  ),
                ],
              ),
              if (user.isVerified) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isAr ? 'موثق ✓' : 'Verified ✓',
                    style: const TextStyle(fontSize: 9, color: Colors.green),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
