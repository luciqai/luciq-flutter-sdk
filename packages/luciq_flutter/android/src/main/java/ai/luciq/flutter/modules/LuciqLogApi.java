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
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.LUCIQ_LOG,
                "[LOG.logVerbose] phase=enter length=" + message.length());
        LuciqLog.v(message);
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.LUCIQ_LOG,
                "[LOG.logVerbose] phase=exit");
    }

    @Override
    public void logDebug(@NonNull String message) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.LUCIQ_LOG,
                "[LOG.logDebug] phase=enter length=" + message.length());
        LuciqLog.d(message);
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.LUCIQ_LOG,
                "[LOG.logDebug] phase=exit");
    }

    @Override
    public void logInfo(@NonNull String message) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.LUCIQ_LOG,
                "[LOG.logInfo] phase=enter length=" + message.length());
        LuciqLog.i(message);
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.LUCIQ_LOG,
                "[LOG.logInfo] phase=exit");
    }

    @Override
    public void logWarn(@NonNull String message) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.LUCIQ_LOG,
                "[LOG.logWarn] phase=enter length=" + message.length());
        LuciqLog.w(message);
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.LUCIQ_LOG,
                "[LOG.logWarn] phase=exit");
    }

    @Override
    public void logError(@NonNull String message) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.LUCIQ_LOG,
                "[LOG.logError] phase=enter length=" + message.length());
        LuciqLog.e(message);
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.LUCIQ_LOG,
                "[LOG.logError] phase=exit");
    }

    @Override
    public void clearAllLogs() {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.LUCIQ_LOG,
                "[LOG.clearAllLogs] phase=enter");
        LuciqLog.clearLogs();
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.LUCIQ_LOG,
                "[LOG.clearAllLogs] phase=exit");
    }
}
