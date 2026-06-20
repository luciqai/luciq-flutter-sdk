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
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.SESSION_REPLAY,
                "[SR.setEnabled] phase=enter isEnabled=" + isEnabled);
        SessionReplay.setEnabled(isEnabled);
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.SESSION_REPLAY,
                "[SR.setEnabled] phase=exit");
    }

    @Override
    public void setNetworkLogsEnabled(@NonNull Boolean isEnabled) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.SESSION_REPLAY,
                "[SR.setNetworkLogsEnabled] phase=enter isEnabled=" + isEnabled);
        SessionReplay.setNetworkLogsEnabled(isEnabled);
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.SESSION_REPLAY,
                "[SR.setNetworkLogsEnabled] phase=exit");
    }

    @Override
    public void setLuciqLogsEnabled(@NonNull Boolean isEnabled) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.SESSION_REPLAY,
                "[SR.setLuciqLogsEnabled] phase=enter isEnabled=" + isEnabled);
        SessionReplay.setLuciqLogsEnabled(isEnabled);
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.SESSION_REPLAY,
                "[SR.setLuciqLogsEnabled] phase=exit");
    }

    @Override
    public void setUserStepsEnabled(@NonNull Boolean isEnabled) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.SESSION_REPLAY,
                "[SR.setUserStepsEnabled] phase=enter isEnabled=" + isEnabled);
        SessionReplay.setUserStepsEnabled(isEnabled);
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.SESSION_REPLAY,
                "[SR.setUserStepsEnabled] phase=exit");
    }

    @Override
    public void getSessionReplayLink(@NonNull String callId, @NonNull SessionReplayPigeon.Result<String> result) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.SESSION_REPLAY,
                "[SR.getSessionReplayLink] #" + callId + " phase=enter");
        SessionReplay.getSessionReplayLink(link -> {
            LuciqFlutterLogger.d(LuciqFlutterDebugTags.SESSION_REPLAY,
                    "[SR.getSessionReplayLink] #" + callId + " phase=exit resultLength="
                            + (link != null ? link.length() : 0)
                            + " resultPresent=" + (link != null && !link.isEmpty()));
            result.success(link);
        });
    }

    @Override
    public void setScreenshotCapturingMode(@NonNull String mode) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.SESSION_REPLAY,
                "[SR.setScreenshotCapturingMode] phase=enter mode=" + mode);
        final Integer capturingMode = ArgsRegistry.screenshotCapturingModes.get(mode);
        if (capturingMode == null) {
            LuciqFlutterLogger.e(LuciqFlutterDebugTags.SESSION_REPLAY,
                    "[SR.setScreenshotCapturingMode] phase=error errorType=UnknownEnum mode=" + mode);
            return;
        }
        SessionReplay.setCapturingMode(capturingMode);
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.SESSION_REPLAY,
                "[SR.setScreenshotCapturingMode] phase=exit");
    }

    @Override
    public void setScreenshotCaptureInterval(@NonNull Long intervalMs) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.SESSION_REPLAY,
                "[SR.setScreenshotCaptureInterval] phase=enter intervalMs=" + intervalMs);
        if (intervalMs < 500L) {
            LuciqFlutterLogger.e(LuciqFlutterDebugTags.SESSION_REPLAY,
                    "[SR.setScreenshotCaptureInterval] phase=error errorType=InvalidArgument intervalMs=" + intervalMs);
            return;
        }
        SessionReplay.setScreenshotCaptureInterval(intervalMs.intValue());
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.SESSION_REPLAY,
                "[SR.setScreenshotCaptureInterval] phase=exit");
    }

    @Override
    public void setScreenshotQualityMode(@NonNull String mode) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.SESSION_REPLAY,
                "[SR.setScreenshotQualityMode] phase=enter mode=" + mode);
        final Integer quality = ArgsRegistry.screenshotQualityModes.get(mode);
        if (quality == null) {
            LuciqFlutterLogger.e(LuciqFlutterDebugTags.SESSION_REPLAY,
                    "[SR.setScreenshotQualityMode] phase=error errorType=UnknownEnum mode=" + mode);
            return;
        }
        SessionReplay.setScreenshotQuality(quality);
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.SESSION_REPLAY,
                "[SR.setScreenshotQualityMode] phase=exit");
    }

}
