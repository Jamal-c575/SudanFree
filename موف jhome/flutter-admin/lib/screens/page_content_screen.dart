// lib/screens/page_content_screen.dart
// تعديل محتوى صفحات الموقع (Hero, About, Contact, Social)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

class PageContentScreen extends ConsumerStatefulWidget {
  const PageContentScreen({super.key});
  @override
  ConsumerState<PageContentScreen> createState() => _PageContentScreenState();
}

class _PageContentScreenState extends ConsumerState<PageContentScreen> {
  String _pageKey = 'home';
  final _heroTitle = TextEditingController();
  final _heroSubtitle = TextEditingController();
  final _primaryBtnText = TextEditingController();
  final _primaryBtnLink = TextEditingController();
  final _secondaryBtnText = TextEditingController();
  final _secondaryBtnLink = TextEditingController();
  final _aboutText = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _whatsapp = TextEditingController();
  final _address = TextEditingController();
  final _facebook = TextEditingController();
  final _twitter = TextEditingController();
  final _instagram = TextEditingController();
  final _youtube = TextEditingController();
  final _telegram = TextEditingController();
  final _tiktok = TextEditingController();

  bool _loading = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final doc = await FirebaseFirestore.instance.collection('pageContent').doc(_pageKey).get();
    if (doc.exists) {
      final data = doc.data()!;
      final sections = data['sections'] as Map<String, dynamic>? ?? {};
      final hero = sections['hero'] as Map<String, dynamic>? ?? {};
      final about = sections['about'] as Map<String, dynamic>? ?? {};
      final contact = sections['contact'] as Map<String, dynamic>? ?? {};
      final social = sections['social'] as Map<String, dynamic>? ?? {};

      _heroTitle.text = hero['title'] ?? '';
      _heroSubtitle.text = hero['subtitle'] ?? '';
      _primaryBtnText.text = hero['primaryButtonText'] ?? '';
      _primaryBtnLink.text = hero['primaryButtonLink'] ?? '';
      _secondaryBtnText.text = hero['secondaryButtonText'] ?? '';
      _secondaryBtnLink.text = hero['secondaryButtonLink'] ?? '';
      _aboutText.text = about['content'] ?? '';
      _email.text = contact['email'] ?? '';
      _phone.text = contact['phone'] ?? '';
      _whatsapp.text = contact['whatsapp'] ?? '';
      _address.text = contact['address'] ?? '';
      _facebook.text = social['facebook'] ?? '';
      _twitter.text = social['twitter'] ?? '';
      _instagram.text = social['instagram'] ?? '';
      _youtube.text = social['youtube'] ?? '';
      _telegram.text = social['telegram'] ?? '';
      _tiktok.text = social['tiktok'] ?? '';
    }
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final sections = {
        'hero': {
          'title': _heroTitle.text,
          'subtitle': _heroSubtitle.text,
          'primaryButtonText': _primaryBtnText.text,
          'primaryButtonLink': _primaryBtnLink.text,
          'secondaryButtonText': _secondaryBtnText.text,
          'secondaryButtonLink': _secondaryBtnLink.text,
        },
        'about': {'content': _aboutText.text},
        'contact': {
          'email': _email.text,
          'phone': _phone.text,
          'whatsapp': _whatsapp.text,
          'address': _address.text,
        },
        'social': {
          'facebook': _facebook.text,
          'twitter': _twitter.text,
          'instagram': _instagram.text,
          'youtube': _youtube.text,
          'telegram': _telegram.text,
          'tiktok': _tiktok.text,
        },
      };

      await FirebaseFunctions.instance.httpsCallable('adminUpdatePageContent').call({
        'pageKey': _pageKey,
        'sections': sections,
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ تم الحفظ')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('محتوى الصفحات', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        DropdownButton<String>(
                          value: _pageKey,
                          items: const [
                            DropdownMenuItem(value: 'home', child: Text('الرئيسية')),
                            DropdownMenuItem(value: 'about', child: Text('من نحن')),
                            DropdownMenuItem(value: 'contact', child: Text('تواصل معنا')),
                          ],
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => _pageKey = v);
                              _load();
                            }
                          },
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: _saving ? null : _save,
                          icon: const Icon(Icons.save),
                          label: const Text('حفظ'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _Section('قسم Hero (الواجهة الرئيسية)', [
                      TextField(controller: _heroTitle, decoration: const InputDecoration(labelText: 'العنوان الرئيسي')),
                      const SizedBox(height: 8),
                      TextField(controller: _heroSubtitle, maxLines: 2, decoration: const InputDecoration(labelText: 'العنوان الفرعي')),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(child: TextField(controller: _primaryBtnText, decoration: const InputDecoration(labelText: 'نص الزر الأول'))),
                        const SizedBox(width: 8),
                        Expanded(child: TextField(controller: _primaryBtnLink, decoration: const InputDecoration(labelText: 'رابط الزر الأول'))),
                      ]),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(child: TextField(controller: _secondaryBtnText, decoration: const InputDecoration(labelText: 'نص الزر الثاني'))),
                        const SizedBox(width: 8),
                        Expanded(child: TextField(controller: _secondaryBtnLink, decoration: const InputDecoration(labelText: 'رابط الزر الثاني'))),
                      ]),
                    ]),
                    const SizedBox(height: 16),
                    _Section('من نحن', [
                      TextField(controller: _aboutText, maxLines: 5, decoration: const InputDecoration(labelText: 'النص')),
                    ]),
                    const SizedBox(height: 16),
                    _Section('التواصل', [
                      TextField(controller: _email, decoration: const InputDecoration(labelText: 'البريد')),
                      const SizedBox(height: 8),
                      TextField(controller: _phone, decoration: const InputDecoration(labelText: 'الهاتف')),
                      const SizedBox(height: 8),
                      TextField(controller: _whatsapp, decoration: const InputDecoration(labelText: 'واتساب')),
                      const SizedBox(height: 8),
                      TextField(controller: _address, decoration: const InputDecoration(labelText: 'العنوان')),
                    ]),
                    const SizedBox(height: 16),
                    _Section('السوشيال ميديا', [
                      TextField(controller: _facebook, decoration: const InputDecoration(labelText: 'Facebook URL')),
                      const SizedBox(height: 8),
                      TextField(controller: _twitter, decoration: const InputDecoration(labelText: 'Twitter/X URL')),
                      const SizedBox(height: 8),
                      TextField(controller: _instagram, decoration: const InputDecoration(labelText: 'Instagram URL')),
                      const SizedBox(height: 8),
                      TextField(controller: _youtube, decoration: const InputDecoration(labelText: 'YouTube URL')),
                      const SizedBox(height: 8),
                      TextField(controller: _telegram, decoration: const InputDecoration(labelText: 'Telegram URL')),
                      const SizedBox(height: 8),
                      TextField(controller: _tiktok, decoration: const InputDecoration(labelText: 'TikTok URL')),
                    ]),
                  ],
                ),
              ),
            ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section(this.title, this.children);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}