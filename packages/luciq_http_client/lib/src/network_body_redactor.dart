import 'dart:convert';

const _sensitiveKeys = [
  // Credentials and tokens. `token` alone also catches `wunderTokenV3`/
  // `wunderTokenV4` (RIDER-5636) — those don't share a compound word with
  // `access_token`/`refresh_token`, and `wunderTokenV3`'s value isn't
  // JWT-shaped so it isn't caught by `_isStripeToken`'s value check either.
  'password',
  'currentPassword',
  'client_secret',
  'access_token',
  'refresh_token',
  'token',
  // Contact details
  'phone',
  'msisdn',
  'mobilenumber',
  'mobile_number',
  'email',
  // Identity: name, date of birth, age and gender (RIDER-5636)
  'firstName',
  'lastName',
  'fullName',
  'birthDate',
  'dateOfBirth',
  'birthday',
  'age',
  'gender',
];

// Deliberately left visible, since neither identifies a customer on their
// own and both are needed to debug from a report: `tags` (backend
// segmentation codes, also used as display labels on purchasable items) and
// `customerId`/`customerReference` (internal ids).

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

// A bare `code` field is ambiguous across this API: it's the OTP/SMS
// verification code on auth endpoints (RIDER-5636), but also a plain
// (non-secret) plan identifier on subscription/bundle responses, e.g.
// `{"code": "25", "title": "Forest Flex"}`. Rather than keying off the
// request URL (the acceptance criteria calls for one rule, not a list of
// screens), redact a bare `code` only when it's sent alongside a phone or
// email — every verification/sign-in call pairs `code` with one of those
// (`phone`, `number`, or `email`), while plan/bundle/promo-code payloads
// never do.
bool _isVerificationCode(String key, Map<String, dynamic> siblings) {
  if (_wordsOf(key).join('_') != 'code') return false;
  return siblings.entries.any((entry) {
    if (entry.key == key) return false;
    final words = _wordsOf(entry.key);
    if (words.contains('phone') || words.contains('number') || words.contains('email')) {
      return true;
    }
    final value = entry.value;
    return value is String && _isPhoneNumber(value);
  });
}

void _removeSensitiveFields(Map<String, dynamic> map) {
  map.forEach((key, value) {
    if (_matchesSensitiveKey(key) || _isVerificationCode(key, map)) {
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
