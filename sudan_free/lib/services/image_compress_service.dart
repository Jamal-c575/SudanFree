import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

/// خدمة ضغط الصور قبل الرفع
/// تقلل حجم الصورة لتسريع الرفع وتوفير البيانات بشكل دراماتيكي بفضل واجهات Native
class ImageCompressService {
  /// ضغط صورة وإرجاع ملف جديد مضغوط
  static Future<File> compressImage(
    File file, {
    int maxWidth = 800,
    int quality = 75,
  }) async {
    try {
      final originalSize = await file.length();

      // If the file is already very small, skip compression
      if (originalSize < 200 * 1024) {
        return file;
      }

      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final targetPath = '${tempDir.path}/compressed_$timestamp.jpg';

      // Use flutter_image_compress for blazing fast native compression
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        minWidth: maxWidth,
        minHeight: maxWidth,
        quality: quality,
        format: CompressFormat.jpeg,
      );

      if (result == null) {
        debugPrint('ImageCompress: فشل في ضغط الصورة، سيتم استخدام الأصلية.');
        return file;
      }

      final compressedFile = File(result.path);
      final compressedSize = await compressedFile.length();
      final reduction = ((originalSize - compressedSize) / originalSize * 100).toStringAsFixed(1);
      
      debugPrint('ImageCompress (Native): $originalSize -> $compressedSize bytes ($reduction% reduction)');

      return compressedFile;
    } catch (e) {
      debugPrint('ImageCompress Error: $e');
      return file;
    }
  }

  static Future<bool> needsCompression(File file, {int maxSizeKB = 500}) async {
    final size = await file.length();
    return size > maxSizeKB * 1024;
  }

  static String getReadableFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
