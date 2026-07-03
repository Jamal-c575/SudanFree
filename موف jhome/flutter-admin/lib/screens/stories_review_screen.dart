// lib/screens/stories_review_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:intl/intl.dart';

class StoriesReviewScreen extends ConsumerStatefulWidget {
  const StoriesReviewScreen({super.key});

  @override
  ConsumerState<StoriesReviewScreen> createState() => _StoriesReviewScreenState();
}

class _StoriesReviewScreenState extends ConsumerState<StoriesReviewScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('مراجعة قصص النجاح', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TabBar(controller: _tab, tabs: const [
            Tab(text: 'بانتظار المراجعة'),
            Tab(text: 'موافق عليها'),
            Tab(text: 'مرفوضة'),
          ]),
          Expanded(
            child: TabBarView(controller: _tab, children: const [
              _SubmissionsList(status: 'pending'),
              _SubmissionsList(status: 'approved'),
              _SubmissionsList(status: 'rejected'),
            ]),
          ),
        ],
      ),
    );
  }
}

class _SubmissionsList extends StatelessWidget {
  final String status;
  const _SubmissionsList({required this.status});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('storySubmissions')
          .where('status', isEqualTo: status)
          .orderBy('submittedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Center(child: Text('لا توجد قصص ${_statusLabel(status)}'));
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final doc = docs[i];
            final data = doc.data() as Map<String, dynamic>;
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(child: Text((data['submitterName'] ?? '؟')[0])),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(data['submitterName'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text(data['submitterEmail'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.white60)),
                            ],
                          ),
                        ),
                        Text(
                          DateFormat('yyyy-MM-dd HH:mm').format((data['submittedAt'] as Timestamp?)?.toDate() ?? DateTime.now()),
                          style: const TextStyle(fontSize: 12, color: Colors.white54),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(data['title'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
                      child: Text(data['story'] ?? '', maxLines: 5, overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(height: 8),
                    Chip(label: Text(data['category'] ?? 'عام')),
                    const SizedBox(height: 12),
                    if (status == 'pending')
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () => _reject(context, doc.id),
                            icon: const Icon(Icons.close, color: Colors.red),
                            label: const Text('رفض', style: TextStyle(color: Colors.red)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () => _approve(context, doc.id),
                            icon: const Icon(Icons.check),
                            label: const Text('موافقة ونشر'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _statusLabel(String s) => {'pending': 'بانتظار المراجعة', 'approved': 'موافق عليها', 'rejected': 'مرفوضة'}[s]!;

  Future<void> _approve(BuildContext context, String id) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (c) => const _ApproveDialog(),
    );
    if (result != true) return;
    try {
      await FirebaseFunctions.instance.httpsCallable('adminApproveStory').call({
        'submissionId': id,
        'publishNow': true,
      });
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ تمت الموافقة والنشر')));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
    }
  }

  Future<void> _reject(BuildContext context, String id) async {
    final notes = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('سبب الرفض'),
        content: TextField(controller: notes, decoration: const InputDecoration(labelText: 'ملاحظة للمرسل (اختياري)'), maxLines: 3),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('رفض', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await FirebaseFunctions.instance.httpsCallable('adminRejectStory').call({
        'submissionId': id,
        'notes': notes.text,
      });
    }
  }
}

class _ApproveDialog extends StatefulWidget {
  const _ApproveDialog();

  @override
  State<_ApproveDialog> createState() => _ApproveDialogState();
}

class _ApproveDialogState extends State<_ApproveDialog> {
  final _roleCtrl = TextEditingController(text: 'مستخدم SudFree');
  final _cityCtrl = TextEditingController();
  final _achieveCtrl = TextEditingController();
  final _metricValueCtrl = TextEditingController();
  final _metricLabelCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('بيانات إضافية للنشر'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _roleCtrl, decoration: const InputDecoration(labelText: 'دور/مهنة الشخص')),
            const SizedBox(height: 8),
            TextField(controller: _cityCtrl, decoration: const InputDecoration(labelText: 'المدينة')),
            const SizedBox(height: 8),
            TextField(controller: _achieveCtrl, decoration: const InputDecoration(labelText: 'الإنجاز الرئيسي')),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: TextField(controller: _metricValueCtrl, decoration: const InputDecoration(labelText: 'رقم'), keyboardType: TextInputType.number)),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: _metricLabelCtrl, decoration: const InputDecoration(labelText: 'وصف الرقم (مثلاً: عميل)'))),
            ]),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: () {
            // ترجيع البيانات عبر Navigator
            Navigator.pop(context, true);
          },
          child: const Text('نشر'),
        ),
      ],
    );
  }
}