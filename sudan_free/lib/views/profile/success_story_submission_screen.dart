import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/glass_container.dart';

class SuccessStorySubmissionScreen extends StatefulWidget {
  const SuccessStorySubmissionScreen({Key? key}) : super(key: key);

  @override
  _SuccessStorySubmissionScreenState createState() => _SuccessStorySubmissionScreenState();
}

class _SuccessStorySubmissionScreenState extends State<SuccessStorySubmissionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submitStory() async {
    if (!_formKey.currentState!.validate()) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يجب تسجيل الدخول أولاً')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('success_stories').add({
        'userId': user.id,
        'userName': user.name,
        'userImage': user.profileImageUrl ?? '',
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'imageUrl': null, // Can be extended for image uploads
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إرسال قصتك بنجاح! سيتم مراجعتها قريباً من الإدارة.', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء الإرسال: $e', style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('قصة نجاحك'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GlassContainer(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(Icons.emoji_events, size: 64, color: Colors.amber),
                  const SizedBox(height: 16),
                  const Text(
                    'شارك قصة نجاحك مع مجتمع سودان فري!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'قصتك قد تكون مصدر إلهام للآلاف من الحرفيين والمستخدمين، شاركنا تفاصيل نجاحك وتجربتك.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            GlassContainer(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'عنوان القصة',
                        labelStyle: TextStyle(color: Colors.grey.shade400),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.teal),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (val) => (val == null || val.isEmpty) ? 'الرجاء إدخال عنوان القصة' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _contentController,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 8,
                      decoration: InputDecoration(
                        labelText: 'تفاصيل القصة',
                        alignLabelWithHint: true,
                        labelStyle: TextStyle(color: Colors.grey.shade400),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.teal),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (val) => (val == null || val.isEmpty) ? 'الرجاء كتابة تفاصيل قصتك' : null,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitStory,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('إرسال القصة للمراجعة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
