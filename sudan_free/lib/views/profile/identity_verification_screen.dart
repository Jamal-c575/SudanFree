import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/common/glass_container.dart';

class IdentityVerificationScreen extends StatefulWidget {
  const IdentityVerificationScreen({super.key});

  @override
  State<IdentityVerificationScreen> createState() => _IdentityVerificationScreenState();
}

class _IdentityVerificationScreenState extends State<IdentityVerificationScreen> {
  File? _idCardImage;
  File? _selfieImage;
  bool _isSubmitting = false;
  String? _errorMessage;

  Future<void> _pickImage(bool isIdCard) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: isIdCard ? ImageSource.gallery : ImageSource.camera,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() {
        if (isIdCard) {
          _idCardImage = File(picked.path);
        } else {
          _selfieImage = File(picked.path);
        }
      });
    }
  }

  Future<String?> _uploadImage(File file, String path) async {
    final ref = FirebaseStorage.instance.ref().child(path);
    final task = await ref.putFile(file);
    return await task.ref.getDownloadURL();
  }

  Future<void> _submit() async {
    if (_idCardImage == null || _selfieImage == null) {
      setState(() => _errorMessage = 'يرجى رفع صورة الهوية والصورة الشخصية');
      return;
    }

    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    setState(() { _isSubmitting = true; _errorMessage = null; });

    try {
      final idUrl = await _uploadImage(
        _idCardImage!,
        'verification/${user.id}/id_card_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      final selfieUrl = await _uploadImage(
        _selfieImage!,
        'verification/${user.id}/selfie_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      // Create verification request
      await FirebaseFirestore.instance.collection('verification_requests').add({
        'userId': user.id,
        'userName': user.name,
        'idCardUrl': idUrl,
        'selfieUrl': selfieUrl,
        'status': 'pending',
        'submittedAt': FieldValue.serverTimestamp(),
        'type': 'identity',
      });

      // Update user document
      await FirebaseFirestore.instance.collection('users').doc(user.id).update({
        'verificationStatus': 'pending',
        'idCardUrl': idUrl,
        'verificationSelfieUrl': selfieUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إرسال طلب التحقق بنجاح! سيتم المراجعة خلال 24 ساعة.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) setState(() { _errorMessage = 'حدث خطأ: $e'; _isSubmitting = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.watch<LocaleProvider>().isArabic;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'تحقق الهوية' : 'Identity Verification'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header badge
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1a6b6b), Color(0xFF0d3d3d)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(Icons.handshake_rounded, color: Colors.white, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    isAr ? 'احصل على شارة "موثق ✓"' : 'Get the "Verified ✓" Badge',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isAr
                        ? 'يزيد الحرفيون الموثقون من ثقة العملاء ويحصلون على فرص أكثر'
                        : 'Verified freelancers gain more client trust and opportunities',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Text(
              isAr ? 'الخطوات المطلوبة:' : 'Required Steps:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
            ),
            const SizedBox(height: 16),

            // Step 1: ID Card
            _buildUploadCard(
              context: context,
              icon: Icons.badge,
              title: isAr ? '1. صورة الهوية الوطنية' : '1. National ID Card',
              subtitle: isAr ? 'صورة واضحة للوجه الأمامي من الهوية' : 'Clear photo of the front of your ID',
              image: _idCardImage,
              onTap: () => _pickImage(true),
              isAr: isAr,
            ),

            const SizedBox(height: 16),

            // Step 2: Selfie
            _buildUploadCard(
              context: context,
              icon: Icons.face,
              title: isAr ? '2. صورة شخصية (سيلفي)' : '2. Personal Selfie',
              subtitle: isAr ? 'صورة واضحة لوجهك مع الهوية بجانبك' : 'Clear photo of your face holding your ID',
              image: _selfieImage,
              onTap: () => _pickImage(false),
              isAr: isAr,
            ),

            const SizedBox(height: 24),

            // Privacy note
            GlassContainer(
              borderRadius: BorderRadius.circular(12),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.lock, color: Colors.green, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isAr
                          ? 'بياناتك محمية ولن تُشارك مع أي طرف ثالث. تُستخدم فقط للتحقق من هويتك.'
                          : 'Your data is protected and will not be shared with any third party.',
                      style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                    ),
                  ),
                ],
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            ],

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1a6b6b),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        isAr ? 'إرسال للمراجعة' : 'Submit for Review',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required File? image,
    required VoidCallback onTap,
    required bool isAr,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        borderRadius: BorderRadius.circular(16),
        padding: const EdgeInsets.all(16),
        enableBlur: true,
        child: Row(
          children: [
            if (image != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(image, width: 70, height: 70, fit: BoxFit.cover),
              )
            else
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: const Color(0xFF1a6b6b).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF1a6b6b).withValues(alpha: 0.5), style: BorderStyle.solid),
                ),
                child: Icon(icon, color: const Color(0xFF1a6b6b), size: 32),
              ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  const SizedBox(height: 8),
                  Text(
                    image != null ? (isAr ? '✓ تم الرفع' : '✓ Uploaded') : (isAr ? 'اضغط للرفع' : 'Tap to upload'),
                    style: TextStyle(
                      fontSize: 12,
                      color: image != null ? Colors.green : const Color(0xFF1a6b6b),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              image != null ? Icons.check_circle : Icons.add_a_photo,
              color: image != null ? Colors.green : const Color(0xFF1a6b6b),
            ),
          ],
        ),
      ),
    );
  }
}
