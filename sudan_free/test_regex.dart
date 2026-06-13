void main() {
  final RegExp _entityRegex = RegExp(
    r'((?:https?:\/\/|www\.)[^\s\u0600-\u06FF()<>]+|\b[a-zA-Z0-9-]+\.[a-zA-Z]{2,}(?:\/[^\s\u0600-\u06FF()<>]*)?)|(#[\w\u0600-\u06FF]+)|(@[\w\u0600-\u06FF]+)',
    caseSensitive: false,
  );
  final text = "مرحبا sudanfree.com";
  final matches = _entityRegex.allMatches(text).toList();
  print(matches.length);
}
