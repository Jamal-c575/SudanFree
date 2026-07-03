import 'package:flutter/material.dart';
import '../../services/error_service.dart';

/// مُعالج الأخطاء المركزي
/// يوفر طرقاً موحّدة لتسجيل الأخطاء وعرضها للمستخدم
class AppErrorHandler {
  static final ErrorService _errorService = ErrorService();

  /// تحويل رسائل Firebase/Firestore إلى رسائل عربية واضحة
  static String toArabic(dynamic error) {
    final msg = error.toString().toLowerCase();
    if (msg.contains('network') ||
        msg.contains('unavailable') ||
        msg.contains('timeout')) {
      return 'تعذّر الاتصال بالشبكة. تحقق من اتصالك بالإنترنت.';
    }
    if (msg.contains('permission') ||
        msg.contains('unauthorized') ||
        msg.contains('unauthenticated')) {
      return 'ليس لديك صلاحية لتنفيذ هذا الإجراء.';
    }
    if (msg.contains('not-found') || msg.contains('not found')) {
      return 'البيانات المطلوبة غير موجودة.';
    }
    if (msg.contains('already-exists') || msg.contains('duplicate')) {
      return 'هذا العنصر موجود مسبقاً.';
    }
    if (msg.contains('quota') || msg.contains('resource-exhausted')) {
      return 'تم تجاوز حد الاستخدام. يرجى المحاولة لاحقاً.';
    }
    if (msg.contains('cancelled') || msg.contains('canceled')) {
      return 'تم إلغاء العملية.';
    }
    if (msg.contains('invalid-argument') || msg.contains('invalid argument')) {
      return 'بيانات غير صحيحة. يرجى التحقق والمحاولة مرة أخرى.';
    }
    if (msg.contains('storage') || msg.contains('upload')) {
      return 'فشل رفع الملف. تحقق من حجم الملف واتصالك بالإنترنت.';
    }

    // Preserve custom Arabic exceptions
    final originalError = error.toString();
    final RegExp arabicRegex = RegExp(r'[\u0600-\u06FF]');
    if (arabicRegex.hasMatch(originalError)) {
      return originalError.replaceFirst('Exception: ', '').trim();
    }

    return 'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.';
  }

  /// تسجيل الخطأ في ErrorService (Firestore) + طباعة في debug
  static Future<void> log(
    dynamic error,
    StackTrace? stack, {
    required String context,
  }) async {
    debugPrint('[$context] Error: $error');
    try {
      await _errorService.logError(error, stack, context: context);
    } catch (_) {
      // تجنب الحلقة اللانهائية إذا فشل ErrorService نفسه
    }
  }

  /// تسجيل الخطأ + عرض SnackBar للمستخدم
  static Future<void> show(
    BuildContext context,
    dynamic error,
    StackTrace? stack, {
    required String logContext,
    String? customMessage,
    Color? color,
  }) async {
    await log(error, stack, context: logContext);

    if (!context.mounted) return;

    final message = customMessage ?? toArabic(error);

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
                child: Text(message, style: const TextStyle(fontSize: 13))),
          ],
        ),
        backgroundColor: color ?? Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// عرض رسالة نجاح للمستخدم
  static void showSuccess(BuildContext context, String message) {
    if (!context.mounted) return;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline,
                color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
                child: Text(message, style: const TextStyle(fontSize: 13))),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// تنفيذ عملية مع إعادة محاولة ذكية (Exponential Backoff)
  /// مفيد جداً في حالات ضعف الإنترنت
  static Future<T> executeWithRetry<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 2),
    String context = 'RetryOperation',
  }) async {
    int attempt = 0;
    while (true) {
      try {
        return await operation();
      } catch (e, stack) {
        attempt++;
        if (attempt >= maxRetries) {
          await log(e, stack, context: '$context (Failed after $maxRetries attempts)');
          rethrow;
        }
        
        final isNetworkError = e.toString().toLowerCase().contains('network') || 
                               e.toString().toLowerCase().contains('timeout') ||
                               e.toString().toLowerCase().contains('unavailable');
                               
        if (!isNetworkError) {
          // Do not retry non-network errors (e.g. invalid argument, permission denied)
          await log(e, stack, context: '$context (Non-retriable error)');
          rethrow;
        }

        // Exponential backoff
        final delay = initialDelay * attempt;
        debugPrint('[$context] Attempt $attempt failed, retrying in ${delay.inSeconds}s...');
        await Future.delayed(delay);
      }
    }
  }
}
