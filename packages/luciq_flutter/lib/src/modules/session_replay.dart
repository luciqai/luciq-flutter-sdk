// ignore_for_file: avoid_classes_with_only_static_members

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:luciq_flutter/src/generated/session_replay.api.g.dart';

export 'package:luciq_flutter/src/generated/session_replay.api.g.dart'
    show ScreenshotCapturingMode, ScreenshotQualityMode;

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
    return _host.setScreenshotCapturingMode(mode);
  }

  /// Sets the capture interval for Frequency mode.
  ///
  /// Only takes effect when [screenshotCapturingMode] is set to
  /// [ScreenshotCapturingMode.frequency].
  ///
  /// - [intervalMs]: Time between captures in milliseconds
  /// - Default: 1000ms (1 screenshot per second)
  /// - Minimum: 500ms (values below 500ms will automatically use 500ms)
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
    return _host.setScreenshotQualityMode(mode);
  }
}
