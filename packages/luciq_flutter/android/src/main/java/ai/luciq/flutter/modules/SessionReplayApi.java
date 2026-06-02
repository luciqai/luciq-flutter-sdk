package ai.luciq.flutter.modules;

import androidx.annotation.NonNull;
import ai.luciq.flutter.generated.SessionReplayPigeon;
import ai.luciq.flutter.util.ArgsRegistry;
import ai.luciq.flutter.util.LuciqFlutterDebugTags;
import ai.luciq.flutter.util.LuciqFlutterLogger;
import ai.luciq.library.sessionreplay.SessionReplay;
import io.flutter.plugin.common.BinaryMessenger;

public class SessionReplayApi implements SessionReplayPigeon.SessionReplayHostApi {

    public static void init(BinaryMessenger messenger) {
        final SessionReplayApi api = new SessionReplayApi();
        SessionReplayPigeon.SessionReplayHostApi.setup(messenger, api);
    }

    @Override
    public void setEnabled(@NonNull Boolean isEnabled) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.SESSION_REPLAY, "[setEnabled] isEnabled=" + isEnabled);
        SessionReplay.setEnabled(isEnabled);
    }

    @Override
    public void setNetworkLogsEnabled(@NonNull Boolean isEnabled) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.SESSION_REPLAY,
                "[setNetworkLogsEnabled] isEnabled=" + isEnabled);
        SessionReplay.setNetworkLogsEnabled(isEnabled);
    }

    @Override
    public void setLuciqLogsEnabled(@NonNull Boolean isEnabled) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.SESSION_REPLAY,
                "[setLuciqLogsEnabled] isEnabled=" + isEnabled);
        SessionReplay.setLuciqLogsEnabled(isEnabled);
    }

    @Override
    public void setUserStepsEnabled(@NonNull Boolean isEnabled) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.SESSION_REPLAY,
                "[setUserStepsEnabled] isEnabled=" + isEnabled);
        SessionReplay.setUserStepsEnabled(isEnabled);
    }

    @Override
    public void getSessionReplayLink(@NonNull SessionReplayPigeon.Result<String> result) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.SESSION_REPLAY, "[getSessionReplayLink]");
        SessionReplay.getSessionReplayLink(result::success);
    }

    @Override
    public void setScreenshotCapturingMode(@NonNull String mode) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.SESSION_REPLAY,
                "[setScreenshotCapturingMode] mode=" + mode);
        final int capturingMode = ArgsRegistry.screenshotCapturingModes.get(mode);
        SessionReplay.setCapturingMode(capturingMode);
    }

    @Override
    public void setScreenshotCaptureInterval(@NonNull Long intervalMs) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.SESSION_REPLAY,
                "[setScreenshotCaptureInterval] intervalMs=" + intervalMs);
        if (intervalMs < 500L) {
            LuciqFlutterLogger.e(LuciqFlutterDebugTags.SESSION_REPLAY,
                    "intervalMs must be >= 500 on Android");
            return;
        }
        SessionReplay.setScreenshotCaptureInterval(intervalMs.intValue());
    }

    @Override
    public void setScreenshotQualityMode(@NonNull String mode) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.SESSION_REPLAY,
                "[setScreenshotQualityMode] mode=" + mode);
        final int quality = ArgsRegistry.screenshotQualityModes.get(mode);
        SessionReplay.setScreenshotQuality(quality);
    }

}
