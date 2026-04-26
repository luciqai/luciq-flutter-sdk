// ignore_for_file: avoid_classes_with_only_static_members

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:luciq_flutter/src/generated/session_replay.api.g.dart';
import 'package:luciq_flutter/src/models/session_metadata.dart';

enum ScreenshotCapturingMode {
  navigation,
  interaction,
  frequency,
}

enum ScreenshotQualityMode {
  normal,
  high,
  greyScale,
}

typedef SessionSyncCallback = bool Function(SessionMetadata metadata);

class SessionReplay implements SessionReplayFlutterApi {
  static var _host = SessionReplayHostApi();
  static final _instance = SessionReplay();

  static SessionSyncCallback? _syncCallback;

  /// @nodoc
  @visibleForTesting
  // ignore: use_setters_to_change_properties
  static void $setHostApi(SessionReplayHostApi host) {
    _host = host;
  }

  /// @nodoc
  @internal
  static void $setup() {
    SessionReplayFlutterApi.setup(_instance);
  }

  /// @nodoc
  @internal
  @override
  void onShouldSyncSession(Map<String?, Object?> metadata) {
    final cleaned = <Object?, Object?>{};
    metadata.forEach((key, value) {
      if (key != null) cleaned[key] = value;
    });
    final parsed = SessionMetadata.fromMap(cleaned);
    final result = _syncCallback?.call(parsed) ?? true;
    _host.evaluateSync(result);
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

  /// Sets when screenshots are captured for Video-like Session Replay.
  ///
  /// Available modes:
  /// - [ScreenshotCapturingMode.navigation]: Capture on screen changes only (default)
  /// - [ScreenshotCapturingMode.interaction]: Capture on navigation and user interactions
  /// - [ScreenshotCapturingMode.frequency]: Capture at fixed time intervals (video-like)
  ///
  /// Example:
  ///
  /// ```dart
  /// // Enable video-like replay
  /// await SessionReplay.setScreenshotCapturingMode(ScreenshotCapturingMode.frequency);
  /// await SessionReplay.setScreenshotCaptureInterval(1000); // 1 FPS
  /// ```
  static Future<void> setScreenshotCapturingMode(
    ScreenshotCapturingMode mode,
  ) async {
    return _host.setScreenshotCapturingMode(mode.toString());
  }

  /// Sets the capture interval for Frequency mode.
  ///
  /// Only takes effect when [screenshotCapturingMode] is set to
  /// [ScreenshotCapturingMode.frequency].
  ///
  /// - [intervalMs]: Time between captures in milliseconds
  /// - Default: 1000ms (1 screenshot per second)
  /// - Minimum supported value: 500ms
  ///
  /// **Timer Reset Behavior:**
  /// The capture timer resets when:
  /// - A manual screenshot is captured via the SDK API
  /// - Screen navigation occurs
  ///
  /// Example:
  ///
  /// ```dart
  /// // Capture every 500ms (2 FPS) - maximum frequency
  /// await SessionReplay.setScreenshotCaptureInterval(500);
  ///
  /// // Capture every 2 seconds
  /// await SessionReplay.setScreenshotCaptureInterval(2000);
  /// ```
  static Future<void> setScreenshotCaptureInterval(int intervalMs) async {
    if (intervalMs < 500) {
      throw ArgumentError.value(
        intervalMs,
        'intervalMs',
        'must be greater than or equal to 500',
      );
    }

    return _host.setScreenshotCaptureInterval(intervalMs);
  }

  /// Sets the visual quality of captured screenshots.
  ///
  /// Available quality profiles:
  /// - [ScreenshotQualityMode.normal]: 25% WebP compression (default) - balanced
  /// - [ScreenshotQualityMode.high]: 50% WebP compression - best visual quality
  /// - [ScreenshotQualityMode.greyScale]: Grayscale + 25% WebP - smallest file size
  ///
  /// **Estimated Screenshots per Session** (based on 1MB limit):
  /// - High: ~62 screenshots
  /// - Normal: ~104 screenshots
  /// - GreyScale: ~130 screenshots
  ///
  /// Changes take effect on the next screenshot capture.
  ///
  /// Example:
  ///
  /// ```dart
  /// // Best visual quality
  /// await SessionReplay.setScreenshotQualityMode(ScreenshotQualityMode.high);
  ///
  /// // Storage-optimized
  /// await SessionReplay.setScreenshotQualityMode(ScreenshotQualityMode.greyScale);
  /// ```
  static Future<void> setScreenshotQualityMode(
    ScreenshotQualityMode mode,
  ) async {
    return _host.setScreenshotQualityMode(mode.toString());
  }

  /// Registers a callback that decides whether to sync a Session Replay.
  ///
  /// The callback receives a [SessionMetadata] describing the previous session
  /// and must return `true` to sync or `false` to drop it.
  ///
  /// Example:
  ///
  /// ```dart
  /// SessionReplay.setSyncCallback((metadata) {
  ///   return metadata.sessionDurationInSeconds > 60;
  /// });
  /// ```
  static Future<void> setSyncCallback(SessionSyncCallback callback) async {
    _syncCallback = callback;
    return _host.bindOnSyncCallback();
  }
}
