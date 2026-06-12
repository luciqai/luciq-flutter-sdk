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

  String parseBody(dynamic data) {
    try {
      final encoded = jsonEncode(data);
      final decoded = jsonDecode(encoded);

      // Remove sensitive fields
      if (decoded is Map<String, dynamic>) {
        _removeSensitiveFields(decoded);
      } else if (decoded is List) {
        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            _removeSensitiveFields(item);
          }
        }
      }

      return jsonEncode(decoded);
    } catch (e) {
      return 'Error parsing body: ${e.toString()}';
    }
  }

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

  void _removeSensitiveFields(Map<String, dynamic> map) {
    final sensitiveKeys = [
      'password',
      'currentPassword',
      'client_secret',
    ];

    map.forEach((key, value) {
      final lowerKey = key.toLowerCase();

      if (sensitiveKeys.any((sensitive) => lowerKey.contains(sensitive))) {
        map[key] = '***REDACTED***';
      } else if (value is String && _isStripeToken(value)) {
        map[key] = '***REDACTED***';
      } else if (value is Map<String, dynamic>) {
        _removeSensitiveFields(value);
      } else if (value is List) {
        for (final item in value) {
          if (item is Map<String, dynamic>) {
            _removeSensitiveFields(item);
          }
        }
      }
    });
  }

  // Detects Stripe payment method tokens (pm_*) and client secrets (pi_*_secret_*, seti_*_secret_*)
  bool _isStripeToken(String value) {
    if (value.startsWith('pm_')) return true;
    if (RegExp(r'^[a-z]{2,}_[A-Za-z0-9]+_secret_').hasMatch(value)) return true;
    return false;
  }
}
