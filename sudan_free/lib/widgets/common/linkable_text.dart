import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';

/// A text widget that auto-detects URLs and makes them tappable.
/// Use this anywhere you want links to be clickable in user-generated content.
class LinkableText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  /// Optional: additional styled spans (e.g. @mentions).
  /// If provided, URLs within those spans are also handled.
  final List<InlineSpan>? extraSpans;

  const LinkableText({
    super.key,
    required this.text,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
    this.extraSpans,
  });

  static final RegExp _urlRegex = RegExp(
    r'(?:https?://|www\.)[^\s<>\[\]{}|\\^`\u0600-\u06FF]+',
    caseSensitive: false,
  );

  static Future<void> _launchURL(String url) async {
    String finalUrl = url;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      finalUrl = 'https://$url';
    }
    final uri = Uri.parse(finalUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultStyle = style ?? TextStyle(
      fontSize: 14,
      height: 1.4,
      color: isDark ? Colors.white : Colors.black87,
    );
    final linkStyle = defaultStyle.copyWith(
      color: isDark ? const Color(0xFF64B5F6) : AppColors.primary,
      decoration: TextDecoration.underline,
      decorationColor: (isDark ? const Color(0xFF64B5F6) : AppColors.primary).withValues(alpha: 0.4),
    );

    final matches = _urlRegex.allMatches(text).toList();

    if (matches.isEmpty) {
      return Text(
        text,
        style: defaultStyle,
        maxLines: maxLines,
        overflow: overflow,
        textAlign: textAlign,
      );
    }

    final spans = <TextSpan>[];
    int lastEnd = 0;

    for (final match in matches) {
      // Add normal text before the URL
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, match.start)));
      }

      // Add the clickable URL
      final url = match.group(0)!;
      spans.add(TextSpan(
        text: url,
        style: linkStyle,
        recognizer: TapGestureRecognizer()..onTap = () => _launchURL(url),
      ));

      lastEnd = match.end;
    }

    // Add remaining text after last URL
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }

    return RichText(
      text: TextSpan(
        style: defaultStyle,
        children: spans,
      ),
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
      textAlign: textAlign ?? TextAlign.start,
    );
  }
}
