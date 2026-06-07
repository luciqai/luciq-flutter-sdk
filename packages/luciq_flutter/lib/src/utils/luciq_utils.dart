/// Stable 8-char hex hash of an arbitrary string for use in debug logs.
///
/// Lets the same value (screen name, route name, span name, URL, widget name)
/// be correlated across multiple log lines without leaking the raw text. Same
/// input always yields the same hash within a process and across runs.
///
/// Returns `'00000000'` for null or empty input. Uses FNV-1a (32-bit) to avoid
/// pulling in the `crypto` package for a non-cryptographic correlation id.
String hashForLog(String? value) {
  if (value == null || value.isEmpty) return '00000000';
  // FNV-1a 32-bit. Constants per http://www.isthe.com/chongo/tech/comp/fnv/
  var hash = 0x811c9dc5;
  for (var i = 0; i < value.length; i++) {
    hash = (hash ^ value.codeUnitAt(i)) & 0xffffffff;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return hash.toRadixString(16).padLeft(8, '0');
}

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
