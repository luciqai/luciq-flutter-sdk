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
}

class LuciqLogger implements Logger {
  LuciqLogger._();

  static LuciqLogger _instance = LuciqLogger._();

  static LuciqLogger get instance => _instance;

  /// Shorthand for [instance]
  static LuciqLogger get I => instance;

  @visibleForTesting
  // ignore: use_setters_to_change_properties
  static void setInstance(LuciqLogger instance) {
    _instance = instance;
  }

  LogLevel _logLevel = LogLevel.error;

  // ignore: avoid_setters_without_getters
  set logLevel(LogLevel level) {
    _logLevel = level;
  }

  @override
  void log(
    String message, {
    required LogLevel level,
    String tag = '',
  }) {
    if (level.getValue() >= _logLevel.getValue()) {
      developer.log(
        message,
        name: tag,
        time: LCQDateTime.I.now(),
        level: level.getValue(),
      );
    }
  }

  void e(
    String message, {
    String tag = '',
  }) {
    log(message, tag: tag, level: LogLevel.error);
  }

  void d(
    String message, {
    String tag = '',
  }) {
    log(message, tag: tag, level: LogLevel.debug);
  }

  void v(
    String message, {
    String tag = '',
  }) {
    log(message, tag: tag, level: LogLevel.verbose);
  }
}

extension LogLevelExtension on LogLevel {
  /// Returns the severity level to be used in the `developer.log` function.
  ///
  /// The severity level is a value between 0 and 2000.
  /// The values used here are based on the `package:logging` `Level` class.
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
