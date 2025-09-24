package ai.luciq.flutter.modules;

import androidx.annotation.NonNull;

import ai.luciq.flutter.generated.LuciqLogPigeon;
import ai.luciq.library.logging.LuciqLog;

import io.flutter.plugin.common.BinaryMessenger;

public class LuciqLogApi implements LuciqLogPigeon.LuciqLogHostApi {
    public static void init(BinaryMessenger messenger) {
        final LuciqLogApi api = new LuciqLogApi();
        LuciqLogPigeon.LuciqLogHostApi.setup(messenger, api);
    }

    @Override
    public void logVerbose(@NonNull String message) {
        LuciqLog.v(message);
    }

    @Override
    public void logDebug(@NonNull String message) {
        LuciqLog.d(message);
    }

    @Override
    public void logInfo(@NonNull String message) {
        LuciqLog.i(message);
    }

    @Override
    public void logWarn(@NonNull String message) {
        LuciqLog.w(message);
    }

    @Override
    public void logError(@NonNull String message) {
        LuciqLog.e(message);
    }

    @Override
    public void clearAllLogs() {
        LuciqLog.clearLogs();
    }
}
