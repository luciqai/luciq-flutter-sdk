package ai.luciq.flutter.modules;

import android.util.Log;
import androidx.annotation.NonNull;
import ai.luciq.flutter.generated.SessionReplayPigeon;
import ai.luciq.flutter.util.ArgsRegistry;
import ai.luciq.flutter.util.RunCatching;
import ai.luciq.library.sessionreplay.SessionReplay;
import io.flutter.plugin.common.BinaryMessenger;

public class SessionReplayApi implements SessionReplayPigeon.SessionReplayHostApi {

    public static void init(BinaryMessenger messenger) {
        final SessionReplayApi api = new SessionReplayApi();
        SessionReplayPigeon.SessionReplayHostApi.setup(messenger, api);
    }

    @Override
    public void setEnabled(@NonNull Boolean isEnabled) {
        RunCatching.runCatching("SessionReplayApi.setEnabled",
                () -> SessionReplay.setEnabled(isEnabled));
    }

    @Override
    public void setNetworkLogsEnabled(@NonNull Boolean isEnabled) {
        RunCatching.runCatching("SessionReplayApi.setNetworkLogsEnabled",
                () -> SessionReplay.setNetworkLogsEnabled(isEnabled));
    }

    @Override
    public void setLuciqLogsEnabled(@NonNull Boolean isEnabled) {
        RunCatching.runCatching("SessionReplayApi.setLuciqLogsEnabled",
                () -> SessionReplay.setLuciqLogsEnabled(isEnabled));
    }

    @Override
    public void setUserStepsEnabled(@NonNull Boolean isEnabled) {
        RunCatching.runCatching("SessionReplayApi.setUserStepsEnabled",
                () -> SessionReplay.setUserStepsEnabled(isEnabled));
    }

    @Override
    public void getSessionReplayLink(@NonNull SessionReplayPigeon.Result<String> result) {
        RunCatching.runCatching("SessionReplayApi.getSessionReplayLink",
                () -> SessionReplay.getSessionReplayLink(result::success));
    }

    @Override
    public void setScreenshotCapturingMode(@NonNull String mode) {
        RunCatching.runCatching("SessionReplayApi.setScreenshotCapturingMode", () -> {
            final int capturingMode = ArgsRegistry.screenshotCapturingModes.get(mode);
            SessionReplay.setCapturingMode(capturingMode);
        });
    }

    @Override
    public void setScreenshotCaptureInterval(@NonNull Long intervalMs) {
        RunCatching.runCatching("SessionReplayApi.setScreenshotCaptureInterval", () -> {
            if (intervalMs < 500L) {
                Log.e("SessionReplayApi", "intervalMs must be >= 500 on Android");
                return;
            }
            SessionReplay.setScreenshotCaptureInterval(intervalMs.intValue());
        });
    }

    @Override
    public void setScreenshotQualityMode(@NonNull String mode) {
        RunCatching.runCatching("SessionReplayApi.setScreenshotQualityMode", () -> {
            final int quality = ArgsRegistry.screenshotQualityModes.get(mode);
            SessionReplay.setScreenshotQuality(quality);
        });
    }

}
