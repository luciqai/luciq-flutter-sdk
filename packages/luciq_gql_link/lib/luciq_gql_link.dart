import 'dart:convert';

import 'package:gql/ast.dart' show OperationType;
import 'package:gql/language.dart' show printNode;
import 'package:gql_exec/gql_exec.dart';
import 'package:gql_http_link/gql_http_link.dart'
    show HttpLinkParserException, HttpLinkServerException;
import 'package:gql_link/gql_link.dart';
import 'package:http/http.dart' show MultipartFile;
import 'package:luciq_flutter/luciq_flutter.dart';
// ignore: invalid_use_of_internal_member
import 'package:luciq_flutter/src/utils/luciq_logger.dart';

const _operationTypeHeader = 'x-luciq-graphql-operation-type';
const _defaultContentType = 'application/json';
const _logTag = 'LCQ-Flutter-GQL:';

/// A `gql_link` middleware that forwards GraphQL operations to the next link
/// while reporting them to the Luciq dashboard via [NetworkLogger].
///
/// Place this link before the terminating link in your chain, e.g.
/// `Link.from([LuciqGqlLink(endpoint: url), HttpLink(url)])`.
class LuciqGqlLink extends Link {
  LuciqGqlLink({this.endpoint = 'graphql'}) {
    LuciqLogger.I.v(
      '[LuciqGqlLink] phase=init endpoint="$endpoint"',
      tag: _logTag,
    );
  }

  /// Display label shown in the Luciq dashboard for operations going through
  /// this link. This is **not** the transport URL — the actual network call is
  /// made by the terminating link (e.g. `HttpLink`). For correlation, pass the
  /// same URL you give the terminating link.
  final String endpoint;
  final NetworkLogger _networkLogger = NetworkLogger();

  @override
  Stream<Response> request(
    Request request, [
    NextLink? forward,
  ]) {
    if (forward == null) {
      LuciqLogger.I.e(
        '[request] phase=error reason=forwardNull; LuciqGqlLink must be '
        'placed before a terminating link',
        tag: _logTag,
      );
      return Stream.error(
        StateError(
          'LuciqGqlLink is not a terminating link and requires a forward function.',
        ),
      );
    }

    final startTime = DateTime.now();
    final operationName = request.operation.operationName;
    final operationType = _getOperationType(request.operation);
    final requestBody = _buildRequestBody(request);
    final url = operationName != null ? '$endpoint ($operationName)' : endpoint;

    LuciqLogger.I.d(
      '[request] phase=start type=$operationType '
      'name=${operationName ?? '<anonymous>'} url=$url',
      tag: _logTag,
    );

    final inboundLinkHeaders =
        request.context.entry<HttpLinkHeaders>()?.headers ??
            const <String, String>{};
    final mergedHeaders = Map<String, dynamic>.from(inboundLinkHeaders);

    LuciqLogger.I.v('[request] phase=enter op=fetchW3C', tag: _logTag);

    return Stream.fromFuture(
      // ignore: invalid_use_of_internal_member
      _networkLogger.getW3CHeader(
        mergedHeaders,
        startTime.millisecondsSinceEpoch,
      ),
    ).asyncExpand((w3Header) {
      final generatedTrace = (w3Header?.isW3cHeaderFound == false)
          ? w3Header?.w3CGeneratedHeader
          : null;

      LuciqLogger.I.v(
        '[request] phase=w3c generated=${generatedTrace != null} '
        'inboundFound=${w3Header?.isW3cHeaderFound == true}',
        tag: _logTag,
      );

      if (generatedTrace != null) {
        mergedHeaders['traceparent'] = generatedTrace;
        LuciqLogger.I.v('[request] phase=w3c op=inject', tag: _logTag);
      }

      final outgoingRequest = generatedTrace != null
          ? request.updateContextEntry<HttpLinkHeaders>((entry) {
              final wireHeaders =
                  Map<String, String>.from(entry?.headers ?? const {});
              wireHeaders['traceparent'] = generatedTrace;
              return HttpLinkHeaders(headers: wireHeaders);
            })
          : request;

      final logRequestHeaders = Map<String, dynamic>.from(mergedHeaders)
        ..[_operationTypeHeader] = operationType;
      final requestContentType =
          inboundLinkHeaders['content-type'] ?? _defaultContentType;

      // For subscriptions the stream emits multiple responses. Each emission
      // is logged as its own NetworkData record whose `startTime` is the end
      // of the previous emission (or the request start, for the first one).
      // The recorded `duration` therefore reflects the gap between successive
      // events, not the per-event server work.
      var lastEventStart = startTime;

      LuciqLogger.I.d(
        '[request] phase=dispatch '
        'name=${operationName ?? '<anonymous>'} url=$url',
        tag: _logTag,
      );

      return forward(outgoingRequest).map((response) {
        final endTime = DateTime.now();
        final eventStart = lastEventStart;
        _logResponse(
          operationName: operationType,
          gqlQueryName: operationName,
          url: url,
          requestBody: requestBody,
          requestHeaders: logRequestHeaders,
          requestContentType: requestContentType,
          response: response,
          startTime: eventStart,
          endTime: endTime,
          w3cHeader: w3Header,
        );
        LuciqLogger.I.d(
          '[request] phase=response '
          'status=${response.context.entry<HttpLinkResponseContext>()?.statusCode} '
          'gqlErrors=${response.errors?.length ?? 0} '
          'duration=${endTime.difference(eventStart).inMicroseconds}us '
          'name=${operationName ?? '<anonymous>'}',
          tag: _logTag,
        );
        lastEventStart = endTime;
        return response;
      }).handleError((Object error, StackTrace stackTrace) {
        final endTime = DateTime.now();
        _logError(
          url: url,
          gqlQueryName: operationName,
          requestBody: requestBody,
          requestHeaders: logRequestHeaders,
          requestContentType: requestContentType,
          error: error,
          startTime: lastEventStart,
          endTime: endTime,
          w3cHeader: w3Header,
        );
        // ignore: only_throw_errors
        throw error;
      });
    });
  }

