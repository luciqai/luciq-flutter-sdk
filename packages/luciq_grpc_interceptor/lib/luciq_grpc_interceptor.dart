import 'dart:async';

import 'package:grpc/grpc.dart';
import 'package:luciq_flutter/luciq_flutter.dart';
import 'package:luciq_grpc_interceptor/src/grpc_body_codec.dart';
import 'package:luciq_grpc_interceptor/src/grpc_status_mapper.dart';
import 'package:luciq_grpc_interceptor/src/tapped_response_stream.dart';

export 'src/grpc_status_mapper.dart' show grpcStatusToHttpStatus;

const int _kStreamBufferCapBytes = 64 * 1024;

class LuciqGrpcInterceptor extends ClientInterceptor {
  final NetworkLogger _networkLogger = NetworkLogger();

  @override
  ResponseFuture<R> interceptUnary<Q, R>(
    ClientMethod<Q, R> method,
    Q request,
    CallOptions options,
    ClientUnaryInvoker<Q, R> invoker,
  ) {
    final startTime = DateTime.now();
    final ctx = _CallContext();

    final modifiedOptions = _withW3CProvider(options, startTime, ctx);
    final response = invoker(method, request, modifiedOptions);

    response.then(
      (value) async {
        var headers = const <String, String>{};
        var trailers = const <String, String>{};
        try {
          headers = await response.headers;
        } catch (_) {}
        try {
          trailers = await response.trailers;
        } catch (_) {}

        final grpcStatus = _readGrpcStatus(trailers);
        if (grpcStatus != null && grpcStatus != StatusCode.ok) {
          await _logFailure(
            method: method,
            request: request,
            error: GrpcError.custom(
              grpcStatus,
              trailers['grpc-message'] ?? '',
            ),
            startTime: startTime,
            ctx: ctx,
            extraResponseHeaders: _mergeHeadersAndTrailers(headers, trailers),
          );
          return;
        }

        await _logUnarySuccess(
          method: method,
          request: request,
          response: value,
          startTime: startTime,
          ctx: ctx,
          headers: headers,
          trailers: trailers,
        );
      },
      onError: (Object error) async {
        await _logFailure(
          method: method,
          request: request,
          error: error,
          startTime: startTime,
          ctx: ctx,
        );
      },
    ).ignore();

    return response;
  }

  @override
  ResponseStream<R> interceptStreaming<Q, R>(
    ClientMethod<Q, R> method,
    Stream<Q> requests,
    CallOptions options,
    ClientStreamingInvoker<Q, R> invoker,
  ) {
    final startTime = DateTime.now();
    final ctx = _CallContext();
    final reqCapture = _StreamCapture();
    final resCapture = _StreamCapture();

    final modifiedOptions = _withW3CProvider(options, startTime, ctx);

    final tappedRequests = requests.map((req) {
      reqCapture.append(req);
      return req;
    });

    final stream = invoker(method, tappedRequests, modifiedOptions);
    final tappedResponses = stream.map((res) {
      resCapture.append(res);
      return res;
    });

    stream.trailers.then(
      (trailers) async {
        var headers = const <String, String>{};
        try {
          headers = await stream.headers;
        } catch (_) {}
        await _logStreamComplete(
          method: method,
          headers: headers,
          trailers: trailers,
          startTime: startTime,
          ctx: ctx,
          reqCapture: reqCapture,
          resCapture: resCapture,
        );
      },
      onError: (Object error) async {
        await _logFailure(
          method: method,
          error: error,
          startTime: startTime,
          ctx: ctx,
          reqCapture: reqCapture,
          resCapture: resCapture,
        );
      },
    ).ignore();

    return TappedResponseStream<R>(stream, tappedResponses);
  }

