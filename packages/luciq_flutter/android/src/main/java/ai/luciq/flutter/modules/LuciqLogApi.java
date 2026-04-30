package ai.luciq.flutter.modules;

import androidx.annotation.NonNull;

import ai.luciq.flutter.generated.LuciqLogPigeon;
import ai.luciq.flutter.util.RunCatching;
import ai.luciq.library.logging.LuciqLog;

import io.flutter.plugin.common.BinaryMessenger;

public class LuciqLogApi implements LuciqLogPigeon.LuciqLogHostApi {
    public static void init(BinaryMessenger messenger) {
        final LuciqLogApi api = new LuciqLogApi();
        LuciqLogPigeon.LuciqLogHostApi.setup(messenger, api);
    }

    @Override
    public void logVerbose(@NonNull String message) {
        RunCatching.runCatching("LuciqLogApi.logVerbose", () -> LuciqLog.v(message));
    }

    @Override
    public void logDebug(@NonNull String message) {
        RunCatching.runCatching("LuciqLogApi.logDebug", () -> LuciqLog.d(message));
    }

    @Override
    public void logInfo(@NonNull String message) {
        RunCatching.runCatching("LuciqLogApi.logInfo", () -> LuciqLog.i(message));
    }

    @Override
    public void logWarn(@NonNull String message) {
        RunCatching.runCatching("LuciqLogApi.logWarn", () -> LuciqLog.w(message));
    }

    @Override
    public void logError(@NonNull String message) {
        RunCatching.runCatching("LuciqLogApi.logError", () -> LuciqLog.e(message));
    }

    @Override
    public void clearAllLogs() {
        RunCatching.runCatching("LuciqLogApi.clearAllLogs", LuciqLog::clearLogs);
    }
}
