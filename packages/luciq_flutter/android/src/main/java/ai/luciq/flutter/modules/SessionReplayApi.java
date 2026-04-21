package ai.luciq.flutter.modules;

import android.util.Log;
import androidx.annotation.NonNull;
import ai.luciq.flutter.generated.SessionReplayPigeon;
import ai.luciq.flutter.util.ArgsRegistry;
import ai.luciq.flutter.util.ThreadManager;
import ai.luciq.library.SessionSyncListener;
import ai.luciq.library.sessionreplay.SessionReplay;
import ai.luciq.library.sessionreplay.model.SessionMetadata;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.CountDownLatch;

import io.flutter.plugin.common.BinaryMessenger;

public class SessionReplayApi implements SessionReplayPigeon.SessionReplayHostApi {

    private final SessionReplayPigeon.SessionReplayFlutterApi flutterApi;

    private boolean shouldSync = true;
    private CountDownLatch latch;

    public static void init(BinaryMessenger messenger) {
        final SessionReplayPigeon.SessionReplayFlutterApi flutterApi =
                new SessionReplayPigeon.SessionReplayFlutterApi(messenger);
        final SessionReplayApi api = new SessionReplayApi(flutterApi);
        SessionReplayPigeon.SessionReplayHostApi.setup(messenger, api);
    }

    public SessionReplayApi(SessionReplayPigeon.SessionReplayFlutterApi flutterApi) {
        this.flutterApi = flutterApi;
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
    public void setScreenshotCapturingMode(@NonNull String mode) {
        final int capturingMode = ArgsRegistry.screenshotCapturingModes.get(mode);
        SessionReplay.setCapturingMode(capturingMode);
    }

    @Override
    public void setScreenshotCaptureInterval(@NonNull Long intervalMs) {
        if (intervalMs < 500L) {
            Log.e("SessionReplayApi", "intervalMs must be >= 500 on Android");
            return;
        }
        SessionReplay.setScreenshotCaptureInterval(intervalMs.intValue());
    }

    @Override
    public void setScreenshotQualityMode(@NonNull String mode) {
        final int quality = ArgsRegistry.screenshotQualityModes.get(mode);
        SessionReplay.setScreenshotQuality(quality);
    }

    @Override
    public void bindOnSyncCallback() {
        ThreadManager.runOnMainThread(new Runnable() {
            @Override
            public void run() {
                SessionReplay.setSyncCallback(new SessionSyncListener() {
                    @Override
                    public boolean onSessionReadyToSync(@NonNull SessionMetadata metadata) {
                        latch = new CountDownLatch(1);

                        // Pigeon FlutterApi messages are delivered on the main (platform) thread.
                        // The SDK invokes this sync listener on a background thread, so
                        // awaiting the latch here does not block the Flutter bridge.
                        flutterApi.onShouldSyncSession(
                                serializeMetadata(metadata),
                                new SessionReplayPigeon.SessionReplayFlutterApi.Reply<Void>() {
                                    @Override
                                    public void reply(Void reply) {
                                    }
                                });

                        try {
                            latch.await();
                        } catch (InterruptedException e) {
                            e.printStackTrace();
                            return true;
                        }
                        return shouldSync;
                    }
                });
            }
        });
    }

    @Override
    public void evaluateSync(@NonNull Boolean result) {
        shouldSync = result;
        if (latch != null) {
            latch.countDown();
        }
    }

    private Map<String, Object> serializeMetadata(SessionMetadata metadata) {
        final Map<String, Object> map = new HashMap<>();
        map.put("appVersion", metadata.getAppVersion());
        map.put("os", metadata.getOs());
        map.put("device", metadata.getDevice());
        map.put("sessionDurationInSeconds", metadata.getSessionDurationInSeconds());
        map.put("hasLinkToAppReview", metadata.getLinkedToReview());
        map.put("launchType", metadata.getLaunchType());
        map.put("launchDuration", metadata.getLaunchDuration());
        map.put("bugsCount", 0L);
        map.put("fatalCrashCount", 0L);
        map.put("oomCrashCount", 0L);

        final List<Map<String, Object>> logs = new ArrayList<>();
        if (metadata.getNetworkLogs() != null) {
            for (SessionMetadata.NetworkLog log : metadata.getNetworkLogs()) {
                final Map<String, Object> logMap = new HashMap<>();
                logMap.put("url", log.getUrl());
                logMap.put("duration", log.getDuration());
                logMap.put("statusCode", (long) log.getStatusCode());
                logs.add(logMap);
            }
        }
        map.put("networkLogs", logs);

        return map;
    }
}
