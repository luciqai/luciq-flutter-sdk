import 'dart:convert';
import 'dart:io';
// to maintain supported versions prior to Flutter 3.3
// ignore: unnecessary_import
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:luciq_flutter/luciq_flutter.dart';
import 'package:luciq_flutter/src/generated/luciq.api.g.dart';
import 'package:luciq_http_client/luciq_http_client.dart';
import 'package:luciq_http_client/luciq_http_logger.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'luciq_http_client_test.mocks.dart';

@GenerateMocks(<Type>[
  LuciqHttpLogger,
  LuciqHttpClient,
  LuciqHostApi,
])
Future<void> main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final mHost = MockLuciqHostApi();

  setUpAll(() {
    Luciq.$setHostApi(mHost);
    NetworkLogger.$setHostApi(mHost);
    when(mHost.isW3CFeatureFlagsEnabled()).thenAnswer(
      (_) => Future<Map<String, bool>>.value(<String, bool>{
        'isW3cCaughtHeaderEnabled': true,
        'isW3cExternalGeneratedHeaderEnabled': false,
        'isW3cExternalTraceIDEnabled': true,
      }),
    );
  });

  const fakeResponse = <String, String>{
    'id': '123',
    'activationCode': '111111',
  };
  late Uri url;
  final mockedResponse = http.Response(json.encode(fakeResponse), 200);

  late LuciqHttpClient luciqHttpClient;

  setUp(() {
    url = Uri.parse('http://www.luciq.ai');
    luciqHttpClient = LuciqHttpClient();
    luciqHttpClient.client = MockLuciqHttpClient();
    luciqHttpClient.logger = MockLuciqHttpLogger();
  });

  test('expect luciq http client GET to return response', () async {
    when<dynamic>(
      luciqHttpClient.client.get(url, headers: anyNamed('headers')),
    ).thenAnswer((_) async => mockedResponse);
    final result = await luciqHttpClient.get(url);
    expect(result, isInstanceOf<http.Response>());
    expect(result, mockedResponse);
    verify(
      luciqHttpClient.logger
          .onLogger(mockedResponse, startTime: anyNamed('startTime')),
    ).called(1);
  });

  test('expect luciq http client HEAD to return response', () async {
    when<dynamic>(
      luciqHttpClient.client.head(url, headers: anyNamed('headers')),
    ).thenAnswer((_) async => mockedResponse);
    final result = await luciqHttpClient.head(url);
    expect(result, isInstanceOf<http.Response>());
    expect(result, mockedResponse);
    verify(
      luciqHttpClient.logger
          .onLogger(mockedResponse, startTime: anyNamed('startTime')),
    ).called(1);
  });

  test('expect luciq http client DELETE to return response', () async {
    when<dynamic>(
      luciqHttpClient.client.delete(url, headers: anyNamed('headers')),
    ).thenAnswer((_) async => mockedResponse);
    final result = await luciqHttpClient.delete(url);
    expect(result, isInstanceOf<http.Response>());
    expect(result, mockedResponse);
    verify(
      luciqHttpClient.logger
          .onLogger(mockedResponse, startTime: anyNamed('startTime')),
    ).called(1);
  });

  test('expect luciq http client PATCH to return response', () async {
    when<dynamic>(
      luciqHttpClient.client.patch(url, headers: anyNamed('headers')),
    ).thenAnswer((_) async => mockedResponse);
    final result = await luciqHttpClient.patch(url);
    expect(result, isInstanceOf<http.Response>());
    expect(result, mockedResponse);
    verify(
      luciqHttpClient.logger
          .onLogger(mockedResponse, startTime: anyNamed('startTime')),
    ).called(1);
  });

  test('expect luciq http client POST to return response', () async {
    when<dynamic>(
      luciqHttpClient.client.post(url, headers: anyNamed('headers')),
    ).thenAnswer((_) async => mockedResponse);
    final result = await luciqHttpClient.post(url);
    expect(result, isInstanceOf<http.Response>());
    expect(result, mockedResponse);
    verify(
      luciqHttpClient.logger
          .onLogger(mockedResponse, startTime: anyNamed('startTime')),
    ).called(1);
  });

  test('expect luciq http client PUT to return response', () async {
    when<dynamic>(
      luciqHttpClient.client.put(url, headers: anyNamed('headers')),
    ).thenAnswer((_) async => mockedResponse);
    final result = await luciqHttpClient.put(url);
    expect(result, isInstanceOf<http.Response>());
    expect(result.body, mockedResponse.body);
    verify(
      luciqHttpClient.logger
          .onLogger(mockedResponse, startTime: anyNamed('startTime')),
    ).called(1);
  });

  test('expect luciq http client READ to return response', () async {
    const response = 'Some response string';
    when<dynamic>(
      luciqHttpClient.client.read(url, headers: anyNamed('headers')),
    ).thenAnswer((_) async => response);

    final result = await luciqHttpClient.read(url);
    expect(result, isInstanceOf<String>());
    expect(result, response);
  });

  test('expect luciq http client READBYTES to return response', () async {
    final response = Uint8List(3);
    luciqHttpClient.client =
        MockClient((_) async => http.Response.bytes(response, 200));

    final result = await luciqHttpClient.readBytes(url);
    expect(result, isInstanceOf<Uint8List>());
    expect(result, response);
  });

  test('expect luciq http client SEND to return response', () async {
    final response = http.StreamedResponse(
      const Stream<List<int>>.empty(),
      200,
      contentLength: 0,
    );
    final request = http.StreamedRequest('POST', url)
      ..headers[HttpHeaders.contentTypeHeader] =
          'application/json; charset=utf-8'
      ..headers[HttpHeaders.userAgentHeader] = 'Dart';
    when<dynamic>(luciqHttpClient.client.send(request))
        .thenAnswer((_) async => response);
    final responseFuture = luciqHttpClient.send(request);
    request
      ..sink.add('{"hello": "world"}'.codeUnits)
      ..sink.close();

    final result = await responseFuture;
    expect(result, isInstanceOf<http.StreamedResponse>());
    expect(result.headers, response.headers);
    expect(result.statusCode, response.statusCode);
    expect(result.contentLength, response.contentLength);
    expect(result.isRedirect, response.isRedirect);
    expect(result.persistentConnection, response.persistentConnection);
    expect(result.reasonPhrase, response.reasonPhrase);
    expect(result.request, response.request);
    expect(
      await result.stream.bytesToString(),
      await response.stream.bytesToString(),
    );
    final logger = luciqHttpClient.logger as MockLuciqHttpLogger;
    verify(logger.onLogger(any, startTime: anyNamed('startTime'))).called(1);
  });

  test('expect luciq http client CLOSE to be called', () async {
    luciqHttpClient.close();

    verify(luciqHttpClient.client.close());
  });

  test('stress test for GET method', () async {
    when<dynamic>(
      luciqHttpClient.client.get(url, headers: anyNamed('headers')),
    ).thenAnswer((_) async => mockedResponse);
    for (var i = 0; i < 10000; i++) {
      await luciqHttpClient.get(url);
    }
    verify(
      luciqHttpClient.logger
          .onLogger(mockedResponse, startTime: anyNamed('startTime')),
    ).called(10000);
  });
}
