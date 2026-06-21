import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gql/language.dart' as gql;
import 'package:gql_exec/gql_exec.dart';
import 'package:gql_http_link/gql_http_link.dart';
import 'package:gql_link/gql_link.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;
import 'package:luciq_flutter/luciq_flutter.dart';
import 'package:luciq_flutter/src/generated/luciq.api.g.dart';
import 'package:luciq_flutter/src/utils/luciq_logger.dart';
import 'package:luciq_gql_link/luciq_gql_link.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'luciq_gql_link_test.mocks.dart';

@GenerateMocks(<Type>[
  LuciqHostApi,
  LuciqLogger,
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();

  final mHost = MockLuciqHostApi();
  final mLogger = MockLuciqLogger();

  setUpAll(() {
    Luciq.$setHostApi(mHost);
    NetworkLogger.$setHostApi(mHost);
    LuciqLogger.setInstance(mLogger);
    when(mLogger.isDebugEnabled()).thenReturn(false);
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

  final queryDocument = gql.parseString('''
    query GetUser(\$id: ID!) {
      user(id: \$id) {
        id
        name
        email
      }
    }
  ''');

  final mutationDocument = gql.parseString('''
    mutation CreateUser(\$input: CreateUserInput!) {
      createUser(input: \$input) {
        id
        name
      }
    }
  ''');

  final subscriptionDocument = gql.parseString('''
    subscription OnMessageAdded(\$channelId: ID!) {
      messageAdded(channelId: \$channelId) {
        id
        content
      }
    }
  ''');

  NextLink mockForwardWith(List<Response> responses) {
    return (Request request) => Stream.fromIterable(
          responses.map(
            (r) => r.context.entry<HttpLinkResponseContext>() != null
                ? r
                : r.withContextEntry(
                    const HttpLinkResponseContext(
                      statusCode: 200,
                      headers: <String, String>{},
                    ),
                  ),
          ),
        );
  }

  NextLink mockForwardRaw(List<Response> responses) {
    return (Request request) => Stream.fromIterable(responses);
  }

  NextLink mockForwardWithError(Object error) {
    return (Request request) => Stream.error(error);
  }

  group('LuciqGqlLink - query operations', () {
    test('logs a query operation with correct URL and method', () async {
      final completer = Completer<Map<String, dynamic>>();
      when(mHost.networkLog(any)).thenAnswer((invocation) {
        final data = invocation.positionalArguments[0] as Map<String, dynamic>;
        if (!completer.isCompleted) completer.complete(data);
        return Future<void>.value();
      });

      final link = LuciqGqlLink(endpoint: 'https://api.example.com/graphql');
      final request = Request(
        operation: Operation(
          document: queryDocument,
          operationName: 'GetUser',
        ),
        variables: const {'id': '123'},
      );

      final forward = mockForwardWith([
        const Response(
          data: {
            'user': {'id': '123', 'name': 'Test', 'email': 'test@test.com'},
          },
          response: {},
        ),
      ]);

      await link.request(request, forward).first;
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final capturedData = await completer.future;
      expect(capturedData['url'], 'https://api.example.com/graphql (GetUser)');
      expect(capturedData['method'], 'POST');
      expect(capturedData['responseCode'], 200);
      expect(capturedData['requestContentType'], 'application/json');
      expect(capturedData['responseContentType'], 'application/json');
      expect(capturedData['gqlQueryName'], 'GetUser');
    });

    test('includes query, operationName, and variables in request body',
        () async {
      final completer = Completer<Map<String, dynamic>>();
      when(mHost.networkLog(any)).thenAnswer((invocation) {
        final data = invocation.positionalArguments[0] as Map<String, dynamic>;
        if (!completer.isCompleted) completer.complete(data);
        return Future<void>.value();
      });

      final link = LuciqGqlLink();
      final request = Request(
        operation: Operation(
          document: queryDocument,
          operationName: 'GetUser',
        ),
        variables: const {'id': '123'},
      );

      final forward = mockForwardWith([
        const Response(data: {'user': null}, response: {}),
      ]);

      await link.request(request, forward).first;
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final capturedData = await completer.future;
      final requestBody = capturedData['requestBody'] as String;
      expect(requestBody, contains('query'));
      expect(requestBody, contains('GetUser'));
      expect(requestBody, contains('operationName'));
      expect(requestBody, contains('variables'));
    });

    test('uses endpoint as URL when no operation name', () async {
      final completer = Completer<Map<String, dynamic>>();
      when(mHost.networkLog(any)).thenAnswer((invocation) {
        final data = invocation.positionalArguments[0] as Map<String, dynamic>;
        if (!completer.isCompleted) completer.complete(data);
        return Future<void>.value();
      });

      final link = LuciqGqlLink(endpoint: 'https://api.example.com/graphql');
      final anonymousQuery = gql.parseString('{ users { id name } }');
      final request = Request(
        operation: Operation(document: anonymousQuery),
      );

      final forward = mockForwardWith([
        const Response(data: {'users': []}, response: {}),
      ]);

      await link.request(request, forward).first;
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final capturedData = await completer.future;
      expect(capturedData['url'], 'https://api.example.com/graphql');
      expect(capturedData['gqlQueryName'], isNull);
    });
  });

  group('LuciqGqlLink - mutation operations', () {
    test('logs a mutation operation', () async {
      final completer = Completer<Map<String, dynamic>>();
      when(mHost.networkLog(any)).thenAnswer((invocation) {
        final data = invocation.positionalArguments[0] as Map<String, dynamic>;
        if (!completer.isCompleted) completer.complete(data);
        return Future<void>.value();
      });

      final link = LuciqGqlLink();
      final request = Request(
        operation: Operation(
          document: mutationDocument,
          operationName: 'CreateUser',
        ),
        variables: const {
          'input': {'name': 'New User'},
        },
      );

      final forward = mockForwardWith([
        const Response(
          data: {
            'createUser': {'id': '456', 'name': 'New User'},
          },
          response: {},
        ),
      ]);

      await link.request(request, forward).first;
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final capturedData = await completer.future;
      expect(capturedData['url'], 'graphql (CreateUser)');
      expect(capturedData['responseCode'], 200);
      expect(capturedData['gqlQueryName'], 'CreateUser');
    });
  });

  group('LuciqGqlLink - error handling', () {
    test('logs GraphQL errors in response body', () async {
      final completer = Completer<Map<String, dynamic>>();
      when(mHost.networkLog(any)).thenAnswer((invocation) {
        final data = invocation.positionalArguments[0] as Map<String, dynamic>;
        if (!completer.isCompleted) completer.complete(data);
        return Future<void>.value();
      });

      final link = LuciqGqlLink();
      final request = Request(
        operation: Operation(
          document: queryDocument,
          operationName: 'GetUser',
        ),
        variables: const {'id': '999'},
      );

      final forward = mockForwardWith([
        const Response(
          errors: [
            GraphQLError(
              message: 'User not found',
              path: ['user'],
            ),
          ],
          response: {},
        ),
      ]);

      await link.request(request, forward).first;
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final capturedData = await completer.future;
      expect(capturedData['responseCode'], 200);
      final responseBody = capturedData['responseBody'] as String;
      expect(responseBody, contains('User not found'));
      expect(responseBody, contains('errors'));
    });

    test('surfaces first GraphQL error message as errorName', () async {
      final completer = Completer<Map<String, dynamic>>();
      when(mHost.networkLog(any)).thenAnswer((invocation) {
        final data = invocation.positionalArguments[0] as Map<String, dynamic>;
        if (!completer.isCompleted) completer.complete(data);
        return Future<void>.value();
      });

      final link = LuciqGqlLink();
      final request = Request(
        operation: Operation(
          document: queryDocument,
          operationName: 'GetUser',
        ),
      );

      final forward = mockForwardWith([
        const Response(
          errors: [
            GraphQLError(message: 'User not found'),
            GraphQLError(message: 'Secondary error ignored'),
          ],
          response: {},
        ),
      ]);

      await link.request(request, forward).first;
      final captured = await completer.future;
      expect(captured['errorName'], 'User not found');
    });

    test('errorName is null on a successful response with no errors', () async {
      final completer = Completer<Map<String, dynamic>>();
      when(mHost.networkLog(any)).thenAnswer((invocation) {
        final data = invocation.positionalArguments[0] as Map<String, dynamic>;
        if (!completer.isCompleted) completer.complete(data);
        return Future<void>.value();
      });

      final link = LuciqGqlLink();
      final request = Request(
        operation: Operation(
          document: queryDocument,
          operationName: 'GetUser',
        ),
      );

      final forward = mockForwardWith([
        const Response(data: {'user': null}, response: {}),
      ]);

      await link.request(request, forward).first;
      final captured = await completer.future;
      expect(captured['errorName'], isNull);
    });

    test('errorName extracts message from HttpLinkServerException JSON body',
        () async {
      final completer = Completer<Map<String, dynamic>>();
      when(mHost.networkLog(any)).thenAnswer((invocation) {
        final data = invocation.positionalArguments[0] as Map<String, dynamic>;
        if (!completer.isCompleted) completer.complete(data);
        return Future<void>.value();
      });

      final link = LuciqGqlLink();
      final request = Request(
        operation: Operation(
          document: queryDocument,
          operationName: 'GetUser',
        ),
      );

      final exception = HttpLinkServerException(
        response: http.Response(
          jsonEncode({
            'errors': [
              {'message': 'Unauthorized'},
            ],
          }),
          401,
          headers: const {'content-type': 'application/json'},
        ),
        parsedResponse: const Response(response: {}),
      );

      try {
        await link.request(request, mockForwardWithError(exception)).first;
      } catch (_) {
        // expected
      }

      final captured = await completer.future;
      expect(captured['errorName'], 'Unauthorized');
    });

    test('errorName falls back to runtime type when no parseable body',
        () async {
      final completer = Completer<Map<String, dynamic>>();
      when(mHost.networkLog(any)).thenAnswer((invocation) {
        final data = invocation.positionalArguments[0] as Map<String, dynamic>;
        if (!completer.isCompleted) completer.complete(data);
        return Future<void>.value();
      });

      final link = LuciqGqlLink();
      final request = Request(
        operation: Operation(
          document: queryDocument,
          operationName: 'GetUser',
        ),
      );

      try {
        await link
            .request(request, mockForwardWithError(Exception('boom')))
            .first;
      } catch (_) {
        // expected
      }

      final captured = await completer.future;
      // Exception('boom').runtimeType is '_Exception'.
      expect(captured['errorName'], '_Exception');
    });

    test('logs transport errors with error domain', () async {
      final completer = Completer<Map<String, dynamic>>();
      when(mHost.networkLog(any)).thenAnswer((invocation) {
        final data = invocation.positionalArguments[0] as Map<String, dynamic>;
        if (!completer.isCompleted) completer.complete(data);
        return Future<void>.value();
      });

      final link = LuciqGqlLink();
      final request = Request(
        operation: Operation(
          document: queryDocument,
          operationName: 'GetUser',
        ),
      );

      final forward = mockForwardWithError(Exception('Network failed'));

      try {
        await link.request(request, forward).first;
      } catch (_) {
        // Expected error
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final capturedData = await completer.future;
      expect(capturedData['errorDomain'], 'graphql');
      expect(capturedData['responseBody'], contains('Network failed'));
      expect(capturedData['gqlQueryName'], 'GetUser');
    });
  });

  group('LuciqGqlLink - subscription handling', () {
    test('logs each subscription event individually', () async {
      var logCount = 0;
      final allLogs = <Map<String, dynamic>>[];
      when(mHost.networkLog(any)).thenAnswer((invocation) {
        final data = invocation.positionalArguments[0] as Map<String, dynamic>;
        allLogs.add(data);
        logCount++;
        return Future<void>.value();
      });

      final link = LuciqGqlLink();
      final request = Request(
        operation: Operation(
          document: subscriptionDocument,
          operationName: 'OnMessageAdded',
        ),
        variables: const {'channelId': 'ch-1'},
      );

      final forward = mockForwardWith([
        const Response(
          data: {
            'messageAdded': {'id': '1', 'content': 'Hello'},
          },
          response: {},
        ),
        const Response(
          data: {
            'messageAdded': {'id': '2', 'content': 'World'},
          },
          response: {},
        ),
        const Response(
          data: {
            'messageAdded': {'id': '3', 'content': '!'},
          },
          response: {},
        ),
      ]);

      await link.request(request, forward).toList();
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(logCount, 3);
      for (final log in allLogs) {
        expect(log['url'], 'graphql (OnMessageAdded)');
        expect(log['responseCode'], 200);
      }
    });
  });

  group('LuciqGqlLink - subscription lifecycle', () {
    test(
        'logs N successful events then logs error when stream errors midflight',
        () async {
      final captured = <Map<String, dynamic>>[];
      when(mHost.networkLog(any)).thenAnswer((invocation) {
        captured.add(invocation.positionalArguments[0] as Map<String, dynamic>);
        return Future<void>.value();
      });

      final link = LuciqGqlLink();
      final request = Request(
        operation: Operation(
          document: subscriptionDocument,
          operationName: 'OnMessageAdded',
        ),
        variables: const {'channelId': 'ch'},
      );

      Stream<Response> midFlightError() async* {
        yield const Response(
          data: {
            'messageAdded': {'id': '1', 'content': 'a'},
          },
          response: {},
        );
        yield const Response(
          data: {
            'messageAdded': {'id': '2', 'content': 'b'},
          },
          response: {},
        );
        throw Exception('socket closed');
      }

      try {
        await link.request(request, (_) => midFlightError()).toList();
      } catch (_) {
        // expected rethrow after the third (error) event is logged.
      }
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(captured.length, 3);
      for (final entry in captured) {
        expect(entry['gqlQueryName'], 'OnMessageAdded');
      }
      expect(captured.last['errorDomain'], 'graphql');
      expect(captured.last['responseBody'], contains('socket closed'));
      // The first two events are normal records, no errorDomain.
      expect(captured[0]['errorDomain'], '');
      expect(captured[1]['errorDomain'], '');
    });

    test('logs subscription events with null status on non-HTTP transport',
        () async {
      final captured = <Map<String, dynamic>>[];
      when(mHost.networkLog(any)).thenAnswer((invocation) {
        captured.add(invocation.positionalArguments[0] as Map<String, dynamic>);
        return Future<void>.value();
      });

      final link = LuciqGqlLink();
      final request = Request(
        operation: Operation(
          document: subscriptionDocument,
          operationName: 'OnMessageAdded',
        ),
        variables: const {'channelId': 'ch'},
      );

      // mockForwardRaw bypasses the default-200 HttpLinkResponseContext, so
      // every emission lacks HTTP framing — modelling a websocket transport.
      final forward = mockForwardRaw([
        const Response(
          data: {
            'messageAdded': {'id': '1', 'content': 'a'},
          },
          response: {},
        ),
        const Response(
          data: {
            'messageAdded': {'id': '2', 'content': 'b'},
          },
          response: {},
        ),
        const Response(
          data: {
            'messageAdded': {'id': '3', 'content': 'c'},
          },
          response: {},
        ),
      ]);

      await link.request(request, forward).toList();
      expect(captured.length, 3);
      for (final entry in captured) {
        expect(entry['responseCode'], isNull);
        expect(entry['gqlQueryName'], 'OnMessageAdded');
      }
    });
  });

  group('LuciqGqlLink - stress test', () {
    test('handles 1000 operations', () async {
      var logCount = 0;
      when(mHost.networkLog(any)).thenAnswer((_) {
        logCount++;
        return Future<void>.value();
      });

      final link = LuciqGqlLink();

      for (var i = 0; i < 1000; i++) {
        final request = Request(
          operation: Operation(
            document: queryDocument,
            operationName: 'GetUser',
          ),
          variables: {'id': '$i'},
        );

        final forward = mockForwardWith([
          const Response(
            data: {'user': null},
            response: {},
          ),
        ]);

        await link.request(request, forward).first;
      }

      await Future<void>.delayed(const Duration(milliseconds: 500));
      expect(logCount, 1000);
    });
  });

  group('LuciqGqlLink - edge cases', () {
    test('returns error stream when forward is null', () async {
      final link = LuciqGqlLink();
      final request = Request(
        operation: Operation(
          document: queryDocument,
          operationName: 'GetUser',
        ),
      );

      expect(
        () => link.request(request).first,
        throwsStateError,
      );
    });
  });

  group('LuciqGqlLink - HTTP context propagation', () {
    test('reads real status code and headers from HttpLinkResponseContext',
        () async {
      final completer = Completer<Map<String, dynamic>>();
      when(mHost.networkLog(any)).thenAnswer((invocation) {
        final data = invocation.positionalArguments[0] as Map<String, dynamic>;
        if (!completer.isCompleted) completer.complete(data);
        return Future<void>.value();
      });

      final link = LuciqGqlLink();
      final request = Request(
        operation: Operation(
          document: queryDocument,
          operationName: 'GetUser',
        ),
        variables: const {'id': '1'},
      );

      final forward = mockForwardWith([
        Response(
          data: const {'user': null},
          response: const {},
          context: const Context().withEntry(
            const HttpLinkResponseContext(
              statusCode: 503,
              headers: {
                'content-type': 'application/json; charset=utf-8',
                'x-trace-id': 'abc-123',
              },
            ),
          ),
        ),
      ]);

      await link.request(request, forward).first;
      final captured = await completer.future;

      expect(captured['responseCode'], 503);
      expect(
        captured['responseContentType'],
        'application/json; charset=utf-8',
      );
      final responseHeaders =
          captured['responseHeaders'] as Map<String, dynamic>;
      expect(responseHeaders['x-trace-id'], 'abc-123');
    });

    test('logs null status when response has no HttpLinkResponseContext',
        () async {
      final completer = Completer<Map<String, dynamic>>();
      when(mHost.networkLog(any)).thenAnswer((invocation) {
        final data = invocation.positionalArguments[0] as Map<String, dynamic>;
        if (!completer.isCompleted) completer.complete(data);
        return Future<void>.value();
      });

      final link = LuciqGqlLink();
      final request = Request(
        operation: Operation(
          document: queryDocument,
          operationName: 'GetUser',
        ),
        variables: const {'id': '1'},
      );

      // mockForwardRaw bypasses the default-200 fixture, modelling a
      // non-HTTP transport (e.g. an in-memory or websocket-backed link).
      final forward = mockForwardRaw([
        const Response(data: {'user': null}, response: {}),
      ]);

      await link.request(request, forward).first;
      final captured = await completer.future;

      expect(captured['responseCode'], isNull);
      expect(captured['responseContentType'], 'application/json');
    });

    test('falls back to exception toString when error response body is empty',
        () async {
      final completer = Completer<Map<String, dynamic>>();
      when(mHost.networkLog(any)).thenAnswer((invocation) {
        final data = invocation.positionalArguments[0] as Map<String, dynamic>;
        if (!completer.isCompleted) completer.complete(data);
        return Future<void>.value();
      });

      final link = LuciqGqlLink();
      final request = Request(
        operation: Operation(
          document: queryDocument,
          operationName: 'GetUser',
        ),
      );

      final exception = HttpLinkServerException(
        response: http.Response('', 504),
        parsedResponse: const Response(response: {}),
      );

      try {
        await link.request(request, mockForwardWithError(exception)).first;
      } catch (_) {
        // expected
      }

      final captured = await completer.future;
      expect(captured['responseCode'], 504);
      expect(captured['errorDomain'], 'graphql');
      final responseBody = captured['responseBody'] as String;
      expect(responseBody.isNotEmpty, true);
      // HttpLinkServerException.toString() renders as
      // 'ServerException(originalException: ..., parsedResponse: ...)'.
      expect(responseBody, contains('ServerException'));
    });

    test('extracts status, headers, and body from HttpLinkServerException',
        () async {
      final completer = Completer<Map<String, dynamic>>();
      when(mHost.networkLog(any)).thenAnswer((invocation) {
        final data = invocation.positionalArguments[0] as Map<String, dynamic>;
        if (!completer.isCompleted) completer.complete(data);
        return Future<void>.value();
      });

      final link = LuciqGqlLink();
      final request = Request(
        operation: Operation(
          document: queryDocument,
          operationName: 'GetUser',
        ),
      );

      final exception = HttpLinkServerException(
        response: http.Response(
          'gateway down',
          502,
          headers: const {'content-type': 'text/plain'},
        ),
        parsedResponse: const Response(response: {}),
      );

      try {
        await link.request(request, mockForwardWithError(exception)).first;
      } catch (_) {
        // expected rethrow
      }

      final captured = await completer.future;
      expect(captured['responseCode'], 502);
      expect(captured['responseBody'], 'gateway down');
      expect(captured['responseContentType'], 'text/plain');
      expect(captured['errorDomain'], 'graphql');
    });

    test('uses HttpLinkHeaders content-type for the request', () async {
      final completer = Completer<Map<String, dynamic>>();
      when(mHost.networkLog(any)).thenAnswer((invocation) {
        final data = invocation.positionalArguments[0] as Map<String, dynamic>;
        if (!completer.isCompleted) completer.complete(data);
        return Future<void>.value();
      });

      final link = LuciqGqlLink();
      final request = Request(
        operation: Operation(
          document: queryDocument,
          operationName: 'GetUser',
        ),
      ).withContextEntry(
        const HttpLinkHeaders(
          headers: {
            'content-type': 'application/graphql-response+json',
            'authorization': 'Bearer xyz',
          },
        ),
      );

      final forward = mockForwardWith([
        const Response(data: {'user': null}, response: {}),
      ]);

      await link.request(request, forward).first;
      final captured = await completer.future;

      expect(
        captured['requestContentType'],
        'application/graphql-response+json',
      );
      final requestHeaders = captured['requestHeaders'] as Map<String, dynamic>;
      expect(requestHeaders['authorization'], 'Bearer xyz');
    });
  });

  group('LuciqGqlLink - W3C tracing', () {
    test('injects generated traceparent into outgoing request', () async {
      final completer = Completer<Map<String, dynamic>>();
      when(mHost.networkLog(any)).thenAnswer((invocation) {
        final data = invocation.positionalArguments[0] as Map<String, dynamic>;
        if (!completer.isCompleted) completer.complete(data);
        return Future<void>.value();
      });

      Request? captured;
      Stream<Response> forward(Request request) {
        captured = request;
        return Stream<Response>.fromIterable([
          const Response(data: {'user': null}, response: {}),
        ]);
      }

      final link = LuciqGqlLink();
      final request = Request(
        operation: Operation(
          document: queryDocument,
          operationName: 'GetUser',
        ),
      );

      await link.request(request, forward).first;
      await completer.future;

      final wireHeaders = captured!.context.entry<HttpLinkHeaders>()?.headers;
      expect(wireHeaders, isNotNull);
      expect(wireHeaders!['traceparent'], isNotNull);
      // W3C traceparent format: 00-<32 hex>-<16 hex>-<2 hex>
      expect(
        RegExp(r'^[0-9a-f]{2}-[0-9a-f]{32}-[0-9a-f]{16}-[0-9a-f]{2}$')
            .hasMatch(wireHeaders['traceparent']!),
        true,
        reason: 'traceparent should match W3C format',
      );
    });

    test('preserves caller-supplied traceparent on the wire', () async {
      const inboundTraceparent =
          '00-0af7651916cd43dd8448eb211c80319c-b7ad6b7169203331-01';

      final completer = Completer<Map<String, dynamic>>();
      when(mHost.networkLog(any)).thenAnswer((invocation) {
        final data = invocation.positionalArguments[0] as Map<String, dynamic>;
        if (!completer.isCompleted) completer.complete(data);
        return Future<void>.value();
      });

      Request? captured;
      Stream<Response> forward(Request request) {
        captured = request;
        return Stream<Response>.fromIterable([
          const Response(data: {'user': null}, response: {}),
        ]);
      }

      final link = LuciqGqlLink();
      final request = Request(
        operation: Operation(
          document: queryDocument,
          operationName: 'GetUser',
        ),
      ).withContextEntry(
        const HttpLinkHeaders(headers: {'traceparent': inboundTraceparent}),
      );

      await link.request(request, forward).first;
      final captureData = await completer.future;

      final wireHeaders = captured!.context.entry<HttpLinkHeaders>()?.headers;
      expect(wireHeaders!['traceparent'], inboundTraceparent);
      expect(captureData['w3CCaughtHeader'], inboundTraceparent);
    });
  });

  group('LuciqGqlLink - operation-type tagging', () {
    test('tags request log with operation type header', () async {
      final completer = Completer<Map<String, dynamic>>();
      when(mHost.networkLog(any)).thenAnswer((invocation) {
        final data = invocation.positionalArguments[0] as Map<String, dynamic>;
        if (!completer.isCompleted) completer.complete(data);
        return Future<void>.value();
      });

      final link = LuciqGqlLink();
      final request = Request(
        operation: Operation(
          document: mutationDocument,
          operationName: 'CreateUser',
        ),
        variables: const {
          'input': {'name': 'X'},
        },
      );

      final forward = mockForwardWith([
        const Response(data: {'createUser': null}, response: {}),
      ]);

      await link.request(request, forward).first;
      final captured = await completer.future;
      final requestHeaders = captured['requestHeaders'] as Map<String, dynamic>;
      expect(requestHeaders['x-luciq-graphql-operation-type'], 'mutation');
    });

    test('tags as unknown when no executable operation is present', () async {
      final completer = Completer<Map<String, dynamic>>();
      when(mHost.networkLog(any)).thenAnswer((invocation) {
        final data = invocation.positionalArguments[0] as Map<String, dynamic>;
        if (!completer.isCompleted) completer.complete(data);
        return Future<void>.value();
      });

      final link = LuciqGqlLink();
      final fragmentOnly = gql.parseString(
        'fragment UserFields on User { id name }',
      );
      final request = Request(
        operation: Operation(document: fragmentOnly),
      );

      final forward = mockForwardWith([
        const Response(data: <String, dynamic>{}, response: {}),
      ]);

      await link.request(request, forward).first;
      final captured = await completer.future;
      final requestHeaders = captured['requestHeaders'] as Map<String, dynamic>;
      expect(requestHeaders['x-luciq-graphql-operation-type'], 'unknown');
    });
  });

  group('LuciqGqlLink - subscription per-event timing', () {
    test('startTime advances per emission', () async {
      final captured = <Map<String, dynamic>>[];
      when(mHost.networkLog(any)).thenAnswer((invocation) {
        captured.add(invocation.positionalArguments[0] as Map<String, dynamic>);
        return Future<void>.value();
      });

      final link = LuciqGqlLink();
      final request = Request(
        operation: Operation(
          document: subscriptionDocument,
          operationName: 'OnMessageAdded',
        ),
        variables: const {'channelId': 'ch'},
      );

      Stream<Response> spaced() async* {
        yield const Response(
          data: {
            'messageAdded': {'id': '1', 'content': 'a'},
          },
          response: {},
        );
        await Future<void>.delayed(const Duration(milliseconds: 30));
        yield const Response(
          data: {
            'messageAdded': {'id': '2', 'content': 'b'},
          },
          response: {},
        );
        await Future<void>.delayed(const Duration(milliseconds: 30));
        yield const Response(
          data: {
            'messageAdded': {'id': '3', 'content': 'c'},
          },
          response: {},
        );
      }

      await link.request(request, (_) => spaced()).toList();
      expect(captured.length, 3);

      final startTimes =
          captured.map((c) => c['startTime'] as int).toList(growable: false);
      expect(
        startTimes[0] <= startTimes[1] && startTimes[1] <= startTimes[2],
        true,
        reason: 'subscription startTimes should be monotonic',
      );

      // Second and third events' duration should reflect the inter-event gap,
      // not the time since subscription open. Since waits are ~30ms, the
      // duration should be at most a few hundred ms — well under the cumulative
      // total of all gaps.
      final duration2 = captured[1]['duration'] as int;
      final duration3 = captured[2]['duration'] as int;
      // duration is microseconds; 30ms == 30000us. Allow generous slack.
      expect(duration2 < 500000, true);
      expect(duration3 < 500000, true);
    });
  });

  group('LuciqGqlLink - body sizing & W3C invocation', () {
    test('requestBodySize matches utf8 byte length for multi-byte payloads',
        () async {
      final completer = Completer<Map<String, dynamic>>();
      when(mHost.networkLog(any)).thenAnswer((invocation) {
        final data = invocation.positionalArguments[0] as Map<String, dynamic>;
        if (!completer.isCompleted) completer.complete(data);
        return Future<void>.value();
      });

      final link = LuciqGqlLink();
      final request = Request(
        operation: Operation(
          document: queryDocument,
          operationName: 'GetUser',
        ),
        // Includes multi-byte CJK characters; UTF-16 code-unit count would
        // under-count compared to UTF-8 bytes.
        variables: const {'id': '你好-世界'},
      );

      final forward = mockForwardWith([
        const Response(data: {'user': null}, response: {}),
      ]);

      await link.request(request, forward).first;
      final captured = await completer.future;
      final requestBody = captured['requestBody'] as String;
      final reportedSize = captured['requestBodySize'] as int;

      expect(reportedSize, utf8.encode(requestBody).length);
      // Sanity: utf-8 byte count should exceed code-unit count for this input.
      expect(reportedSize > requestBody.codeUnits.length, true);
    });

    test('does not invoke W3C feature flag check more than once per request',
        () async {
      clearInteractions(mHost);
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

      final link = LuciqGqlLink();
      final request = Request(
        operation: Operation(
          document: queryDocument,
          operationName: 'GetUser',
        ),
      );
      final forward = mockForwardWith([
        const Response(data: {'user': null}, response: {}),
      ]);

      await link.request(request, forward).first;
      // Allow the network-log internal pipeline to settle.
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Exactly one W3C check: from LuciqGqlLink.request. NetworkLogger
      // should NOT re-invoke it via networkLog -> getW3CHeader because we
      // call networkLogInternal directly.
      verify(mHost.isW3CFeatureFlagsEnabled()).called(1);
    });
  });

  group('LuciqGqlLink - debug logging', () {
    setUp(() => clearInteractions(mLogger));

    test('logs error when forward is null', () async {
      final link = LuciqGqlLink();
      final request = Request(
        operation: Operation(
          document: queryDocument,
          operationName: 'GetUser',
        ),
      );

      try {
        await link.request(request).first;
      } catch (_) {
        // expected
      }

      verify(
        mLogger.e(
          argThat(contains('forward is null')),
          tag: 'LuciqGqlLink',
        ),
      ).called(1);
    });

    test('logs request entry and response on successful query', () async {
      when(mHost.networkLog(any)).thenAnswer((_) => Future<void>.value());

      final link = LuciqGqlLink();
      final request = Request(
        operation: Operation(
          document: queryDocument,
          operationName: 'GetUser',
        ),
        variables: const {'id': '1'},
      );
      final forward = mockForwardWith([
        const Response(data: {'user': null}, response: {}),
      ]);

      await link.request(request, forward).first;
      await Future<void>.delayed(const Duration(milliseconds: 50));

      verify(
        mLogger.d(
          argThat(allOf(
            contains('request:'),
            contains('type=query'),
            contains('name=GetUser'),
          ),),
          tag: 'LuciqGqlLink',
        ),
      ).called(1);
      verify(
        mLogger.d(
          argThat(allOf(
            contains('response:'),
            contains('status=200'),
            contains('gqlErrors=0'),
          ),),
          tag: 'LuciqGqlLink',
        ),
      ).called(1);
    });

    test('logs error on HttpLinkServerException with status', () async {
      when(mHost.networkLog(any)).thenAnswer((_) => Future<void>.value());

      final link = LuciqGqlLink();
      final request = Request(
        operation: Operation(
          document: queryDocument,
          operationName: 'GetUser',
        ),
      );
      final exception = HttpLinkServerException(
        response: http.Response(
          'down',
          502,
          headers: const {'content-type': 'text/plain'},
        ),
        parsedResponse: const Response(response: {}),
      );

      try {
        await link.request(request, mockForwardWithError(exception)).first;
      } catch (_) {
        // expected
      }
      await Future<void>.delayed(const Duration(milliseconds: 50));

      verify(
        mLogger.e(
          argThat(allOf(
            contains('error:'),
            contains('status=502'),
            contains('name=GetUser'),
          ),),
          tag: 'LuciqGqlLink',
        ),
      ).called(1);
    });

    test('logs error when request body encoding falls back', () async {
      when(mHost.networkLog(any)).thenAnswer((_) => Future<void>.value());

      final link = LuciqGqlLink();
      final request = Request(
        operation: Operation(
          document: queryDocument,
          operationName: 'GetUser',
        ),
        variables: {'oops': _NotEncodable()},
      );
      final forward = mockForwardWith([
        const Response(data: {'user': null}, response: {}),
      ]);

      await link.request(request, forward).first;
      await Future<void>.delayed(const Duration(milliseconds: 50));

      verify(
        mLogger.e(
          argThat(contains('request body encode failed')),
          tag: 'LuciqGqlLink',
        ),
      ).called(1);
    });
  });

  group('LuciqGqlLink - integration with HttpLink', () {
    test(
        'routes a real HttpLink response through LuciqGqlLink with status and headers',
        () async {
      final completer = Completer<Map<String, dynamic>>();
      when(mHost.networkLog(any)).thenAnswer((invocation) {
        final data = invocation.positionalArguments[0] as Map<String, dynamic>;
        if (!completer.isCompleted) completer.complete(data);
        return Future<void>.value();
      });

      http.Request? sentRequest;
      final mockClient = http_testing.MockClient((request) async {
        sentRequest = request;
        return http.Response(
          jsonEncode({
            'data': {
              'user': {'id': '1', 'name': 'Ada'},
            },
          }),
          200,
          headers: {
            'content-type': 'application/json',
            'x-server': 'mock-1',
          },
        );
      });

      final link = Link.from([
        LuciqGqlLink(endpoint: 'http://x/graphql'),
        HttpLink('http://x/graphql', httpClient: mockClient),
      ]);
      final request = Request(
        operation: Operation(
          document: queryDocument,
          operationName: 'GetUser',
        ),
        variables: const {'id': '1'},
      );

      await link.request(request).first;
      final captured = await completer.future;

      expect(captured['responseCode'], 200);
      expect(captured['gqlQueryName'], 'GetUser');
      final responseHeaders =
          captured['responseHeaders'] as Map<String, dynamic>;
      expect(responseHeaders['x-server'], 'mock-1');
      // The generated traceparent should reach the wire request.
      expect(sentRequest!.headers['traceparent'], isNotNull);
    });

    test('captures HTTP 500 from real HttpLink with errorDomain=graphql',
        () async {
      final completer = Completer<Map<String, dynamic>>();
      when(mHost.networkLog(any)).thenAnswer((invocation) {
        final data = invocation.positionalArguments[0] as Map<String, dynamic>;
        if (!completer.isCompleted) completer.complete(data);
        return Future<void>.value();
      });

      final mockClient = http_testing.MockClient((_) async {
        return http.Response(
          'internal error',
          500,
          headers: const {'content-type': 'text/plain'},
        );
      });

      final link = Link.from([
        LuciqGqlLink(endpoint: 'http://x/graphql'),
        HttpLink('http://x/graphql', httpClient: mockClient),
      ]);
      final request = Request(
        operation: Operation(
          document: queryDocument,
          operationName: 'GetUser',
        ),
      );

      try {
        await link.request(request).first;
      } catch (_) {
        // expected — HttpLink raises HttpLinkServerException on >=400.
      }

      final captured = await completer.future;
      expect(captured['responseCode'], 500);
      expect(captured['errorDomain'], 'graphql');
      expect(captured['responseBody'], 'internal error');
    });
  });

  group('LuciqGqlLink - multipart uploads', () {
    test('replaces MultipartFile in variables with a JSON-friendly placeholder',
        () async {
      final completer = Completer<Map<String, dynamic>>();
      when(mHost.networkLog(any)).thenAnswer((invocation) {
        final data = invocation.positionalArguments[0] as Map<String, dynamic>;
        if (!completer.isCompleted) completer.complete(data);
        return Future<void>.value();
      });

      final upload = http.MultipartFile.fromString(
        'avatar',
        'hello-bytes',
        filename: 'a.txt',
      );
      final uploadMutation = gql.parseString('''
        mutation Upload(\$file: Upload!) {
          uploadAvatar(file: \$file) { id }
        }
      ''');
      final link = LuciqGqlLink();
      final request = Request(
        operation: Operation(
          document: uploadMutation,
          operationName: 'Upload',
        ),
        variables: {'file': upload},
      );

      final forward = mockForwardWith([
        const Response(
          data: {
            'uploadAvatar': {'id': '7'},
          },
          response: {},
        ),
      ]);

      await link.request(request, forward).first;
      final captured = await completer.future;
      final raw = captured['requestBody'] as String;
      final parsed = jsonDecode(raw) as Map<String, dynamic>;

      expect(parsed['operationName'], 'Upload');
      final variables = parsed['variables'] as Map<String, dynamic>;
      final fileEntry = variables['file'] as Map<String, dynamic>;
      expect(fileEntry['__luciq_multipart'], true);
      expect(fileEntry['filename'], 'a.txt');
      expect(fileEntry['field'], 'avatar');
      expect(fileEntry['length'], isA<int>());
    });

    test('walks nested maps and lists to sanitize multipart entries', () async {
      final completer = Completer<Map<String, dynamic>>();
      when(mHost.networkLog(any)).thenAnswer((invocation) {
        final data = invocation.positionalArguments[0] as Map<String, dynamic>;
        if (!completer.isCompleted) completer.complete(data);
        return Future<void>.value();
      });

      final file1 = http.MultipartFile.fromString('a', '1', filename: '1.txt');
      final file2 = http.MultipartFile.fromString('b', '2', filename: '2.txt');
      final uploadMutation = gql.parseString('''
        mutation UploadMany(\$payload: PayloadInput!) {
          uploadMany(payload: \$payload) { id }
        }
      ''');
      final link = LuciqGqlLink();
      final request = Request(
        operation: Operation(
          document: uploadMutation,
          operationName: 'UploadMany',
        ),
        variables: {
          'payload': <String, dynamic>{
            'files': [file1, file2],
          },
        },
      );

      final forward = mockForwardWith([
        const Response(
          data: {'uploadMany': null},
          response: {},
        ),
      ]);

      await link.request(request, forward).first;
      final captured = await completer.future;
      final parsed =
          jsonDecode(captured['requestBody'] as String) as Map<String, dynamic>;
      final files = ((parsed['variables'] as Map<String, dynamic>)['payload']
          as Map<String, dynamic>)['files'] as List<dynamic>;
      expect(files.length, 2);
      expect((files[0] as Map<String, dynamic>)['filename'], '1.txt');
      expect((files[1] as Map<String, dynamic>)['filename'], '2.txt');
    });
  });

  group('LuciqGqlLink - encoding fallback', () {
    test('wraps non-encodable variables in a structured error envelope',
        () async {
      final completer = Completer<Map<String, dynamic>>();
      when(mHost.networkLog(any)).thenAnswer((invocation) {
        final data = invocation.positionalArguments[0] as Map<String, dynamic>;
        if (!completer.isCompleted) completer.complete(data);
        return Future<void>.value();
      });

      final link = LuciqGqlLink();
      final request = Request(
        operation: Operation(
          document: queryDocument,
          operationName: 'GetUser',
        ),
        // _NotEncodable has no toJson; jsonEncode throws on it, which forces
        // _buildRequestBody into the fallback path.
        variables: {'oops': _NotEncodable()},
      );

      final forward = mockForwardWith([
        const Response(data: {'user': null}, response: {}),
      ]);

      await link.request(request, forward).first;
      final captured = await completer.future;

      final raw = captured['requestBody'] as String;
      final parsed = jsonDecode(raw) as Map<String, dynamic>;
      expect(parsed['_luciq_encode_error'], isA<String>());
      expect(parsed['fallback'], isA<String>());
    });
  });
}

class _NotEncodable {}
