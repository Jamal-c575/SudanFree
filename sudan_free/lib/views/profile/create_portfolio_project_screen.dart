import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/portfolio_project_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../providers/locale_provider.dart';

class CreatePortfolioProjectScreen extends StatefulWidget {
  const CreatePortfolioProjectScreen({super.key});

  @override
  State<CreatePortfolioProjectScreen> createState() => _CreatePortfolioProjectScreenState();
}

class _CreatePortfolioProjectScreenState extends State<CreatePortfolioProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedCategory;
  final List<File> _selectedImages = [];
  bool _isLoading = false;
  String _loadingStatus = '';

  static const int _maxImages = 5;

  // Category options with icons and colors
  static const List<Map<String, dynamic>> _categories = [
    {'key': 'design', 'ar': 'تصميم', 'en': 'Design', 'icon': Icons.palette, 'color': Color(0xFF6c5ce7)},
    {'key': 'programming', 'ar': 'برمجة', 'en': 'Programming', 'icon': Icons.code, 'color': Color(0xFF0984e3)},
    {'key': 'maintenance', 'ar': 'صيانة', 'en': 'Maintenance', 'icon': Icons.build, 'color': Color(0xFFe17055)},
    {'key': 'construction', 'ar': 'بناء وتشييد', 'en': 'Construction', 'icon': Icons.construction, 'color': Color(0xFF00b894)},
    {'key': 'electrical', 'ar': 'كهرباء', 'en': 'Electrical', 'icon': Icons.electric_bolt, 'color': Color(0xFFfdcb6e)},
    {'key': 'plumbing', 'ar': 'سباكة', 'en': 'Plumbing', 'icon': Icons.plumbing, 'color': Color(0xFF00cec9)},
    {'key': 'painting', 'ar': 'دهان وطلاء', 'en': 'Painting', 'icon': Icons.format_paint, 'color': Color(0xFFa29bfe)},
    {'key': 'carpentry', 'ar': 'نجارة', 'en': 'Carpentry', 'icon': Icons.carpenter, 'color': Color(0xFF636e72)},
    {'key': 'other', 'ar': 'أخرى', 'en': 'Other', 'icon': Icons.category, 'color': Color(0xFF74b9ff)},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _l(BuildContext ctx) => ctx.read<LocaleProvider>().locale.languageCode;
  bool _isAr(BuildContext ctx) => ctx.read<LocaleProvider>().isArabic;

  Future<void> _pickImages() async {
    final remaining = _maxImages - _selectedImages.length;
    if (remaining <= 0) return;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2))),
            ListTile(
              leading: Container(padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.photo_library_outlined, color: AppColors.primary)),
              title: Text(_isAr(context) ? 'المعرض' : 'Gallery'),
              subtitle: Text(_isAr(context) ? 'اختر عدة صور' : 'Pick multiple', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: Container(padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.camera_alt_outlined, color: Colors.orange)),
              title: Text(_isAr(context) ? 'الكاميرا' : 'Camera'),
              subtitle: Text(_isAr(context) ? 'التقط صورة' : 'Take a photo', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ]),
        ),
      ),
    );
    if (source == null) return;

    final picker = ImagePicker();
    if (source == ImageSource.camera) {
      final image = await picker.pickImage(source: ImageSource.camera, imageQuality: 70, maxWidth: 1200);
      if (image != null && mounted) setState(() => _selectedImages.add(File(image.path)));
    } else {
      final images = await picker.pickMultiImage(imageQuality: 70, maxWidth: 1200);
      if (images.isNotEmpty && mounted) {
        setState(() => _selectedImages.addAll(images.take(remaining).map((img) => File(img.path))));
      }
    }
  }

  Future<void> _submitProject() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isAr(context) ? 'يرجى إضافة صورة واحدة على الأقل' : 'Please add at least one image'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    setState(() { _isLoading = true; _loadingStatus = _isAr(context) ? 'جاري رفع الصور...' : 'Uploading images...'; });

    try {
      final List<String> uploadedUrls = [];
      for (int i = 0; i < _selectedImages.length; i++) {
        setState(() => _loadingStatus = _isAr(context)
            ? 'رفع صورة ${i + 1} من ${_selectedImages.length}...'
            : 'Uploading image ${i + 1} of ${_selectedImages.length}...');
        final url = await StorageService().uploadImage(
          _selectedImages[i],
          folder: 'portfolio/${user.id}/${DateTime.now().millisecondsSinceEpoch}',
        );
        if (url != null) uploadedUrls.add(url);
      }

      setState(() => _loadingStatus = _isAr(context) ? 'جاري حفظ المشروع...' : 'Saving project...');

      final project = PortfolioProjectModel(
        id: '',
        userId: user.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        imageUrls: uploadedUrls,
        createdAt: DateTime.now(),
      );

      await FirestoreService().addPortfolioProject(project);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isAr(context) ? 'تمت إضافة المشروع بنجاح! ✅' : 'Project added successfully! ✅'),
          backgroundColor: AppColors.success,
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${_isAr(context) ? "خطأ" : "Error"}: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() { _isLoading = false; _loadingStatus = ''; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = _isAr(context);
    final locale = _l(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'إضافة مشروع منجز' : 'Add Completed Project'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Loading overlay
          if (_isLoading)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: AppColors.primary.withValues(alpha: 0.1),
              child: Row(children: [
                const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                const SizedBox(width: 12),
                Expanded(child: Text(_loadingStatus, style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600))),
              ]),
            ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── Title ───
                    _buildSectionLabel(isArabic ? 'عنوان المشروع' : 'Project Title', Icons.title),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _titleController,
                      decoration: _inputDecoration(
                        hint: isArabic ? 'مثال: تركيب نظام كهرباء لمنزل' : 'e.g. Home electrical system installation',
                        icon: Icons.edit,
                        isDark: isDark,
                      ),
                      validator: (v) => v == null || v.isEmpty ? (isArabic ? 'مطلوب' : 'Required') : null,
                    ),

                    const SizedBox(height: 20),

                    // ─── Category Chips ───
                    _buildSectionLabel(isArabic ? 'تصنيف المشروع' : 'Project Category', Icons.category),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _categories.map((cat) {
                        final isSelected = _selectedCategory == cat['key'];
                        final Color color = cat['color'];
                        return GestureDetector(
                          onTap: () => setState(() => _selectedCategory = isSelected ? null : cat['key']),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? color : color.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: isSelected ? color : color.withValues(alpha: 0.3)),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(cat['icon'] as IconData, size: 16, color: isSelected ? Colors.white : color),
                              const SizedBox(width: 6),
                              Text(
                                locale == 'ar' ? cat['ar'] : cat['en'],
                                style: TextStyle(
                                  color: isSelected ? Colors.white : color,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ]),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20),

                    // ─── Description ───
                    _buildSectionLabel(isArabic ? 'وصف المشروع' : 'Project Description', Icons.description),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: _inputDecoration(
                        hint: isArabic ? 'اكتب تفاصيل عن المشروع وما قمت بإنجازه...' : 'Write details about your project...',
                        isDark: isDark,
                      ),
                      validator: (v) => v == null || v.isEmpty ? (isArabic ? 'مطلوب' : 'Required') : null,
                    ),

                    const SizedBox(height: 20),

                    // ─── Images Section ───
                    Row(
                      children: [
                        _buildSectionLabel(isArabic ? 'صور المشروع' : 'Project Images', Icons.photo_library),
                        const Spacer(),
                        Text('${_selectedImages.length}/$_maxImages',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold,
                            color: _selectedImages.length >= _maxImages ? Colors.orange : AppColors.primary)),
                      ],
                    ),
                    const SizedBox(height: 10),

                    if (_selectedImages.isNotEmpty)
                      SizedBox(
                        height: 110,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedImages.length + (_selectedImages.length < _maxImages ? 1 : 0),
                          itemBuilder: (ctx, i) {
                            if (i == _selectedImages.length) {
                              return GestureDetector(
                                onTap: _pickImages,
                                child: Container(
                                  width: 100, height: 110,
                                  margin: const EdgeInsets.only(left: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.06),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), style: BorderStyle.solid),
                                  ),
                                  child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                    Icon(Icons.add_photo_alternate, color: AppColors.primary, size: 28),
                                    SizedBox(height: 4),
                                    Text('+', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                                  ]),
                                ),
                              );
                            }
                            return Stack(children: [
                              Container(
                                width: 110, height: 110,
                                margin: const EdgeInsets.only(left: 8),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.file(_selectedImages[i], fit: BoxFit.cover),
                                ),
                              ),
                              Positioned(top: 4, right: 4,
                                child: GestureDetector(
                                  onTap: () => setState(() => _selectedImages.removeAt(i)),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.85), shape: BoxShape.circle),
                                    child: const Icon(Icons.close, color: Colors.white, size: 14),
                                  ),
                                ),
                              ),
                            ]);
                          },
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: _pickImages,
                        child: Container(
                          width: double.infinity, height: 130,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.25), style: BorderStyle.solid),
                          ),
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                              child: const Icon(Icons.cloud_upload_outlined, size: 32, color: AppColors.primary),
                            ),
                            const SizedBox(height: 10),
                            Text(isArabic ? 'اضغط لإضافة صور المشروع' : 'Tap to add project images',
                              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text(isArabic ? 'حد أقصى $_maxImages صور' : 'Maximum $_maxImages images',
                              style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                          ]),
                        ),
                      ),

                    const SizedBox(height: 32),

                    // ─── Submit Button ───
                    SizedBox(
                      width: double.infinity,
                      child: GestureDetector(
                        onTap: _isLoading ? null : _submitProject,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF5f3dc4)]),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
                          ),
                          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(_isLoading ? null : Icons.rocket_launch, color: Colors.white, size: 20),
                            const SizedBox(width: 10),
                            Text(
                              isArabic ? 'نشر المشروع' : 'Publish Project',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ]),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text, IconData icon) {
    return Row(children: [
      Icon(icon, size: 18, color: AppColors.primary),
      const SizedBox(width: 8),
      Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
    ]);
  }

  InputDecoration _inputDecoration({required String hint, IconData? icon, required bool isDark}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
      prefixIcon: icon != null ? Icon(icon, color: AppColors.primary, size: 20) : null,
      filled: true,
      fillColor: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.withValues(alpha: 0.06),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
