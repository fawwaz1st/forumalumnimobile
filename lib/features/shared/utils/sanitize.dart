// Very lightweight sanitization helpers for user-provided text/markdown.
// Note: This is client-side best-effort; always revalidate on the server.

final _htmlTagRegex = RegExp(r"<[^>]+>", multiLine: true, caseSensitive: false);
final _scriptLikeRegex = RegExp(r"(javascript:|data:text/html|onerror=|onload=|<script|</script)", caseSensitive: false);
final _multipleSpaces = RegExp(r"\s{2,}");

String sanitizeText(String input) {
  if (input.isEmpty) return input;
  var s = input.replaceAll(_htmlTagRegex, '');
  s = s.replaceAll(_scriptLikeRegex, '');
  s = s.replaceAll('\u0000', ''); // strip NUL
  s = s.replaceAll(_multipleSpaces, ' ').trim();
  return s;
}

String sanitizeMarkdown(String input) {
  if (input.isEmpty) return input;
  var s = input;
  // Remove raw HTML blocks and obvious script payloads
  s = s.replaceAll(_htmlTagRegex, '');
  s = s.replaceAll(_scriptLikeRegex, '');

  // Disallow image/data javascript urls
  s = s.replaceAllMapped(RegExp(r"!\[[^\]]*\]\(([^)]+)\)"), (m) {
    final url = m.group(1) ?? '';
    final safe = _isSafeUrl(url) ? url : '';
    return m.group(0)!.replaceFirst(url, safe);
  });
  s = s.replaceAllMapped(RegExp(r"\[[^\]]*\]\(([^)]+)\)"), (m) {
    final url = m.group(1) ?? '';
    final safe = _isSafeUrl(url) ? url : '';
    return m.group(0)!.replaceFirst(url, safe);
  });

  // Normalize whitespace
  s = s.replaceAll('\u0000', '');
  return s;
}

bool _isSafeUrl(String url) {
  final u = url.trim().toLowerCase();
  if (u.isEmpty) return false;
  return u.startsWith('https://') || u.startsWith('http://');
}
