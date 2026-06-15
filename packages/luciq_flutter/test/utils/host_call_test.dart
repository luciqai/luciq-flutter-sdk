import 'package:flutter_test/flutter_test.dart';
import 'package:luciq_flutter/luciq_flutter.dart';
import 'package:luciq_flutter/src/utils/host_call.dart';
import 'package:luciq_flutter/src/utils/luciq_logger.dart';

class _RecordedLog {
  _RecordedLog(this.level, this.tag, this.message);
  final LogLevel level;
  final String tag;
  final String message;
}

class _RecordingLogger implements Logger {
  final List<_RecordedLog> entries = [];
  bool debugEnabled = true;

  @override
  void log(String message, {required LogLevel level, required String tag}) {
    entries.add(_RecordedLog(level, tag, message));
  }

  @override
  void d(String message, {String tag = ''}) =>
      log(message, level: LogLevel.debug, tag: tag);

  @override
  void e(String message, {String tag = ''}) =>
      log(message, level: LogLevel.error, tag: tag);

  @override
  void w(String message, {String tag = ''}) =>
      log(message, level: LogLevel.debug, tag: tag);

  @override
  void v(String message, {String tag = ''}) =>
      log(message, level: LogLevel.verbose, tag: tag);

  @override
  bool isDebugEnabled() => debugEnabled;
}

void main() {
  late _RecordingLogger logger;

  setUp(() {
    logger = _RecordingLogger();
    setHostCallLogger(logger);
  });

  tearDown(resetHostCallLogger);

  group('hostCall', () {
    test('logs enter then exit on success and returns the value', () async {
      final result = await hostCall<int>(
        'SUR.example',
        () async => 42,
        tag: 'TAG:',
        callId: 'c7f3',
        args: {'tokenPresent': true, 'tokenLength': 7},
      );

      expect(result, 42);
      expect(logger.entries.length, 2);

      expect(logger.entries[0].level, LogLevel.debug);
      expect(logger.entries[0].tag, 'TAG:');
      expect(
        logger.entries[0].message,
        '[SUR.example] #c7f3 phase=enter tokenPresent=true tokenLength=7',
      );

      expect(logger.entries[1].level, LogLevel.debug);
      expect(
        logger.entries[1].message,
        '[SUR.example] #c7f3 phase=exit result=42',
      );
    });

    test('summarizes string result as length', () async {
      await hostCall<String>(
        'SR.getLink',
        () async => 'https://luciq.ai/abc',
        tag: 'T:',
      );

      expect(
        logger.entries[1].message,
        '[SR.getLink] phase=exit resultLength=20',
      );
    });

    test('summarizes list result as count', () async {
      await hostCall<List<String>>(
        'SUR.getAvailable',
        () async => ['a', 'b', 'c'],
        tag: 'T:',
      );

      expect(
        logger.entries[1].message,
        '[SUR.getAvailable] phase=exit resultCount=3',
      );
    });

    test('summarizes null result as resultPresent=false', () async {
      await hostCall<String?>(
        'CORE.getMaybe',
        () async => null,
        tag: 'T:',
      );

      expect(
        logger.entries[1].message,
        '[CORE.getMaybe] phase=exit resultPresent=false',
      );
    });

    test('logs error and rethrows: errorType at error, message at debug',
        () async {
      Object? caught;
      try {
        await hostCall<void>(
          'CORE.boom',
          () async => throw StateError('nope'),
          tag: 'T:',
          callId: 'beef',
        );
      } catch (e) {
        caught = e;
      }

      expect(caught, isA<StateError>());
      expect(logger.entries.length, 3);
      expect(logger.entries[0].message, '[CORE.boom] #beef phase=enter');
      expect(logger.entries[1].level, LogLevel.error);
      expect(
        logger.entries[1].message,
        '[CORE.boom] #beef phase=error errorType=StateError',
      );
      expect(logger.entries[2].level, LogLevel.debug);
      expect(
        logger.entries[2].message,
        startsWith('[CORE.boom] #beef phase=error errorType=StateError '
            'errorMessage='),
      );
    });

    test('errorMessage is suppressed when debug is off', () async {
      logger.debugEnabled = false;
      try {
        await hostCall<void>(
          'CORE.boom',
          () async => throw StateError('with-pii https://x.y/a@b'),
          tag: 'T:',
        );
      } catch (_) {}

      expect(logger.entries.length, 1);
      expect(logger.entries.single.level, LogLevel.error);
      expect(
        logger.entries.single.message,
        '[CORE.boom] phase=error errorType=StateError',
      );
    });

    test('truncates long error messages on the debug line', () async {
      final long = 'x' * 300;
      try {
        await hostCall<void>(
          'CORE.boom',
          () async => throw Exception(long),
          tag: 'T:',
        );
      } catch (_) {}

      final debugLine = logger.entries
          .lastWhere((e) => e.level == LogLevel.debug)
          .message;
      // 256-char ceiling + trailing "..." marker
      expect(debugLine.contains('...'), isTrue);
      expect(debugLine.contains('x' * 257), isFalse);
    });

    test('omits callId marker when none provided', () async {
      await hostCall<int>('CORE.x', () async => 1, tag: 'T:');
      expect(logger.entries[0].message, '[CORE.x] phase=enter');
    });
  });

  group('hostCallSync', () {
    test('logs enter+exit and returns the value', () {
      final r = hostCallSync<bool>(
        'CORE.flag',
        () => true,
        tag: 'T:',
        args: const {'isEnabled': true},
      );
      expect(r, true);
      expect(
        logger.entries[0].message,
        '[CORE.flag] phase=enter isEnabled=true',
      );
      expect(logger.entries[1].message, '[CORE.flag] phase=exit result=true');
    });

    test('rethrows and logs error: errorType at error, message at debug', () {
      expect(
        () => hostCallSync<void>(
          'CORE.s',
          () => throw ArgumentError('bad'),
          tag: 'T:',
        ),
        throwsA(isA<ArgumentError>()),
      );
      final errorLine =
          logger.entries.firstWhere((e) => e.level == LogLevel.error);
      expect(errorLine.message, '[CORE.s] phase=error errorType=ArgumentError');
      final debugErrorLine = logger.entries.lastWhere(
        (e) =>
            e.level == LogLevel.debug && e.message.contains('phase=error'),
      );
      expect(debugErrorLine.message, contains('errorMessage='));
    });
  });

  group('logCallbackFire', () {
    test('emits a single phase=fire line with id and args', () {
      logCallbackFire(
        'SUR.onShowSurvey',
        tag: 'T:',
        callId: 'c7f3',
        args: const {'tokenLength': 7},
      );
      expect(logger.entries.length, 1);
      expect(logger.entries[0].level, LogLevel.debug);
      expect(
        logger.entries[0].message,
        '[SUR.onShowSurvey] #c7f3 phase=fire tokenLength=7',
      );
    });
  });
}
