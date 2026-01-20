package ai.luciq.flutter.modules;

import androidx.annotation.NonNull;
import ai.luciq.flutter.generated.SessionReplayPigeon;
import ai.luciq.library.sessionreplay.CapturingMode;
import ai.luciq.library.sessionreplay.ScreenshotQuality;
import ai.luciq.library.sessionreplay.SessionReplay;
import io.flutter.plugin.common.BinaryMessenger;

public class SessionReplayApi implements SessionReplayPigeon.SessionReplayHostApi {

    public static void init(BinaryMessenger messenger) {
        final SessionReplayApi api = new SessionReplayApi();
        SessionReplayPigeon.SessionReplayHostApi.setup(messenger, api);
    }

    @Override
    public void setEnabled(@NonNull Boolean isEnabled) {
        SessionReplay.setEnabled(isEnabled);
    }

    @Override
    public void setNetworkLogsEnabled(@NonNull Boolean isEnabled) {
        SessionReplay.setNetworkLogsEnabled(isEnabled);
    }

    @Override
    public void setLuciqLogsEnabled(@NonNull Boolean isEnabled) {
        SessionReplay.setLuciqLogsEnabled(isEnabled);
    }

    @Override
    public void setUserStepsEnabled(@NonNull Boolean isEnabled) {
        SessionReplay.setUserStepsEnabled(isEnabled);
    }

    @Override
    public void getSessionReplayLink(@NonNull SessionReplayPigeon.Result<String> result) {
        SessionReplay.getSessionReplayLink(result::success);
    }

    @Override
    public void setScreenshotCapturingMode(@NonNull SessionReplayPigeon.ScreenshotCapturingMode mode) {
        final int capturingMode;
        switch (mode) {
            case NAVIGATION:
                capturingMode = CapturingMode.NAVIGATION;
                break;
            case INTERACTION:
                capturingMode = CapturingMode.INTERACTIONS;
                break;
            case FREQUENCY:
                capturingMode = CapturingMode.FREQUENCY;
                break;
            default:
                throw new SessionReplayPigeon.FlutterError(
                        "INVALID_CAPTURING_MODE",
                        "Unknown ScreenshotCapturingMode: " + mode,
                        mode
                );
        }

        SessionReplay.setCapturingMode(capturingMode);
    }

    @Override
    public void setScreenshotCaptureInterval(@NonNull Long intervalMs) {
        if (intervalMs < 500L) {
            throw new SessionReplayPigeon.FlutterError(
                    "INVALID_CAPTURE_INTERVAL",
                    "intervalMs must be >= 500 on Android",
                    intervalMs
            );
        }
        SessionReplay.setScreenshotCaptureInterval(intervalMs.intValue());
    }

    @Override
    public void setScreenshotQualityMode(@NonNull SessionReplayPigeon.ScreenshotQualityMode mode) {
        final int quality;
        switch (mode) {
            case NORMAL:
                quality = ScreenshotQuality.NORMAL;
                break;
            case HIGH:
                quality = ScreenshotQuality.HIGH;
                break;
            case GREY_SCALE:
                quality = ScreenshotQuality.GREYSCALE;
                break;
            default:
                throw new SessionReplayPigeon.FlutterError(
                        "INVALID_QUALITY_MODE",
                        "Unknown ScreenshotQualityMode: " + mode,
                        mode
                );
        }

        SessionReplay.setScreenshotQuality(quality);
    }

}
