package ai.luciq.flutter.modules;

import androidx.annotation.NonNull;

import ai.luciq.flutter.generated.LuciqLogPigeon;
import ai.luciq.flutter.util.LuciqFlutterDebugTags;
import ai.luciq.flutter.util.LuciqFlutterLogger;
import ai.luciq.library.logging.LuciqLog;

import io.flutter.plugin.common.BinaryMessenger;

public class LuciqLogApi implements LuciqLogPigeon.LuciqLogHostApi {
    public static void init(BinaryMessenger messenger) {
        final LuciqLogApi api = new LuciqLogApi();
        LuciqLogPigeon.LuciqLogHostApi.setup(messenger, api);
    }

    @Override
    public void logVerbose(@NonNull String message) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.LUCIQ_LOG, "[logVerbose] length=" + message.length());
        LuciqLog.v(message);
    }

    @Override
    public void logDebug(@NonNull String message) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.LUCIQ_LOG, "[logDebug] length=" + message.length());
        LuciqLog.d(message);
    }

    @Override
    public void logInfo(@NonNull String message) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.LUCIQ_LOG, "[logInfo] length=" + message.length());
        LuciqLog.i(message);
    }

    @Override
    public void logWarn(@NonNull String message) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.LUCIQ_LOG, "[logWarn] length=" + message.length());
        LuciqLog.w(message);
    }

    @Override
    public void logError(@NonNull String message) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.LUCIQ_LOG, "[logError] length=" + message.length());
        LuciqLog.e(message);
    }

    @Override
    public void clearAllLogs() {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.LUCIQ_LOG, "[clearAllLogs]");
        LuciqLog.clearLogs();
    }
}
