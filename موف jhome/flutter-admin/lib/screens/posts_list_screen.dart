// lib/screens/posts_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class PostsListScreen extends ConsumerWidget {
  const PostsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('المقالات', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  onPressed: () => context.go('/posts/new'),
                  icon: const Icon(Icons.add),
                  label: const Text('مقال جديد'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('posts')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('لا توجد مقالات بعد'));
                  }
                  final posts = snapshot.data!.docs;
                  return ListView.separated(
                    itemCount: posts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final post = posts[i].data() as Map<String, dynamic>;
                      final id = posts[i].id;
                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: post['coverImage'] != null && post['coverImage'] != ''
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(post['coverImage'], width: 80, height: 80, fit: BoxFit.cover),
                                )
                              : Container(
                                  width: 80, height: 80,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade800,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.article, size: 30),
                                ),
                          title: Text(post['title'] ?? '(بدون عنوان)',
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(post['excerpt'] ?? '',
                                  maxLines: 2, overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white60)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children: [
                                  _StatusChip(post['status'] ?? 'draft'),
                                  if (post['category'] != null)
                                    Chip(
                                      label: Text(post['category']),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  if (post['publishedAt'] != null)
                                    Text(
                                      DateFormat('yyyy-MM-dd').format(
                                          (post['publishedAt'] as Timestamp).toDate()),
                                      style: const TextStyle(fontSize: 12, color: Colors.white54),
                                    ),
                                  Text('👁 ${post['views'] ?? 0}',
                                      style: const TextStyle(fontSize: 12, color: Colors.white54)),
                                ],
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (action) async {
                              if (action == 'edit') {
                                context.go('/posts/edit/$id');
                              } else if (action == 'delete') {
                                await _confirmAndDelete(context, id, post['title']);
                              } else if (action == 'view') {
                                // افتح المقال في الموقع
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'view', child: Row(children: [Icon(Icons.visibility), SizedBox(width: 8), Text('عرض')])),
                              PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit), SizedBox(width: 8), Text('تعديل')])),
                              PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red), SizedBox(width: 8), Text('أرشفة', style: TextStyle(color: Colors.red))])),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmAndDelete(BuildContext context, String id, String? title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('تأكيد الأرشفة'),
        content: Text('هل تريد أرشفة المقال "${title ?? ''}"؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('أرشفة', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await FirebaseFirestore.instance.collection('posts').doc(id).update({
        'status': 'archived',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip(this.status);

  @override
  Widget build(BuildContext context) {
    final config = {
      'published': {'label': 'منشور', 'color': Colors.green},
      'draft': {'label': 'مسودة', 'color': Colors.orange},
      'archived': {'label': 'مؤرشف', 'color': Colors.grey},
    }[status] ?? {'label': status, 'color': Colors.grey};

    return Chip(
      label: Text(config['label'] as String),
      backgroundColor: (config['color'] as Color).withOpacity(0.2),
      labelStyle: TextStyle(color: config['color'] as Color, fontSize: 12),
      visualDensity: VisualDensity.compact,
    );
  }
}