  CallOptions _withW3CProvider(
    CallOptions options,
    DateTime startTime,
    _CallContext ctx,
  ) {
    return options.mergedWith(
      CallOptions(
        providers: [
          (Map<String, String> metadata, String uri) async {
            try {
              // ignore: invalid_use_of_internal_member
              final header = await _networkLogger.getW3CHeader(
                Map<String, dynamic>.from(metadata),
                startTime.millisecondsSinceEpoch,
              );
              if (header?.isW3cHeaderFound == false &&
                  header?.w3CGeneratedHeader != null) {
                metadata['traceparent'] = header!.w3CGeneratedHeader!;
              }
              ctx.completeProvider(
                w3cHeader: header,
                authority: uri,
                metadata: Map<String, String>.from(metadata),
              );
            } catch (_) {
              ctx.completeProvider(
                w3cHeader: null,
                authority: uri,
                metadata: Map<String, String>.from(metadata),
              );
            }
          },
        ],
      ),
    );
  }

  Future<void> _logUnarySuccess<Q, R>({
    required ClientMethod<Q, R> method,
    required Q request,
    required R response,
    required DateTime startTime,
    required _CallContext ctx,
    required Map<String, String> headers,
    required Map<String, String> trailers,
  }) async {
    try {
      final endTime = DateTime.now();
      final requestBody = parseGrpcBody(request);
      final responseBody = parseGrpcBody(response);

      _networkLogger.networkLog(
        NetworkData(
          startTime: startTime,
          url: _buildUrl(method, ctx.authority),
          method: 'POST',
          requestBody: requestBody,
          requestHeaders: ctx.requestHeadersForLog(),
          requestBodySize: calculateGrpcBodySize(request),
          responseBody: responseBody,
          responseHeaders: _mergeHeadersAndTrailers(headers, trailers),
          responseBodySize: calculateGrpcBodySize(response),
          status: grpcStatusToHttpStatus(StatusCode.ok),
          requestContentType: 'application/grpc',
          responseContentType: 'application/grpc',
          endTime: endTime,
          duration: endTime.difference(startTime).inMicroseconds,
          w3cHeader: ctx.w3cHeader,
        ),
      );
    } catch (_) {}
  }

  Future<void> _logStreamComplete<Q, R>({
    required ClientMethod<Q, R> method,
    required Map<String, String> headers,
    required Map<String, String> trailers,
    required DateTime startTime,
    required _CallContext ctx,
    required _StreamCapture reqCapture,
    required _StreamCapture resCapture,
  }) async {
    try {
      final endTime = DateTime.now();
      final grpcStatus = _readGrpcStatus(trailers) ?? StatusCode.unknown;

      final responseHeaders = _mergeHeadersAndTrailers(headers, trailers);
      _annotateStreamMetrics(responseHeaders, resCapture, startTime);

      final isError = grpcStatus != StatusCode.ok;
      final responseBody = isError
          ? (trailers['grpc-message'] ?? resCapture.body())
          : resCapture.body();

      _networkLogger.networkLog(
        NetworkData(
          startTime: startTime,
          url: _buildUrl(method, ctx.authority),
          method: 'POST',
          requestBody: reqCapture.body(),
          requestHeaders: ctx.requestHeadersForLog(),
          requestBodySize: reqCapture.byteCount,
          responseBody: responseBody,
          responseHeaders: responseHeaders,
          responseBodySize: resCapture.byteCount,
          requestContentType: 'application/grpc',
          responseContentType: 'application/grpc',
          status: grpcStatusToHttpStatus(grpcStatus),
          errorCode: isError ? grpcStatus : 0,
          errorDomain: isError ? 'grpc' : '',
          endTime: endTime,
          duration: endTime.difference(startTime).inMicroseconds,
          w3cHeader: ctx.w3cHeader,
        ),
      );
    } catch (_) {}
  }

