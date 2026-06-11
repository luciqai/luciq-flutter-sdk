import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:luciq_flutter/luciq_flutter.dart';
import 'package:luciq_flutter/src/utils/lcq_date_time.dart';

abstract class Logger {
  void log(
    String message, {
    required LogLevel level,
    required String tag,
  });

  void d(String message, {String tag = ''});
  void e(String message, {String tag = ''});
  void w(String message, {String tag = ''});
  void v(String message, {String tag = ''});
}

class LuciqLogger implements Logger {
  LuciqLogger._();

  static LuciqLogger _instance = LuciqLogger._();
  static LuciqLogger get instance => _instance;
  static LuciqLogger get I => instance;

  @visibleForTesting
  // ignore: use_setters_to_change_properties
  static void setInstance(LuciqLogger instance) {
    _instance = instance;
  }

  LogLevel logLevel = LogLevel.error;

  /// Returns true when the current level is at debug or verbose. Use to gate
  /// expensive payload construction:
  ///
  ///   if (LuciqLogger.I.isDebugEnabled()) {
  ///     LuciqLogger.I.d('big payload: ' + buildPayload(), tag: DebugTags.network);
  ///   }
  bool isDebugEnabled() => logLevel.getValue() <= LogLevel.debug.getValue();

  @override
  void log(
    String message, {
    required LogLevel level,
    String tag = '',
  }) {
    if (level.getValue() >= logLevel.getValue()) {
      developer.log(
        message,
        name: tag,
        time: LCQDateTime.I.now(),
        level: level.getValue(),
      );
    }
  }

  @override
  void e(String message, {String tag = ''}) =>
      log(message, tag: tag, level: LogLevel.error);

  @override
  void d(String message, {String tag = ''}) =>
      log(message, tag: tag, level: LogLevel.debug);

  @override
  void v(String message, {String tag = ''}) =>
      log(message, tag: tag, level: LogLevel.verbose);

  /// Warning log. Mirrors RN's `Logger.warn`, gated at the debug threshold
  /// (warnings only surface when debug logs are on).
  @override
  void w(String message, {String tag = ''}) =>
      log(message, tag: tag, level: LogLevel.debug);
}

extension LogLevelExtension on LogLevel {
  /// Severity level used by `developer.log`. Larger = more severe.
  /// Based on the `package:logging` `Level` class.
  int getValue() {
    switch (this) {
      case LogLevel.none:
        return 2000;
      case LogLevel.error:
        return 1000;
      case LogLevel.debug:
        return 500;
      case LogLevel.verbose:
        return 0;
    }
  }
}
