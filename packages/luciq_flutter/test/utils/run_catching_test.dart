import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luciq_flutter/src/utils/luciq_logger.dart';
import 'package:luciq_flutter/src/utils/run_catching.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'run_catching_test.mocks.dart';

@GenerateMocks([LuciqLogger])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockLuciqLogger mLogger;

  setUp(() {
    mLogger = MockLuciqLogger();
    LuciqLogger.setInstance(mLogger);
  });

  group('runCatching (sync void)', () {
    test('runs the action when it does not throw', () {
      var ran = false;
      runCatching('Test.method', () => ran = true);
      expect(ran, isTrue);
      verifyNever(mLogger.e(any, tag: anyNamed('tag')));
    });

    test('swallows Exception and logs the method + error', () {
      runCatching('Test.method', () {
        throw Exception('boom');
      });
      verify(
        mLogger.e(
          argThat(allOf(contains('Test.method'), contains('boom'))),
          tag: 'Luciq',
        ),
      ).called(1);
    });

    test('swallows Error subclasses (e.g. ArgumentError) too', () {
      runCatching('Test.method', () {
        throw ArgumentError('bad input');
      });
      verify(
        mLogger.e(
          argThat(contains('bad input')),
          tag: 'Luciq',
        ),
      ).called(1);
    });
  });

  group('runCatchingAsync', () {
    test('awaits the action and completes normally on success', () async {
      var ran = false;
      await runCatchingAsync('Test.method', () async => ran = true);
      expect(ran, isTrue);
      verifyNever(mLogger.e(any, tag: anyNamed('tag')));
    });

    test('swallows PlatformException from the action', () async {
      await expectLater(
        runCatchingAsync('Test.method', () async {
          throw PlatformException(code: 'X');
        }),
        completes,
      );
      verify(
        mLogger.e(
          argThat(contains('Test.method')),
          tag: 'Luciq',
        ),
      ).called(1);
    });

    test('swallows synchronous throws from the action', () async {
      await expectLater(
        runCatchingAsync('Test.method', () {
          throw StateError('sync throw');
        }),
        completes,
      );
      verify(
        mLogger.e(
          argThat(contains('sync throw')),
          tag: 'Luciq',
        ),
      ).called(1);
    });
  });

  group('runCatchingReturn', () {
    test('returns the action result on success', () async {
      final result = await runCatchingReturn<int>(
        'Test.method',
        () async => 42,
        fallback: 0,
      );
      expect(result, 42);
      verifyNever(mLogger.e(any, tag: anyNamed('tag')));
    });

    test('returns fallback on Exception and logs the error', () async {
      final result = await runCatchingReturn<bool>(
        'Test.method',
        () async {
          throw PlatformException(code: 'X');
        },
        fallback: false,
      );
      expect(result, isFalse);
      verify(
        mLogger.e(
          argThat(contains('Test.method')),
          tag: 'Luciq',
        ),
      ).called(1);
    });

    test('returns fallback on Error and logs the error', () async {
      final result = await runCatchingReturn<List<String>>(
        'Test.method',
        () async {
          throw StateError('boom');
        },
        fallback: const <String>[],
      );
      expect(result, isEmpty);
      verify(
        mLogger.e(
          argThat(contains('boom')),
          tag: 'Luciq',
        ),
      ).called(1);
    });

    test('accepts a synchronous action', () async {
      final result = await runCatchingReturn<int>(
        'Test.method',
        () => 7,
        fallback: 0,
      );
      expect(result, 7);
    });
  });
}
