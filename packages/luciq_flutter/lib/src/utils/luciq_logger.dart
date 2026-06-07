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
  static LuciqLogger get I => instance;

  @visibleForTesting
  // ignore: use_setters_to_change_properties
  static void setInstance(LuciqLogger instance) {
    _instance = instance;
  }

  LogLevel _logLevel = LogLevel.error;

  LogLevel get logLevel => _logLevel;

  set logLevel(LogLevel level) {
    _logLevel = level;
  }

  /// Returns true when the current level is at debug or verbose. Use to gate
  /// expensive payload construction:
  ///
  ///   if (LuciqLogger.I.isDebugEnabled()) {
  ///     LuciqLogger.I.d('big payload: ' + buildPayload(), tag: DebugTags.network);
  ///   }
  bool isDebugEnabled() => _logLevel.getValue() <= LogLevel.debug.getValue();

  /// Returns true when the current level is at verbose. Use for high-frequency
  /// events (per-frame, per-pointer) that should be opt-in even when debug is
  /// on.
  bool isVerboseEnabled() =>
      _logLevel.getValue() <= LogLevel.verbose.getValue();

  /// Structured key/value log: emits `event=<event> k1=v1 k2=v2` on one line
  /// so log streams can be grep-filtered and parsed by tooling.
  ///
  /// Null field values are skipped. Field values are interpolated as-is; pass
  /// hashes/lengths via [hashForLog] for any user-provided string.
  void kv(
    String event, {
    required String tag,
    LogLevel level = LogLevel.debug,
    Map<String, Object?> fields = const {},
  }) {
    if (level.getValue() < _logLevel.getValue()) return;
    final buf = StringBuffer('event=')..write(event);
    fields.forEach((k, v) {
      if (v == null) return;
      buf
        ..write(' ')
        ..write(k)
        ..write('=')
        ..write(v);
    });
    log(buf.toString(), tag: tag, level: level);
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

  void e(String message, {String tag = ''}) =>
      log(message, tag: tag, level: LogLevel.error);

  void d(String message, {String tag = ''}) =>
      log(message, tag: tag, level: LogLevel.debug);

  void v(String message, {String tag = ''}) =>
      log(message, tag: tag, level: LogLevel.verbose);

  /// Warning log. Mirrors RN's `Logger.warn`, gated at the debug threshold
  /// (warnings only surface when debug logs are on).
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
