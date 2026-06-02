// ignore_for_file: avoid_classes_with_only_static_members

import 'dart:async';

import 'package:luciq_flutter/src/constants/debug_tags.dart';
import 'package:luciq_flutter/src/generated/luciq_log.api.g.dart';
import 'package:luciq_flutter/src/utils/luciq_logger.dart';
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
  static Future<void> logVerbose(String message) async {
    LuciqLogger.I.d(
      'logVerbose length=${message.length}',
      tag: DebugTags.luciqLog,
    );
    return _host.logVerbose(message);
  }

  /// Appends a log [message] to Luciq internal log
  /// These logs are then sent along the next uploaded report.
  /// All log messages are timestamped
  /// Note: logs passed to this method are NOT printed to console
  static Future<void> logDebug(String message) async {
    LuciqLogger.I.d(
      'logDebug length=${message.length}',
      tag: DebugTags.luciqLog,
    );
    return _host.logDebug(message);
  }

  /// Appends a log [message] to Luciq internal log
  /// These logs are then sent along the next uploaded report.
  /// All log messages are timestamped
  /// Note: logs passed to this method are NOT printed to console
  static Future<void> logInfo(String message) async {
    LuciqLogger.I.d(
      'logInfo length=${message.length}',
      tag: DebugTags.luciqLog,
    );
    return _host.logInfo(message);
  }

  /// Appends a log [message] to Luciq internal log
  /// These logs are then sent along the next uploaded report.
  /// All log messages are timestamped
  /// Note: logs passed to this method are NOT printed to console
  static Future<void> logWarn(String message) async {
    LuciqLogger.I.d(
      'logWarn length=${message.length}',
      tag: DebugTags.luciqLog,
    );
    return _host.logWarn(message);
  }

  /// Appends a log [message] to Luciq internal log
  /// These logs are then sent along the next uploaded report.
  /// All log messages are timestamped
  /// Note: logs passed to this method are NOT printed to console
  static Future<void> logError(String message) async {
    LuciqLogger.I.d(
      'logError length=${message.length}',
      tag: DebugTags.luciqLog,
    );
    return _host.logError(message);
  }

  /// Clears Luciq internal log
  static Future<void> clearAllLogs() async {
    LuciqLogger.I.d('clearAllLogs invoked', tag: DebugTags.luciqLog);
    return _host.clearAllLogs();
  }
}