  void _logResponse({
    required String operationName,
    required String? gqlQueryName,
    required String url,
    required String requestBody,
    required Map<String, dynamic> requestHeaders,
    required String requestContentType,
    required Response response,
    required DateTime startTime,
    required DateTime endTime,
    required W3CHeader? w3cHeader,
  }) {
    final responseBody = _buildResponseBody(response);
    final httpCtx = response.context.entry<HttpLinkResponseContext>();
    final httpHeaders = httpCtx?.headers;
    final responseHeaders = <String, dynamic>{...?httpHeaders};
    final responseContentType =
        httpHeaders?['content-type'] ?? _defaultContentType;
    final status = httpCtx?.statusCode;
    final requestBodySize = _calculateBodySize(requestBody);
    final responseBodySize = _calculateBodySize(responseBody);
    final errors = response.errors;
    // Surface the first GraphQL error so the dashboard can group on it even
    // when the HTTP transport returned 200.
    final errorName = (errors != null && errors.isNotEmpty)
        ? _truncate(errors.first.message)
        : null;

    final data = NetworkData(
      startTime: startTime,
      url: url,
      method: 'POST',
      requestBody: requestBody,
      requestHeaders: requestHeaders,
      requestBodySize: requestBodySize,
      requestContentType: requestContentType,
      responseBody: responseBody,
      responseHeaders: responseHeaders,
      responseBodySize: responseBodySize,
      responseContentType: responseContentType,
      status: status,
      endTime: endTime,
      duration: endTime.difference(startTime).inMicroseconds,
      errorName: errorName,
      gqlQueryName: gqlQueryName,
      w3cHeader: w3cHeader,
    );

    // ignore: invalid_use_of_internal_member
    _networkLogger.networkLogInternal(data);
  }

  void _logError({
    required String url,
    required String? gqlQueryName,
    required String requestBody,
    required Map<String, dynamic> requestHeaders,
    required String requestContentType,
    required Object error,
    required DateTime startTime,
    required DateTime endTime,
    required W3CHeader? w3cHeader,
  }) {
    int? status;
    var responseHeaders = <String, dynamic>{};
    var responseBody = error.toString();
    var responseContentType = _defaultContentType;

    Map<String, String>? errorHeaders;
    String? errorBody;
    if (error is HttpLinkServerException) {
      status = error.response.statusCode;
      errorHeaders = error.response.headers;
      errorBody = error.response.body;
    } else if (error is HttpLinkParserException) {
      status = error.response.statusCode;
      errorHeaders = error.response.headers;
      errorBody = error.response.body;
    }

    if (errorHeaders != null) {
      responseHeaders = <String, dynamic>{...errorHeaders};
      responseContentType = errorHeaders['content-type'] ?? _defaultContentType;
    }
    if (errorBody != null && errorBody.isNotEmpty) {
      responseBody = errorBody;
    }

    LuciqLogger.I.e(
      '[_logError] phase=error errorType=${error.runtimeType} status=$status '
      'name=${gqlQueryName ?? '<anonymous>'}',
      tag: _logTag,
    );

    final requestBodySize = _calculateBodySize(requestBody);
    final responseBodySize = _calculateBodySize(responseBody);
    final errorName = _extractErrorName(error, errorBody);

    final data = NetworkData(
      startTime: startTime,
      url: url,
      method: 'POST',
      requestBody: requestBody,
      requestHeaders: requestHeaders,
      requestBodySize: requestBodySize,
      requestContentType: requestContentType,
      responseBody: responseBody,
      responseHeaders: responseHeaders,
      responseBodySize: responseBodySize,
      responseContentType: responseContentType,
      status: status,
      endTime: endTime,
      duration: endTime.difference(startTime).inMicroseconds,
      errorDomain: 'graphql',
      errorName: errorName,
      gqlQueryName: gqlQueryName,
      w3cHeader: w3cHeader,
    );

    // ignore: invalid_use_of_internal_member
    _networkLogger.networkLogInternal(data);
  }