  Future<void> _logFailure<Q, R>({
    required ClientMethod<Q, R> method,
    Q? request,
    required Object error,
    required DateTime startTime,
    required _CallContext ctx,
    _StreamCapture? reqCapture,
    _StreamCapture? resCapture,
    Map<String, dynamic>? extraResponseHeaders,
  }) async {
    try {
      final endTime = DateTime.now();

      var status = 500;
      var errorDomain = 'transport';
      var errorCode = 0;
      var errorMessage = error.toString();

      if (error is GrpcError) {
        status = grpcStatusToHttpStatus(error.code);
        errorDomain = 'grpc';
        errorCode = error.code;
        errorMessage = error.message ?? error.codeName;
      }

      final requestBody =
          reqCapture?.body() ?? (request != null ? parseGrpcBody(request) : '');
      final requestBodySize = reqCapture?.byteCount ??
          (request != null ? calculateGrpcBodySize(request) : 0);

      final responseHeaders = <String, dynamic>{
        if (extraResponseHeaders != null) ...extraResponseHeaders,
      };
      if (resCapture != null) {
        _annotateStreamMetrics(responseHeaders, resCapture, startTime);
      }

      _networkLogger.networkLog(
        NetworkData(
          startTime: startTime,
          url: _buildUrl(method, ctx.authority),
          method: 'POST',
          requestBody: requestBody,
          requestHeaders: ctx.requestHeadersForLog(),
          requestBodySize: requestBodySize,
          responseBody: errorMessage,
          responseHeaders: responseHeaders,
          responseBodySize: calculateGrpcBodySize(errorMessage),
          status: status,
          errorCode: errorCode,
          errorDomain: errorDomain,
          requestContentType: 'application/grpc',
          responseContentType: 'application/grpc',
          endTime: endTime,
          duration: endTime.difference(startTime).inMicroseconds,
          w3cHeader: ctx.w3cHeader,
        ),
      );
    } catch (_) {}
  }

  String _buildUrl<Q, R>(ClientMethod<Q, R> method, String? authority) {
    final path = method.path.isEmpty ? '/unknown' : method.path;
    if (authority == null || authority.isEmpty) return path;
    return 'grpc://$authority$path';
  }

  int? _readGrpcStatus(Map<String, String> trailers) {
    final raw = trailers['grpc-status'];
    if (raw == null) return null;
    return int.tryParse(raw) ?? StatusCode.unknown;
  }

  Map<String, dynamic> _mergeHeadersAndTrailers(
    Map<String, String> headers,
    Map<String, String> trailers,
  ) {
    final merged = <String, dynamic>{};
    headers.forEach((k, v) => merged[k] = v);
    trailers.forEach((k, v) => merged['trailer-$k'] = v);
    return merged;
  }

  void _annotateStreamMetrics(
    Map<String, dynamic> headers,
    _StreamCapture capture,
    DateTime startTime,
  ) {
    headers['x-luciq-stream-message-count'] = capture.messageCount.toString();
    final firstAt = capture.firstAt;
    if (firstAt != null) {
      headers['x-luciq-stream-first-byte-ms'] =
          firstAt.difference(startTime).inMilliseconds.toString();
    }
    final lastAt = capture.lastAt;
    if (lastAt != null) {
      headers['x-luciq-stream-last-byte-ms'] =
          lastAt.difference(startTime).inMilliseconds.toString();
    }
  }
}

class _CallContext {
  W3CHeader? w3cHeader;
  String? authority;
  Map<String, String> metadata = const <String, String>{};

  void completeProvider({
    required W3CHeader? w3cHeader,
    required String? authority,
    required Map<String, String> metadata,
  }) {
    this.w3cHeader = w3cHeader;
    this.authority = authority;
    this.metadata = metadata;
  }

  Map<String, dynamic> requestHeadersForLog() {
    final headers = <String, dynamic>{};
    metadata.forEach((k, v) => headers[k] = v);
    return headers;
  }
}

class _StreamCapture {
  final StringBuffer _buffer = StringBuffer();
  int _capturedBytes = 0;
  bool _truncated = false;
  int byteCount = 0;
  int messageCount = 0;
  DateTime? firstAt;
  DateTime? lastAt;

  void append(dynamic message) {
    final now = DateTime.now();
    firstAt ??= now;
    lastAt = now;
    messageCount++;
    byteCount += calculateGrpcBodySize(message);

    if (_truncated) return;
    final encoded = parseGrpcBody(message);
    final encodedBytes = encoded.length;
    if (_capturedBytes + encodedBytes > _kStreamBufferCapBytes) {
      _truncated = true;
      _buffer.write('...[truncated at $_kStreamBufferCapBytes bytes]');
      return;
    }
    if (_buffer.isNotEmpty) _buffer.write('\n');
    _buffer.write(encoded);
    _capturedBytes += encodedBytes;
  }

  String body() => _buffer.toString();
}
