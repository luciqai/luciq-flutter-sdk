import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luciq_dio_interceptor/luciq_dio_interceptor.dart';
import 'package:luciq_flutter/luciq_flutter.dart';
import 'package:luciq_flutter/src/generated/luciq.api.g.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'luciq_dio_interceptor_test.mocks.dart';
import 'mock_adapter.dart';

class MyInterceptor extends LuciqDioInterceptor {
  int requestCount = 0;
  int resposneCount = 0;
  int errorCount = 0;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    requestCount++;
    super.onRequest(options, handler);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    resposneCount++;
    super.onResponse(response, handler);
  }

  @override
  // ignore: deprecated_member_use
  void onError(DioError err, ErrorInterceptorHandler handler) {
    errorCount++;
    super.onError(err, handler);
  }
}

@GenerateMocks(<Type>[
  LuciqHostApi,
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();

  final mHost = MockLuciqHostApi();

  late Dio dio;
  late MyInterceptor luciqDioInterceptor;
  const appToken = '068ba9a8c3615035e163dc5f829c73be';

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
  });

  setUp(() {
    dio = Dio();
    dio.options.baseUrl = MockAdapter.mockBase;
    dio.httpClientAdapter = MockAdapter();
    final events = <InvocationEvent>[];
    luciqDioInterceptor = MyInterceptor();
    dio.interceptors.add(luciqDioInterceptor);
    Luciq.init(token: appToken, invocationEvents: events);
  });

  test('onResponse Test', () async {
    try {
      await dio.get<dynamic>('/test');
      // ignore: deprecated_member_use
    } on DioError {
      // ignor
    }

    expect(luciqDioInterceptor.requestCount, 1);
    expect(luciqDioInterceptor.resposneCount, 1);
    expect(luciqDioInterceptor.errorCount, 0);
  });

  test('onError Test', () async {
    try {
      await dio.get<dynamic>('/test-error');
      // ignore: deprecated_member_use
    } on DioError {
      // ignor
    }

    expect(luciqDioInterceptor.requestCount, 1);
    expect(luciqDioInterceptor.resposneCount, 0);
    expect(luciqDioInterceptor.errorCount, 1);
  });

  test('Stress Test', () async {
    for (var i = 0; i < 1000; i++) {
      try {
        await dio.get<dynamic>('/test');
        // ignore: deprecated_member_use
      } on DioError {
        // ignor
      }
    }
    expect(luciqDioInterceptor.requestCount, 1000);
  });

  test('Response headers with single value are mapped correctly', () async {
    final completer = Completer<Map<String, dynamic>>();
    when(mHost.networkLog(any)).thenAnswer((invocation) {
      final data = invocation.positionalArguments[0] as Map<String, dynamic>;
      completer.complete(data);
      return Future<void>.value();
    });

    await dio.get('/test-single-header');
    final capturedNetworkLog = await completer.future;

    expect(luciqDioInterceptor.resposneCount, 1);
    final responseHeaders =
        capturedNetworkLog['responseHeaders'] as Map<String, dynamic>;
    expect(responseHeaders['x-custom-header'], 'single-value');
  });

  test('Response headers with multiple values are joined with comma', () async {
    final completer = Completer<Map<String, dynamic>>();
    when(mHost.networkLog(any)).thenAnswer((invocation) {
      final data = invocation.positionalArguments[0] as Map<String, dynamic>;
      completer.complete(data);
      return Future<void>.value();
    });

    await dio.get('/test-multi-header');
    final capturedNetworkLog = await completer.future;

    expect(luciqDioInterceptor.resposneCount, 1);
    final responseHeaders =
        capturedNetworkLog['responseHeaders'] as Map<String, dynamic>;
    expect(responseHeaders['x-custom-header'], 'value1, value2');
  });
}
