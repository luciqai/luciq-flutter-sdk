// ignore_for_file: avoid_classes_with_only_static_members

import 'dart:async';

import 'package:luciq_flutter/src/constants/debug_tags.dart';
import 'package:luciq_flutter/src/generated/luciq_log.api.g.dart';
import 'package:luciq_flutter/src/utils/host_call.dart';
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
  static Future<void> logVerbose(String message) => hostCall(
        'LOG.logVerbose',
        () => _host.logVerbose(message),
        tag: DebugTags.luciqLog,
        args: {'length': message.length},
      );

  /// Appends a log [message] to Luciq internal log
  /// These logs are then sent along the next uploaded report.
  /// All log messages are timestamped
  /// Note: logs passed to this method are NOT printed to console
  static Future<void> logDebug(String message) => hostCall(
        'LOG.logDebug',
        () => _host.logDebug(message),
        tag: DebugTags.luciqLog,
        args: {'length': message.length},
      );

  /// Appends a log [message] to Luciq internal log
  /// These logs are then sent along the next uploaded report.
  /// All log messages are timestamped
  /// Note: logs passed to this method are NOT printed to console
  static Future<void> logInfo(String message) => hostCall(
        'LOG.logInfo',
        () => _host.logInfo(message),
        tag: DebugTags.luciqLog,
        args: {'length': message.length},
      );

  /// Appends a log [message] to Luciq internal log
  /// These logs are then sent along the next uploaded report.
  /// All log messages are timestamped
  /// Note: logs passed to this method are NOT printed to console
  static Future<void> logWarn(String message) => hostCall(
        'LOG.logWarn',
        () => _host.logWarn(message),
        tag: DebugTags.luciqLog,
        args: {'length': message.length},
      );

  /// Appends a log [message] to Luciq internal log
  /// These logs are then sent along the next uploaded report.
  /// All log messages are timestamped
  /// Note: logs passed to this method are NOT printed to console
  static Future<void> logError(String message) => hostCall(
        'LOG.logError',
        () => _host.logError(message),
        tag: DebugTags.luciqLog,
        args: {'length': message.length},
      );

  /// Clears Luciq internal log
  static Future<void> clearAllLogs() => hostCall(
        'LOG.clearAllLogs',
        () => _host.clearAllLogs(),
        tag: DebugTags.luciqLog,
      );
}
