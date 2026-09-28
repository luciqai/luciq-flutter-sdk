import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:luciq_flutter/luciq_flutter.dart';

class LuciqDioInterceptor extends Interceptor {
  static final Map<int, NetworkData> _requests = <int, NetworkData>{};
  static final NetworkLogger _networklogger = NetworkLogger();

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final headers = options.headers;
    final startTime = DateTime.now();
    // ignore: invalid_use_of_internal_member
    final w3Header = await _networklogger.getW3CHeader(
      headers,
      startTime.millisecondsSinceEpoch,
    );
    if (w3Header?.isW3cHeaderFound == false &&
        w3Header?.w3CGeneratedHeader != null) {
      headers['traceparent'] = w3Header?.w3CGeneratedHeader;
    }
    options.headers = headers;
    final data = NetworkData(
      startTime: startTime,
      url: options.uri.toString(),
      w3cHeader: w3Header,
      method: options.method,
    );
    _requests[options.hashCode] = data;
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final data = _mapResponse(response);
    _networklogger.networkLog(data);
    handler.next(response);
  }

  @override
  // Keep `DioError` instead of `DioException` for backward-compatibility, for now.
  // ignore: deprecated_member_use
  void onError(DioError err, ErrorInterceptorHandler handler) {
    final data = _mapError(err);
    _networklogger.networkLog(data);

    handler.next(err);
  }

  static NetworkData _getRequestData(int requestHashCode) {
    final data = _requests[requestHashCode]!;
    _requests.remove(requestHashCode);
    return data;
  }

  NetworkData _mapError(DioException err) {
    if (err.response != null) {
      return _mapResponse(err.response!);
    }

    final data = _getRequestData(err.requestOptions.hashCode);

    final endTime = DateTime.now();

    var requestBodySize = 0;
    if (err.requestOptions.headers.containsKey('content-length')) {
      requestBodySize = int.parse(
        err.requestOptions.headers['content-length'] ?? '0',
      );
    } else if (err.requestOptions.data != null) {
      requestBodySize = err.requestOptions.data?.toString().length ?? 0;
    }

    return data.copyWith(
      endTime: endTime,
      duration: endTime.difference(data.startTime).inMicroseconds,
      url: err.requestOptions.uri.toString(),
      method: err.requestOptions.method,
      requestBody: err.requestOptions.data?.toString() ?? '',
      requestHeaders: err.requestOptions.headers,
      requestContentType: err.requestOptions.contentType ?? '',
      requestBodySize: requestBodySize,
      status: 0,
      responseBody: '',
      responseHeaders: <String, dynamic>{},
      responseContentType: '',
      responseBodySize: 0,
    );
  }

  NetworkData _mapResponse(Response<dynamic> response) {
    final data = _getRequestData(response.requestOptions.hashCode);
    final responseHeaders = <String, dynamic>{};
    final endTime = DateTime.now();

    response.headers.forEach(
      (String name, dynamic value) => responseHeaders[name] = value,
    );

    var responseContentType = '';
    if (responseHeaders.containsKey('content-type')) {
      responseContentType = responseHeaders['content-type'].toString();
    }

    var requestBodySize = 0;
    if (response.requestOptions.headers.containsKey('content-length')) {
      requestBodySize = int.parse(
        response.requestOptions.headers['content-length'] ?? '0',
      );
    } else if (response.requestOptions.data != null) {
      // Calculate actual byte size for more accurate size estimation
      requestBodySize = _calculateBodySize(response.requestOptions.data);
    }

    var responseBodySize = 0;
    if (responseHeaders.containsKey('content-length')) {
      // ignore: avoid_dynamic_calls
      responseBodySize = int.parse(responseHeaders['content-length'][0] ?? '0');
    } else if (response.data != null) {
      // Calculate actual byte size for more accurate size estimation
      responseBodySize = _calculateBodySize(response.data);
    }

    return data.copyWith(
      endTime: endTime,
      duration: endTime.difference(data.startTime).inMicroseconds,
      url: response.requestOptions.uri.toString(),
      method: response.requestOptions.method,
      requestBody: parseBody(response.requestOptions.data),
      requestHeaders: response.requestOptions.headers,
      requestContentType: response.requestOptions.contentType,
      requestBodySize: requestBodySize,
      status: response.statusCode,
      responseBody: parseBody(response.data),
      responseHeaders: responseHeaders,
      responseContentType: responseContentType,
      responseBodySize: responseBodySize,
    );
  }

  String parseBody(dynamic data) => redactNetworkBody(data);

  /// Calculates the actual byte size of the body data
  int _calculateBodySize(dynamic data) {
    if (data == null) return 0;

    try {
      // For string data, get UTF-8 byte length
      if (data is String) {
        return data.codeUnits.length;
      }

      // For other types, try to encode as JSON and get byte length
      final jsonString = jsonEncode(data);
      return jsonString.codeUnits.length;
    } catch (e) {
      // Fallback to string conversion if JSON encoding fails
      return data.toString().codeUnits.length;
    }
  }
}

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
    final decoded =
        data is String ? jsonDecode(data) : jsonDecode(jsonEncode(data));

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
      return _isStripeToken(data) || _isPhoneNumber(data)
          ? '***REDACTED***'
          : data;
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
    if (words.contains('phone') ||
        words.contains('number') ||
        words.contains('email')) {
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
    } else if (value is String &&
        (_isStripeToken(value) || _isPhoneNumber(value))) {
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
    } else if (item is String &&
        (_isStripeToken(item) || _isPhoneNumber(item))) {
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
