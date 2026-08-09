import 'package:flutter_test/flutter_test.dart';
import 'package:luciq_flutter/luciq_flutter.dart';

void main() {
  group('LuciqLogger', () {
    setUp(() {
      LuciqLogger.I.logLevel = LogLevel.error;
    });

    test('default level is error: isDebugEnabled() is false', () {
      expect(LuciqLogger.I.isDebugEnabled(), isFalse);
    });

    test('debug level: isDebugEnabled() is true', () {
      LuciqLogger.I.logLevel = LogLevel.debug;
      expect(LuciqLogger.I.isDebugEnabled(), isTrue);
    });

    test('verbose level: isDebugEnabled() is true', () {
      LuciqLogger.I.logLevel = LogLevel.verbose;
      expect(LuciqLogger.I.isDebugEnabled(), isTrue);
    });

    test('none level: isDebugEnabled() is false', () {
      LuciqLogger.I.logLevel = LogLevel.none;
      expect(LuciqLogger.I.isDebugEnabled(), isFalse);
    });

    test('w() is gated by debug threshold', () {
      LuciqLogger.I.logLevel = LogLevel.error;
      expect(LuciqLogger.I.isDebugEnabled(), isFalse);
      LuciqLogger.I.w('warn-msg', tag: 'T:');

      LuciqLogger.I.logLevel = LogLevel.debug;
      expect(LuciqLogger.I.isDebugEnabled(), isTrue);
      LuciqLogger.I.w('warn-msg', tag: 'T:');
    });
  });
}
