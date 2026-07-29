import 'dart:convert';

const _sensitiveKeys = [
  // Credentials and tokens
  'password',
  'currentPassword',
  'client_secret',
  'access_token',
  'refresh_token',
  // Contact details
  'phone',
  'msisdn',
  'mobilenumber',
  'mobile_number',
  'email',
  // Identity: name and date of birth
  'firstName',
  'lastName',
  'fullName',
  'birthDate',
  'dateOfBirth',
  'birthday',
];

// Deliberately left visible, since none of them identify a customer on their
// own and all of them are needed to debug from a report: `gender` (coded int),
// `tags` (backend segmentation codes, also used as display labels on
// purchasable items) and `customerId`/`customerReference` (internal ids).

/// Redacts sensitive fields (passwords, tokens, phone numbers, etc.) from
/// network request/response bodies before they're sent to network logging.
///
/// This only affects the copy of the data that gets logged — it never
/// touches the data actually sent to/received from the network.
String redactNetworkBody(dynamic data) {
  if (data is String && data.isEmpty) return data;

  try {
    final decoded = data is String ? jsonDecode(data) : jsonDecode(jsonEncode(data));

    if (decoded is Map<String, dynamic>) {
      _removeSensitiveFields(decoded);
    } else if (decoded is List) {
      _removeSensitiveFieldsFromList(decoded);
    } else if (decoded is String && _isPhoneNumber(decoded)) {
      return jsonEncode('***REDACTED***');
    }

    return jsonEncode(decoded);
  } catch (e) {
    // Not JSON (e.g. plain text, HTML, form-encoded body) — keep the original
    // content for diagnostics, redacting it only if it's a bare sensitive value.
    if (data is String) {
      return _isStripeToken(data) || _isPhoneNumber(data) ? '***REDACTED***' : data;
    }
    return 'Error parsing body: $e';
  }
}

// Splits a key into lowercase word tokens on camelCase boundaries and
// separators (_, -, space), so 'phone' matches 'phoneNumber'/'phone_number'
// but not 'microphoneEnabled'/'headphoneJack'.
List<String> _wordsOf(String key) {
  final withBoundaries = key.replaceAllMapped(
    RegExp('([a-z0-9])([A-Z])'),
    (m) => '${m[1]}_${m[2]}',
  );
  return withBoundaries
      .toLowerCase()
      .split(RegExp('[^a-z0-9]+'))
      .where((word) => word.isNotEmpty)
      .toList();
}

bool _matchesSensitiveKey(String key) {
  final normalized = '_${_wordsOf(key).join('_')}_';
  return _sensitiveKeys.any(
    (sensitive) => normalized.contains('_${_wordsOf(sensitive).join('_')}_'),
  );
}

void _removeSensitiveFields(Map<String, dynamic> map) {
  map.forEach((key, value) {
    if (_matchesSensitiveKey(key)) {
      map[key] = '***REDACTED***';
    } else if (value is String && (_isStripeToken(value) || _isPhoneNumber(value))) {
      map[key] = '***REDACTED***';
    } else if (value is Map<String, dynamic>) {
      _removeSensitiveFields(value);
    } else if (value is List) {
      _removeSensitiveFieldsFromList(value);
    }
  });
}

void _removeSensitiveFieldsFromList(List<dynamic> list) {
  for (var i = 0; i < list.length; i++) {
    final item = list[i];

    if (item is Map<String, dynamic>) {
      _removeSensitiveFields(item);
    } else if (item is List) {
      _removeSensitiveFieldsFromList(item);
    } else if (item is String && (_isStripeToken(item) || _isPhoneNumber(item))) {
      list[i] = '***REDACTED***';
    }
  }
}

// Detects Stripe tokens (pm_*, client secrets) and JWT bearer tokens
bool _isStripeToken(String value) {
  if (value.startsWith('pm_')) return true;
  if (RegExp('^[a-z]{2,}_[A-Za-z0-9]+_secret_').hasMatch(value)) return true;
  // JWTs always start with base64url-encoded '{"' → eyJ
  if (value.startsWith('eyJ')) return true;
  return false;
}

// Detects E.164-formatted phone numbers (e.g. +447911123456) even when
// logged under a key name that doesn't otherwise flag as sensitive.
bool _isPhoneNumber(String value) {
  return RegExp(r'^\+[1-9]\d{6,14}$').hasMatch(value);
}
