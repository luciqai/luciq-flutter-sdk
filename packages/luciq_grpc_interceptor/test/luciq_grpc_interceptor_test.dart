import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart';
import 'package:luciq_flutter/luciq_flutter.dart';
import 'package:luciq_flutter/src/generated/luciq.api.g.dart';
import 'package:luciq_grpc_interceptor/luciq_grpc_interceptor.dart';
import 'package:luciq_grpc_interceptor/src/grpc_body_codec.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'luciq_grpc_interceptor_test.mocks.dart';

@GenerateMocks(
  <Type>[
    LuciqHostApi,
  ],
  customMocks: [
    MockSpec<ClientCall<String, String>>(as: #MockClientCall),
  ],
)
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();

  final mHost = MockLuciqHostApi();

  setUpAll(() {
    Luciq.$setHostApi(mHost);
    NetworkLogger.$setHostApi(mHost);
    when(mHost.isW3CFeatureFlagsEnabled()).thenAnswer(
      (_) => Future<Map<String, bool>>.value(<String, bool>{
        'isW3cCaughtHeaderEnabled': true,
        'isW3cExternalGeneratedHeaderEnabled': true,
        'isW3cExternalTraceIDEnabled': true,
      }),
    );
    when(mHost.getNetworkBodyMaxSize()).thenAnswer(
      (_) => Future.value(10240),
    );
    when(mHost.networkLog(any)).thenAnswer((_) => Future<void>.value());
  });

  final method = ClientMethod<String, String>(
    '/test.Service/GetData',
    (value) => value.codeUnits,
    (bytes) => String.fromCharCodes(bytes),
  );

  MockClientCall createMockCall({
    String responseValue = 'test response',
    Map<String, String> headers = const {},
    Map<String, String> trailers = const {'grpc-status': '0'},
    bool shouldError = false,
    GrpcError? error,
  }) {
    final mockCall = MockClientCall();
    if (shouldError) {
      when(mockCall.response).thenAnswer(
        (_) => Stream<String>.error(
          error ?? const GrpcError.notFound('not found'),
        ),
      );
      when(mockCall.headers).thenAnswer(
        (_) => Future.error(
          error ?? const GrpcError.notFound('not found'),
        ),
      );
      when(mockCall.trailers).thenAnswer(
        (_) => Future.error(
          error ?? const GrpcError.notFound('not found'),
        ),
      );
    } else {
      when(mockCall.response).thenAnswer(
        (_) => Stream.value(responseValue),
      );
      when(mockCall.headers).thenAnswer(
        (_) => Future.value(headers),
      );
      when(mockCall.trailers).thenAnswer(
        (_) => Future.value(trailers),
      );
    }
    when(mockCall.cancel()).thenAnswer((_) => Future.value());
    return mockCall;
  }

  group('grpc body codec', () {
    test('parseGrpcBody prefers toProto3Json for protobuf-like objects', () {
      final body = parseGrpcBody(_FakeProto(name: 'echo'));
      expect(body, contains('"name":"echo"'));
    });

    test('parseGrpcBody falls back to jsonEncode for plain objects', () {
      expect(parseGrpcBody({'a': 1}), '{"a":1}');
    });

    test('parseGrpcBody returns empty string for null', () {
      expect(parseGrpcBody(null), '');
    });

    test('calculateGrpcBodySize uses writeToBuffer for protobuf-like objects',
        () {
      final size = calculateGrpcBodySize(
        _FakeProto(name: 'q', bytes: List<int>.filled(42, 1)),
      );
      expect(size, 42);
    });

    test('calculateGrpcBodySize uses utf8 byte length for strings', () {
      // Single multibyte character: 'é' = 2 utf-8 bytes (vs 1 utf-16 code unit).
      expect(calculateGrpcBodySize('é'), 2);
    });
  });

  group('grpcStatusToHttpStatus', () {
    test('maps OK to 200', () {
      expect(grpcStatusToHttpStatus(0), 200);
    });

    test('maps CANCELLED to 499', () {
      expect(grpcStatusToHttpStatus(1), 499);
    });

    test('maps NOT_FOUND to 404', () {
      expect(grpcStatusToHttpStatus(5), 404);
    });

    test('maps PERMISSION_DENIED to 403', () {
      expect(grpcStatusToHttpStatus(7), 403);
    });

    test('maps UNAUTHENTICATED to 401', () {
      expect(grpcStatusToHttpStatus(16), 401);
    });

    test('maps INTERNAL to 500', () {
      expect(grpcStatusToHttpStatus(13), 500);
    });

    test('maps UNAVAILABLE to 503', () {
      expect(grpcStatusToHttpStatus(14), 503);
    });

    test('maps unknown code to 500', () {
      expect(grpcStatusToHttpStatus(99), 500);
    });

    test('maps all standard gRPC codes', () {
      final expectedMappings = <int, int>{
        0: 200,
        1: 499,
        2: 500,
        3: 400,
        4: 504,
        5: 404,
        6: 409,
        7: 403,
        8: 429,
        9: 400,
        10: 409,
        11: 400,
        12: 501,
        13: 500,
        14: 503,
        15: 500,
        16: 401,
      };
      for (final entry in expectedMappings.entries) {
        expect(
          grpcStatusToHttpStatus(entry.key),
          entry.value,
          reason: 'gRPC status ${entry.key} should map to HTTP ${entry.value}',
        );
      }
    });
  });

  group('LuciqGrpcInterceptor - interceptUnary', () {
    test('logs successful unary call', () async {
      final completer = Completer<Map<String, dynamic>>();
      when(mHost.networkLog(any)).thenAnswer((invocation) {
        final data = invocation.positionalArguments[0] as Map<String, dynamic>;
        if (!completer.isCompleted) completer.complete(data);
        return Future<void>.value();
      });

      final interceptor = LuciqGrpcInterceptor();
      final mockCall = createMockCall();

      final response = interceptor.interceptUnary<String, String>(
        method,
        'test request',
        CallOptions(),
        (m, req, opts) => ResponseFuture<String>(mockCall),
      );

      await response;
      // Allow async logging to complete
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final capturedData = await completer.future;
      expect(capturedData['url'], '/test.Service/GetData');
      expect(capturedData['method'], 'POST');
      expect(capturedData['responseCode'], 200);
      expect(capturedData['requestContentType'], 'application/grpc');
    });

    test('logs error on failed unary call', () async {
      final completer = Completer<Map<String, dynamic>>();
      when(mHost.networkLog(any)).thenAnswer((invocation) {
        final data = invocation.positionalArguments[0] as Map<String, dynamic>;
        if (!completer.isCompleted) completer.complete(data);
        return Future<void>.value();
      });

      final interceptor = LuciqGrpcInterceptor();
      final mockCall = createMockCall(
        shouldError: true,
        error: const GrpcError.notFound('resource not found'),
      );

      final response = interceptor.interceptUnary<String, String>(
        method,
        'test request',
        CallOptions(),
        (m, req, opts) => ResponseFuture<String>(mockCall),
      );

      try {
        await response;
      } catch (_) {
        // Expected error
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final capturedData = await completer.future;
      expect(capturedData['url'], '/test.Service/GetData');
      expect(capturedData['method'], 'POST');
      expect(capturedData['responseCode'], 404);
      expect(capturedData['errorDomain'], 'grpc');
    });

    test('logs grpc://authority/path when providers run', () async {
      final completer = Completer<Map<String, dynamic>>();
      when(mHost.networkLog(any)).thenAnswer((invocation) {
        final data = invocation.positionalArguments[0] as Map<String, dynamic>;
        if (!completer.isCompleted) completer.complete(data);
        return Future<void>.value();
      });

      final interceptor = LuciqGrpcInterceptor();
      final mockCall = createMockCall();

      final response = interceptor.interceptUnary<String, String>(
        method,
        'test request',
        CallOptions(metadata: {'authorization': 'Bearer token-xyz'}),
        (m, req, opts) {
          final metadata = Map<String, String>.from(opts.metadata)..addAll({});
          for (final p in opts.metadataProviders) {
            p(metadata, 'http://localhost:50051/test.Service');
          }
          return ResponseFuture<String>(mockCall);
        },
      );

      await response;
      final captured = await completer.future;
      expect(
        captured['url'],
        'grpc://http://localhost:50051/test.Service/test.Service/GetData',
      );
      expect(
        captured['requestHeaders'],
        containsPair('authorization', 'Bearer token-xyz'),
      );
    });

    test('logs trailer-status non-OK as gRPC error', () async {
      final completer = Completer<Map<String, dynamic>>();
      when(mHost.networkLog(any)).thenAnswer((invocation) {
        final data = invocation.positionalArguments[0] as Map<String, dynamic>;
        if (!completer.isCompleted) completer.complete(data);
        return Future<void>.value();
      });

      final interceptor = LuciqGrpcInterceptor();
      final mockCall = createMockCall(
        trailers: {'grpc-status': '7', 'grpc-message': 'denied by policy'},
      );

      final response = interceptor.interceptUnary<String, String>(
        method,
        'test request',
        CallOptions(),
        (m, req, opts) => ResponseFuture<String>(mockCall),
      );

      await response;
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final captured = await completer.future;
      expect(captured['responseCode'], 403);
      expect(captured['errorDomain'], 'grpc');
      expect(captured['errorCode'], 7);
      expect(captured['responseBody'], contains('denied by policy'));
    });

    test('passes W3C header via MetadataProvider in CallOptions', () async {
      when(mHost.networkLog(any)).thenAnswer((_) => Future<void>.value());

      final interceptor = LuciqGrpcInterceptor();
      final mockCall = createMockCall();
      CallOptions? capturedOptions;

      interceptor.interceptUnary<String, String>(
        method,
        'test request',
        CallOptions(),
        (m, req, opts) {
          capturedOptions = opts;
          return ResponseFuture<String>(mockCall);
        },
      );

      expect(capturedOptions, isNotNull);
      expect(capturedOptions!.metadataProviders, isNotEmpty);
    });

    test('preserves existing CallOptions metadata', () async {
      when(mHost.networkLog(any)).thenAnswer((_) => Future<void>.value());

      final interceptor = LuciqGrpcInterceptor();
      final mockCall = createMockCall();
      CallOptions? capturedOptions;

      interceptor.interceptUnary<String, String>(
        method,
        'test request',
        CallOptions(metadata: {'custom-key': 'custom-value'}),
        (m, req, opts) {
          capturedOptions = opts;
          return ResponseFuture<String>(mockCall);
        },
      );

      expect(capturedOptions!.metadata['custom-key'], 'custom-value');
    });

    test('stress test - 1000 unary calls', () async {
      var logCount = 0;
      when(mHost.networkLog(any)).thenAnswer((_) {
        logCount++;
        return Future<void>.value();
      });

      final interceptor = LuciqGrpcInterceptor();

      for (var i = 0; i < 1000; i++) {
        final mockCall = createMockCall();
        final response = interceptor.interceptUnary<String, String>(
          method,
          'request $i',
          CallOptions(),
          (m, req, opts) => ResponseFuture<String>(mockCall),
        );
        try {
          await response;
        } catch (_) {}
      }

      await Future<void>.delayed(const Duration(milliseconds: 500));
      expect(logCount, 1000);
    });
  });

  group('LuciqGrpcInterceptor - interceptStreaming', () {
    test('logs streaming call on completion via trailers', () async {
      final completer = Completer<Map<String, dynamic>>();
      when(mHost.networkLog(any)).thenAnswer((invocation) {
        final data = invocation.positionalArguments[0] as Map<String, dynamic>;
        if (!completer.isCompleted) completer.complete(data);
        return Future<void>.value();
      });

      final interceptor = LuciqGrpcInterceptor();
      final mockCall = createMockCall(
        trailers: {'grpc-status': '0'},
      );

      interceptor.interceptStreaming<String, String>(
        method,
        Stream.value('test request'),
        CallOptions(),
        (m, req, opts) => ResponseStream<String>(mockCall),
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final capturedData = await completer.future;
      expect(capturedData['url'], '/test.Service/GetData');
      expect(capturedData['method'], 'POST');
      expect(capturedData['responseCode'], 200);
    });

    test('captures multi-message server stream body and metrics', () async {
      final completer = Completer<Map<String, dynamic>>();
      when(mHost.networkLog(any)).thenAnswer((invocation) {
        final data = invocation.positionalArguments[0] as Map<String, dynamic>;
        if (!completer.isCompleted) completer.complete(data);
        return Future<void>.value();
      });

      final interceptor = LuciqGrpcInterceptor();
      final mockCall = MockClientCall();
      final drained = Completer<void>();
      when(mockCall.response).thenAnswer(
        (_) => Stream<String>.fromIterable(['one', 'two', 'three']),
      );
      when(mockCall.headers)
          .thenAnswer((_) => Future.value(<String, String>{}));
      // Real gRPC: trailers resolve only after the response stream has drained.
      when(mockCall.trailers).thenAnswer((_) async {
        await drained.future;
        return <String, String>{'grpc-status': '0'};
      });
      when(mockCall.cancel()).thenAnswer((_) => Future.value());

      final stream = interceptor.interceptStreaming<String, String>(
        method,
        Stream.value('seed'),
        CallOptions(),
        (m, req, opts) => ResponseStream<String>(mockCall),
      );
      await stream.toList();
      drained.complete();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final captured = await completer.future;
      expect(captured['responseBody'], contains('one'));
      expect(captured['responseBody'], contains('two'));
      expect(captured['responseBody'], contains('three'));
      expect(
        captured['responseHeaders'],
        containsPair('x-luciq-stream-message-count', '3'),
      );
    });

    test('treats malformed grpc-status as UNKNOWN, not OK', () async {
      final completer = Completer<Map<String, dynamic>>();
      when(mHost.networkLog(any)).thenAnswer((invocation) {
        final data = invocation.positionalArguments[0] as Map<String, dynamic>;
        if (!completer.isCompleted) completer.complete(data);
        return Future<void>.value();
      });

      final interceptor = LuciqGrpcInterceptor();
      final mockCall = createMockCall(
        trailers: {'grpc-status': 'not-a-number'},
      );

      interceptor.interceptStreaming<String, String>(
        method,
        Stream.value('test request'),
        CallOptions(),
        (m, req, opts) => ResponseStream<String>(mockCall),
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final captured = await completer.future;
      expect(captured['responseCode'], 500);
      expect(captured['errorDomain'], 'grpc');
      expect(captured['errorCode'], StatusCode.unknown);
    });

    test('logs streaming call error', () async {
      final completer = Completer<Map<String, dynamic>>();
      when(mHost.networkLog(any)).thenAnswer((invocation) {
        final data = invocation.positionalArguments[0] as Map<String, dynamic>;
        if (!completer.isCompleted) completer.complete(data);
        return Future<void>.value();
      });

      final interceptor = LuciqGrpcInterceptor();
      final mockCall = createMockCall(
        shouldError: true,
        error: const GrpcError.unavailable('service unavailable'),
      );

      interceptor.interceptStreaming<String, String>(
        method,
        Stream.value('test request'),
        CallOptions(),
        (m, req, opts) => ResponseStream<String>(mockCall),
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final capturedData = await completer.future;
      expect(capturedData['url'], '/test.Service/GetData');
      expect(capturedData['responseCode'], 503);
      expect(capturedData['errorDomain'], 'grpc');
    });
  });
}

class _FakeProto {
  _FakeProto({required this.name, this.bytes});

  final String name;
  final List<int>? bytes;

  Map<String, dynamic> toProto3Json() => <String, dynamic>{'name': name};

  List<int> writeToBuffer() => bytes ?? List<int>.filled(name.length * 2, 0);
}
