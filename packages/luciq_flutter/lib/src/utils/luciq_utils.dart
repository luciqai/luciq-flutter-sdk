/// Strips query string, fragment, and userinfo from a URL for safe inclusion
/// in debug logs.
///
/// URLs commonly carry user identifiers, tokens, and PII in query parameters
/// (e.g. `?email=u@x.com`, `?token=...`) and credentials in the userinfo
/// segment (`https://user:pass@host/...`). Both are removed here. The path is
/// preserved because it is typically needed for diagnostics and is the
/// boundary the user approved.
///
/// Returns the URL with `?...`, `#...`, and any `userinfo@` portion removed.
/// A `?<redacted>` suffix is appended when a query string was stripped, so
/// the trace remains unambiguous about whether a query was present.
String redactUrlForLog(String? url) {
  if (url == null || url.isEmpty) return '';

  // Strip userinfo (scheme://user:pass@host/... -> scheme://host/...). Only
  // treat `@` as userinfo when it appears in the authority (between `://` and
  // the next `/`, `?`, or `#`), so an `@` in the path is preserved.
  var stripped = url;
  final schemeEnd = stripped.indexOf('://');
  if (schemeEnd != -1) {
    final authorityStart = schemeEnd + 3;
    var authorityEnd = stripped.length;
    for (var i = authorityStart; i < stripped.length; i++) {
      final c = stripped.codeUnitAt(i);
      // '/' = 47, '?' = 63, '#' = 35
      if (c == 47 || c == 63 || c == 35) {
        authorityEnd = i;
        break;
      }
    }
    final atIdx = stripped.lastIndexOf('@', authorityEnd - 1);
    if (atIdx > authorityStart - 1 && atIdx < authorityEnd) {
      stripped =
          stripped.substring(0, authorityStart) + stripped.substring(atIdx + 1);
    }
  }

  final queryIdx = stripped.indexOf('?');
  final fragIdx = stripped.indexOf('#');
  var cutoff = -1;
  if (queryIdx != -1) cutoff = queryIdx;
  if (fragIdx != -1 && (cutoff == -1 || fragIdx < cutoff)) cutoff = fragIdx;
  if (cutoff == -1) return stripped;

  // Mark a redacted query only when a real query string was cut (i.e. `?`
  // preceded any `#`). A `?` inside a fragment is part of the fragment.
  final cutAtQuery = queryIdx != -1 && (fragIdx == -1 || queryIdx < fragIdx);
  return stripped.substring(0, cutoff) + (cutAtQuery ? '?<redacted>' : '');
}
