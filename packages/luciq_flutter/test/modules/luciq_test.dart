import 'package:flutter_test/flutter_test.dart';
import 'package:luciq_flutter/luciq_flutter.dart';
import 'package:luciq_flutter/src/utils/luciq_logger.dart';

void main() {
  setUp(() {
    LuciqLogger.I.logLevel = LogLevel.error;
  });

  test('setDebugLogsLevel updates LuciqLogger level', () {
    Luciq.setDebugLogsLevel(LogLevel.verbose);
    expect(LuciqLogger.I.logLevel, LogLevel.verbose);

    Luciq.setDebugLogsLevel(LogLevel.none);
    expect(LuciqLogger.I.logLevel, LogLevel.none);
  });
}
