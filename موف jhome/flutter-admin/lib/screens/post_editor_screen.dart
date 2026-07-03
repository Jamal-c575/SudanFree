// lib/screens/post_editor_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:go_router/go_router.dart';

class PostEditorScreen extends ConsumerStatefulWidget {
  final String? postId;
  const PostEditorScreen({this.postId, super.key});

  @override
  ConsumerState<PostEditorScreen> createState() => _PostEditorScreenState();
}

class _PostEditorScreenState extends ConsumerState<PostEditorScreen> {
  final _titleCtrl = TextEditingController();
  final _excerptCtrl = TextEditingController();
  final _seoTitleCtrl = TextEditingController();
  final _seoDescCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();
  final _coverUrlCtrl = TextEditingController();

  quill.QuillController? _quillCtrl;
  String _category = 'تقنية';
  String _status = 'draft';
  bool _isFeatured = false;
  String _language = 'ar';
  bool _saving = false;
  bool _loading = true;
  String? _existingId;

  final _categories = ['تقنية', 'أخبار', 'رؤية', 'قصص نجاح', 'إعمار', 'عام'];

  @override
  void initState() {
    super.initState();
    _quillCtrl = quill.QuillController.basic();
    if (widget.postId != null) {
      _loadExisting();
    } else {
      _loading = false;
    }
  }

  Future<void> _loadExisting() async {
    final doc = await FirebaseFirestore.instance.collection('posts').doc(widget.postId).get();
    if (!doc.exists) {
      setState(() => _loading = false);
      return;
    }
    final data = doc.data()!;
    _existingId = doc.id;
    _titleCtrl.text = data['title'] ?? '';
    _excerptCtrl.text = data['excerpt'] ?? '';
    _seoTitleCtrl.text = data['seoTitle'] ?? '';
    _seoDescCtrl.text = data['seoDescription'] ?? '';
    _tagsCtrl.text = (data['tags'] as List?)?.join(', ') ?? '';
    _coverUrlCtrl.text = data['coverImage'] ?? '';
    _category = data['category'] ?? 'تقنية';
    _status = data['status'] ?? 'draft';
    _isFeatured = data['isFeatured'] ?? false;
    _language = data['language'] ?? 'ar';

    if (data['content'] != null && (data['content'] as String).isNotEmpty) {
      try {
        final doc = quill.Document()..insert(0, data['content']);
        _quillCtrl = quill.QuillController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
        );
      } catch (_) {
        // لو المحتوى ليس Delta، تجاهل
      }
    }
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _excerptCtrl.dispose();
    _seoTitleCtrl.dispose();
    _seoDescCtrl.dispose();
    _tagsCtrl.dispose();
    _coverUrlCtrl.dispose();
    _quillCtrl?.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadCover() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result == null) return;
    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) return;

    final fileName = 'posts/${DateTime.now().millisecondsSinceEpoch}_${file.name}';
    final ref = FirebaseStorage.instance.ref().child(fileName);
    await ref.putData(bytes);
    final url = await ref.getDownloadURL();
    setState(() => _coverUrlCtrl.text = url);
  }

  Future<void> _save({bool publish = false}) async {
    if (_titleCtrl.text.trim().isEmpty) {
      _toast('أدخل عنوان المقال');
      return;
    }
    setState(() => _saving = true);

    try {
      // تحويل محتوى Quill إلى HTML
      final html = _quillCtrl!.document.toPlainText().trim();

      final tags = _tagsCtrl.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      final data = {
        'title': _titleCtrl.text.trim(),
        'excerpt': _excerptCtrl.text.trim(),
        'content': html,
        'coverImage': _coverUrlCtrl.text.trim(),
        'category': _category,
        'tags': tags,
        'status': publish ? 'published' : _status,
        'isFeatured': _isFeatured,
        'language': _language,
        'seoTitle': _seoTitleCtrl.text.trim(),
        'seoDescription': _seoDescCtrl.text.trim(),
      };

      final functions = FirebaseFunctions.instance;
      if (_existingId != null) {
        await functions.httpsCallable('adminUpdatePost').call({'postId': _existingId, ...data});
      } else {
        final res = await functions.httpsCallable('adminCreatePost').call(data);
        _existingId = res.data['id'];
      }

      _toast(publish ? '✅ تم النشر بنجاح' : '✅ تم الحفظ');
      if (mounted && publish) context.go('/posts');
    } catch (e) {
      _toast('خطأ: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(onPressed: () => context.go('/posts'), icon: const Icon(Icons.arrow_back)),
                  const Text('محرر المقال', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: _saving ? null : () => _save(publish: false),
                    icon: const Icon(Icons.save),
                    label: const Text('حفظ كمسودة'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _saving ? null : () => _save(publish: true),
                    icon: const Icon(Icons.publish),
                    label: Text(_status == 'published' ? 'تحديث المنشور' : 'نشر'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              LayoutBuilder(builder: (context, c) {
                final isWide = c.maxWidth > 900;
                final form = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'عنوان المقال *'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    const Text('المحتوى', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (_quillCtrl != null)
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white24),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            quill.QuillSimpleToolbar(controller: _quillCtrl!, config: const quill.QuillSimpleToolbarConfig(multiRowsDisplay: false)),
                            Container(height: 400, padding: const EdgeInsets.all(16), child: quill.QuillEditor.basic(controller: _quillCtrl!)),
                          ],
                        ),
                      ),
                  ],
                );
                final sidebar = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(controller: _excerptCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'ملخص قصير (يظهر في القوائم)')),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _category,
                      decoration: const InputDecoration(labelText: 'التصنيف'),
                      items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (v) => setState(() => _category = v ?? 'عام'),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _language,
                      decoration: const InputDecoration(labelText: 'اللغة'),
                      items: const [
                        DropdownMenuItem(value: 'ar', child: Text('العربية')),
                        DropdownMenuItem(value: 'en', child: Text('English')),
                      ],
                      onChanged: (v) => setState(() => _language = v ?? 'ar'),
                    ),
                    const SizedBox(height: 16),
                    TextField(controller: _tagsCtrl, decoration: const InputDecoration(labelText: 'الكلمات المفتاحية (مفصولة بفاصلة)')),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(child: TextField(controller: _coverUrlCtrl, decoration: const InputDecoration(labelText: 'رابط صورة الغلاف'))),
                      IconButton(onPressed: _pickAndUploadCover, icon: const Icon(Icons.upload)),
                    ]),
                    if (_coverUrlCtrl.text.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(_coverUrlCtrl.text, height: 120, fit: BoxFit.cover)),
                    ],
                    const SizedBox(height: 16),
                    SwitchListTile(title: const Text('مقال مميز (يظهر في الرئيسية)'), value: _isFeatured, onChanged: (v) => setState(() => _isFeatured = v)),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text('SEO', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(controller: _seoTitleCtrl, decoration: const InputDecoration(labelText: 'عنوان SEO')),
                    const SizedBox(height: 8),
                    TextField(controller: _seoDescCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'وصف SEO')),
                  ],
                );

                if (!isWide) {
                  return Column(children: [form, const SizedBox(height: 24), sidebar]);
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: form),
                    const SizedBox(width: 24),
                    SizedBox(width: 320, child: sidebar),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}