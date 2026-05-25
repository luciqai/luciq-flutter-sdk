import 'package:pigeon/pigeon.dart';

@FlutterApi()
abstract class SessionReplayFlutterApi {
  void onShouldSyncSession(Map<String, Object?> metadata);
}

@HostApi()
abstract class SessionReplayHostApi {
  void setEnabled(bool isEnabled);
  void setNetworkLogsEnabled(bool isEnabled);
  void setLuciqLogsEnabled(bool isEnabled);
  void setUserStepsEnabled(bool isEnabled);

  void bindOnSyncCallback();
  void evaluateSync(bool result);

  @async
  String getSessionReplayLink();

  /// Sets when screenshots are captured.
  /// - navigation: Capture on screen changes only (default)
  /// - interactions: Capture on navigation and user interactions
  /// - frequency: Capture at fixed time intervals (video-like)
  void setScreenshotCapturingMode(String mode);

  /// Sets the capture interval for Frequency mode.
  /// @param intervalMs Interval in milliseconds (min: 500, default: 1000)
  void setScreenshotCaptureInterval(int intervalMs);

  /// Sets the visual quality of captured screenshots.
  /// - high: 50% WebP compression
  /// - normal: 25% WebP compression (default)
  /// - greyscale: Grayscale + 25% WebP compression
  void setScreenshotQualityMode(String mode);
}
