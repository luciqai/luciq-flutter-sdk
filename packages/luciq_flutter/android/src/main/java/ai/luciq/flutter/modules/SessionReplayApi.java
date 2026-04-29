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
import java.util.concurrent.ConcurrentLinkedDeque;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;

import io.flutter.plugin.common.BinaryMessenger;

public class SessionReplayApi implements SessionReplayPigeon.SessionReplayHostApi {

    static final long SYNC_CALLBACK_TIMEOUT_SECONDS = 5L;

    private final SessionReplayPigeon.SessionReplayFlutterApi flutterApi;

    private final ConcurrentLinkedDeque<PendingSync> pendingSyncs = new ConcurrentLinkedDeque<>();

    private static final class PendingSync {
        final CountDownLatch latch = new CountDownLatch(1);
        volatile boolean shouldSync = true;
    }

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
        SessionReplay.setSyncCallback(new SessionSyncListener() {
            @Override
            public boolean onSessionReadyToSync(@NonNull SessionMetadata metadata) {
                final PendingSync sync = new PendingSync();
                pendingSyncs.addLast(sync);

                // Pigeon FlutterApi messages are delivered on the main (platform) thread.
                // The SDK invokes this sync listener on a background thread, so awaiting
                // the latch here does not block the Flutter bridge.
                ThreadManager.runOnMainThread(new Runnable() {
                    @Override
                    public void run() {
                        flutterApi.onShouldSyncSession(
                                serializeMetadata(metadata),
                                new SessionReplayPigeon.SessionReplayFlutterApi.Reply<Void>() {
                                    @Override
                                    public void reply(Void reply) {
                                    }
                                });
                    }
                });

                try {
                    if (!sync.latch.await(SYNC_CALLBACK_TIMEOUT_SECONDS, TimeUnit.SECONDS)) {
                        // Flutter isolate did not respond in time — drop the pending entry
                        // and fall back to syncing rather than wedging the SDK thread.
                        pendingSyncs.remove(sync);
                        return true;
                    }
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                    pendingSyncs.remove(sync);
                    return true;
                }
                return sync.shouldSync;
            }
        });
    }

    @Override
    public void evaluateSync(@NonNull Boolean result) {
        final PendingSync sync = pendingSyncs.pollFirst();
        if (sync != null) {
            sync.shouldSync = result;
            sync.latch.countDown();
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
