// ignore_for_file: avoid_classes_with_only_static_members

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:luciq_flutter/src/generated/session_replay.api.g.dart';

class SessionReplay {
  static var _host = SessionReplayHostApi();

  /// @nodoc
  @visibleForTesting
  // ignore: use_setters_to_change_properties
  static void $setHostApi(SessionReplayHostApi host) {
    _host = host;
  }

  /// Enables or disables Session Replay for your Luciq integration.
  ///
  /// By default, Session Replay is enabled if it is available in your current plan.
  ///
  /// Example:
  ///
  /// ```dart
  /// await SessionReplay.setEnabled(true);
  /// ```
  static Future<void> setEnabled(bool isEnabled) async {
    return _host.setEnabled(isEnabled);
  }

  /// Enables or disables network logs for Session Replay.
  /// By default, network logs are enabled.
  ///
  /// Example:
  ///
  /// ```dart
  /// await SessionReplay.setNetworkLogsEnabled(true);
  /// ```
  static Future<void> setNetworkLogsEnabled(bool isEnabled) async {
    return _host.setNetworkLogsEnabled(isEnabled);
  }

  /// Enables or disables Luciq logs for Session Replay.
  /// By default, Luciq logs are enabled.
  ///
  /// Example:
  ///
  /// ```dart
  /// await SessionReplay.setLuciqLogsEnabled(true);
  /// ```
  static Future<void> setLuciqLogsEnabled(bool isEnabled) async {
    return _host.setLuciqLogsEnabled(isEnabled);
  }

  /// Enables or disables capturing of user steps  for Session Replay.
  /// By default, user steps are enabled.
  ///
  /// Example:
  ///
  /// ```dart
  /// await SessionReplay.setUserStepsEnabled(true);
  /// ```
  static Future<void> setUserStepsEnabled(bool isEnabled) async {
    return _host.setUserStepsEnabled(isEnabled);
  }

  /// Retrieves current session's replay link.
  ///
  /// Example:
  ///
  /// ```dart
  /// await SessionReplay.getSessionReplayLink();
  /// ```
  static Future<String> getSessionReplayLink() async {
    return _host.getSessionReplayLink();
  }
}
