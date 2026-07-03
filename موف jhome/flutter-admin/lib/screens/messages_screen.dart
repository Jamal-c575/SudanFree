// lib/screens/messages_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:intl/intl.dart';

class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('رسائل التواصل', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('contactMessages').orderBy('receivedAt', descending: true).snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snap.data!.docs;
                if (docs.isEmpty) return const Center(child: Text('لا توجد رسائل'));

                return Row(
                  children: [
                    SizedBox(
                      width: 360,
                      child: ListView.separated(
                        itemCount: docs.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final data = docs[i].data() as Map<String, dynamic>;
                          final id = docs[i].id;
                          return _MessageListItem(data: data, id: id);
                        },
                      ),
                    ),
                    const VerticalDivider(width: 1),
                    const Expanded(child: Center(child: Text('اختر رسالة لعرضها'))),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageListItem extends StatelessWidget {
  final Map<String, dynamic> data;
  final String id;
  const _MessageListItem({required this.data, required this.id});

  @override
  Widget build(BuildContext context) {
    final isNew = (data['status'] ?? 'new') == 'new';
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isNew ? Colors.pink : Colors.grey,
        child: Text((data['name'] ?? '؟')[0].toUpperCase()),
      ),
      title: Text(data['name'] ?? '', style: TextStyle(fontWeight: isNew ? FontWeight.bold : FontWeight.normal)),
      subtitle: Text(data['subject'] ?? data['message']?.toString().substring(0, 40) ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Text(
        DateFormat('MM-dd').format((data['receivedAt'] as Timestamp?)?.toDate() ?? DateTime.now()),
        style: const TextStyle(fontSize: 12, color: Colors.white54),
      ),
      onTap: () async {
        if (isNew) {
          await FirebaseFunctions.instance.httpsCallable('adminMarkMessageRead').call({'messageId': id, 'status': 'read'});
        }
        // افتح التفاصيل
        if (context.mounted) _showMessageDialog(context, data, id);
      },
    );
  }

  void _showMessageDialog(BuildContext context, Map<String, dynamic> data, String id) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(data['subject'] ?? 'بدون موضوع'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('من: ${data['name']} (${data['email']})'),
              if (data['phone'] != null && data['phone'].toString().isNotEmpty) Text('الهاتف: ${data['phone']}'),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              Text(data['message'] ?? ''),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('إغلاق')),
          TextButton(
            onPressed: () async {
              await FirebaseFunctions.instance.httpsCallable('adminMarkMessageRead').call({'messageId': id, 'status': 'replied'});
              if (c.mounted) Navigator.pop(c);
            },
            child: const Text('وضع كـ "تم الرد"'),
          ),
        ],
      ),
    );
  }
}