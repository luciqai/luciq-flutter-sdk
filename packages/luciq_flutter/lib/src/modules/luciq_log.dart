// ignore_for_file: avoid_classes_with_only_static_members

import 'dart:async';

import 'package:luciq_flutter/src/generated/luciq_log.api.g.dart';
import 'package:luciq_flutter/src/utils/run_catching.dart';
import 'package:meta/meta.dart';

class LuciqLog {
  static var _host = LuciqLogHostApi();

  /// @nodoc
  @visibleForTesting
  // ignore: use_setters_to_change_properties
  static void $setHostApi(LuciqLogHostApi host) {
    _host = host;
  }

  /// Appends a log [message] to Luciq internal log
  /// These logs are then sent along the next uploaded report.
  /// All log messages are timestamped
  /// Note: logs passed to this method are NOT printed to console
  static Future<void> logVerbose(String message) {
    return runCatchingAsync('LuciqLog.logVerbose', () async {
      await _host.logVerbose(message);
    });
  }

  /// Appends a log [message] to Luciq internal log
  /// These logs are then sent along the next uploaded report.
  /// All log messages are timestamped
  /// Note: logs passed to this method are NOT printed to console
  static Future<void> logDebug(String message) {
    return runCatchingAsync('LuciqLog.logDebug', () async {
      await _host.logDebug(message);
    });
  }

  /// Appends a log [message] to Luciq internal log
  /// These logs are then sent along the next uploaded report.
  /// All log messages are timestamped
  /// Note: logs passed to this method are NOT printed to console
  static Future<void> logInfo(String message) {
    return runCatchingAsync('LuciqLog.logInfo', () async {
      await _host.logInfo(message);
    });
  }

  /// Appends a log [message] to Luciq internal log
  /// These logs are then sent along the next uploaded report.
  /// All log messages are timestamped
  /// Note: logs passed to this method are NOT printed to console
  static Future<void> logWarn(String message) {
    return runCatchingAsync('LuciqLog.logWarn', () async {
      await _host.logWarn(message);
    });
  }

  /// Appends a log [message] to Luciq internal log
  /// These logs are then sent along the next uploaded report.
  /// All log messages are timestamped
  /// Note: logs passed to this method are NOT printed to console
  static Future<void> logError(String message) {
    return runCatchingAsync('LuciqLog.logError', () async {
      await _host.logError(message);
    });
  }

  /// Clears Luciq internal log
  static Future<void> clearAllLogs() {
    return runCatchingAsync('LuciqLog.clearAllLogs', () async {
      await _host.clearAllLogs();
    });
  }
}