  String _getOperationType(Operation operation) {
    final operationType = operation.getOperationType();
    switch (operationType) {
      case OperationType.query:
        return 'query';
      case OperationType.mutation:
        return 'mutation';
      case OperationType.subscription:
        return 'subscription';
      default:
        return 'unknown';
    }
  }

  String _buildRequestBody(Request request) {
    try {
      final sanitizedVariables = _sanitizeVariablesForLog(request.variables);
      final body = <String, dynamic>{
        'query': printNode(request.operation.document),
        if (request.operation.operationName != null)
          'operationName': request.operation.operationName,
        if (sanitizedVariables.isNotEmpty) 'variables': sanitizedVariables,
      };
      return jsonEncode(body);
    } catch (e) {
      LuciqLogger.I.e(
        '[_buildRequestBody] phase=error op=encode errorType=${e.runtimeType}',
        tag: _logTag,
      );
      return jsonEncode(<String, String>{
        '_luciq_encode_error': e.toString(),
        'fallback': request.toString(),
      });
    }
  }

  /// Recursively walks [variables] and replaces any [MultipartFile] with a
  /// JSON-friendly placeholder so the variables can be encoded for logging
  /// without consuming the file stream. The caller's map is not mutated; the
  /// terminating link still sees the original [MultipartFile] entries.
  Map<String, dynamic> _sanitizeVariablesForLog(
    Map<String, dynamic> variables,
  ) {
    final out = <String, dynamic>{};
    variables.forEach((key, value) {
      out[key] = _sanitizeValueForLog(value);
    });
    return out;
  }

  dynamic _sanitizeValueForLog(dynamic value) {
    if (value is MultipartFile) {
      LuciqLogger.I.v(
        '[_sanitizeValueForLog] phase=sanitize op=multipart '
        'field=${value.field} filename=${value.filename}',
        tag: _logTag,
      );
      return <String, dynamic>{
        '__luciq_multipart': true,
        'field': value.field,
        'filename': value.filename,
        'contentType': value.contentType.toString(),
        'length': value.length,
      };
    }
    if (value is Map<String, dynamic>) {
      return _sanitizeVariablesForLog(value);
    }
    if (value is List) {
      return value.map(_sanitizeValueForLog).toList();
    }
    return value;
  }

  String _buildResponseBody(Response response) {
    try {
      final body = <String, dynamic>{
        if (response.data != null) 'data': response.data,
        if (response.errors != null && response.errors!.isNotEmpty)
          'errors': response.errors!
              .map(
                (e) => {
                  'message': e.message,
                  if (e.locations != null)
                    'locations': e.locations!
                        .map((l) => {'line': l.line, 'column': l.column})
                        .toList(),
                  if (e.path != null) 'path': e.path,
                  if (e.extensions != null) 'extensions': e.extensions,
                },
              )
              .toList(),
      };
      return jsonEncode(body);
    } catch (e) {
      LuciqLogger.I.e(
        '[_buildResponseBody] phase=error op=encode errorType=${e.runtimeType}',
        tag: _logTag,
      );
      return jsonEncode(<String, String>{
        '_luciq_encode_error': e.toString(),
        'fallback': response.toString(),
      });
    }
  }

  /// Returns a short label suitable for the [NetworkData.errorName] field.
  ///
  /// Prefers the first GraphQL error message embedded in the transport
  /// response (when the server returned a structured `errors` array), then
  /// falls back to the Dart runtime type of the thrown exception.
  String? _extractErrorName(Object error, String? errorBody) {
    if (errorBody != null && errorBody.isNotEmpty) {
      try {
        final parsed = jsonDecode(errorBody);
        if (parsed is Map<String, dynamic>) {
          final errors = parsed['errors'];
          if (errors is List && errors.isNotEmpty) {
            final first = errors.first;
            if (first is Map && first['message'] is String) {
              return _truncate(first['message'] as String);
            }
          }
        }
      } catch (_) {
        // Body wasn't JSON or didn't carry a GraphQL error envelope. Fall
        // through to the runtime-type fallback.
      }
    }
    return error.runtimeType.toString();
  }

  String _truncate(String value, {int max = 256}) =>
      value.length <= max ? value : value.substring(0, max);

  int _calculateBodySize(dynamic data) {
    if (data == null) return 0;

    try {
      if (data is String) {
        return utf8.encode(data).length;
      }
      final jsonString = jsonEncode(data);
      return utf8.encode(jsonString).length;
    } catch (e) {
      LuciqLogger.I.v(
        '[_calculateBodySize] phase=warn op=fallback errorType=${e.runtimeType}',
        tag: _logTag,
      );
      return utf8.encode(data.toString()).length;
    }
  }
}
