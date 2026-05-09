import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// خدمة رفع الصور إلى Cloudinary عبر HTTP مباشرة
/// أكثر موثوقية من cloudinary_public package
class CloudinaryService {
  static const String cloudName = 'dmuc5x843';
  static const String uploadPreset = 'Sudfree';
  static const int maxRetries = 3;

  static const String _uploadUrl =
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload';

  /// رفع صورة مع إعادة المحاولة
  Future<String?> uploadImage(File imageFile, {String? folder}) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        debugPrint('Cloudinary: محاولة $attempt/$maxRetries...');

        final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));
        request.fields['upload_preset'] = uploadPreset;
        if (folder != null) request.fields['folder'] = folder;

        request.files.add(
          await http.MultipartFile.fromPath('file', imageFile.path),
        );

        final streamedResponse = await request.send()
            .timeout(const Duration(seconds: 60));
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200) {
          final json = jsonDecode(response.body) as Map<String, dynamic>;
          final url = json['secure_url'] as String?;
          debugPrint('Cloudinary: ✅ تم الرفع → $url');
          return url;
        } else {
          debugPrint('Cloudinary: ❌ status ${response.statusCode} → ${response.body}');
        }
      } catch (e) {
        debugPrint('Cloudinary: ❌ محاولة $attempt فشلت → $e');
        if (attempt < maxRetries) {
          await Future.delayed(Duration(seconds: attempt));
        }
      }
    }
    debugPrint('Cloudinary: ❌ فشل بعد $maxRetries محاولات');
    return null;
  }

  /// رفع فيديو مع إعادة المحاولة
  Future<String?> uploadVideo(File videoFile, {String? folder}) async {
    const videoUrl =
        'https://api.cloudinary.com/v1_1/$cloudName/video/upload';

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        debugPrint('Cloudinary Video: محاولة $attempt/$maxRetries...');

        final request = http.MultipartRequest('POST', Uri.parse(videoUrl));
        request.fields['upload_preset'] = uploadPreset;
        if (folder != null) request.fields['folder'] = folder;

        request.files.add(
          await http.MultipartFile.fromPath('file', videoFile.path),
        );

        final streamedResponse = await request.send()
            .timeout(const Duration(seconds: 120));
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200) {
          final json = jsonDecode(response.body) as Map<String, dynamic>;
          final url = json['secure_url'] as String?;
          debugPrint('Cloudinary Video: ✅ → $url');
          return url;
        } else {
          debugPrint('Cloudinary Video: ❌ ${response.statusCode} → ${response.body}');
        }
      } catch (e) {
        debugPrint('Cloudinary Video: ❌ محاولة $attempt → $e');
        if (attempt < maxRetries) {
          await Future.delayed(Duration(seconds: attempt * 2));
        }
      }
    }
    return null;
  }

  /// تحسين رابط الصورة لتقليل حجم البيانات
  static String getOptimizedUrl(
    String url, {
    int? width,
    int? height,
    String quality = 'auto',
    List<String>? extraTransformations,
  }) {
    if (url.isEmpty || !url.contains('cloudinary.com')) return url;
    if (url.contains('/q_$quality,f_auto')) return url;

    try {
      final uri = Uri.parse(url);
      final pathSegments = List<String>.from(uri.pathSegments);
      final uploadIndex = pathSegments.indexOf('upload');
      if (uploadIndex == -1) return url;

      final transformations = <String>[];
      if (width != null) transformations.add('w_$width');
      if (height != null) transformations.add('h_$height');
      if (width != null || height != null) transformations.add('c_limit');
      transformations.add('q_$quality');
      transformations.add('f_auto');
      if (extraTransformations != null) {
        transformations.addAll(extraTransformations);
      }

      pathSegments.insert(uploadIndex + 1, transformations.join(','));
      return uri.replace(pathSegments: pathSegments).toString();
    } catch (_) {
      return url;
    }
  }
}
