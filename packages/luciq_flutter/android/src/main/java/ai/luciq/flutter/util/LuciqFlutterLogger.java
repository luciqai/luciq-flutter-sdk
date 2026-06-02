package ai.luciq.flutter.util;

import android.util.Log;

import ai.luciq.library.LogLevel;

/**
 * Plugin-side logger that gates `android.util.Log` calls on the same
 * debugLogsLevel the host app passes to Luciq.init(), so the native Flutter
 * plugin diagnostic logs do not leak in production builds when the
 * Dart-side LuciqLogger is silent.
 *
 * Mirrors the level hierarchy in lib/src/utils/luciq_logger.dart:
 *   VERBOSE > DEBUG > ERROR > NONE
 */
public final class LuciqFlutterLogger {

    private static volatile int currentLevel = LogLevel.ERROR;

    private LuciqFlutterLogger() {}

    public static void setLevel(int level) {
        currentLevel = level;
    }

    public static int getLevel() {
        return currentLevel;
    }

    public static void d(String tag, String message) {
        if (currentLevel >= LogLevel.DEBUG) {
            Log.d(tag, message);
        }
    }

    public static void w(String tag, String message) {
        if (currentLevel >= LogLevel.DEBUG) {
            Log.w(tag, message);
        }
    }

    public static void e(String tag, String message) {
        if (currentLevel >= LogLevel.ERROR) {
            Log.e(tag, message);
        }
    }

    public static void e(String tag, String message, Throwable throwable) {
        if (currentLevel >= LogLevel.ERROR) {
            Log.e(tag, message, throwable);
        }
    }

    /**
     * Returns `url` with its query string, fragment, and userinfo stripped
     * for safe logging. Mirrors `redactUrlForLog` in
     * lib/src/utils/luciq_utils.dart. null/empty input returns "".
     */
    public static String redactUrl(String url) {
        if (url == null || url.isEmpty()) return "";

        String stripped = url;
        int schemeEnd = stripped.indexOf("://");
        if (schemeEnd != -1) {
            int authorityStart = schemeEnd + 3;
            int authorityEnd = stripped.length();
            for (int i = authorityStart; i < stripped.length(); i++) {
                char c = stripped.charAt(i);
                if (c == '/' || c == '?' || c == '#') {
                    authorityEnd = i;
                    break;
                }
            }
            int atIdx = stripped.lastIndexOf('@', authorityEnd - 1);
            if (atIdx > authorityStart - 1 && atIdx < authorityEnd) {
                stripped = stripped.substring(0, authorityStart) + stripped.substring(atIdx + 1);
            }
        }

        int queryIdx = stripped.indexOf('?');
        int fragIdx = stripped.indexOf('#');
        int cutoff = -1;
        if (queryIdx != -1) cutoff = queryIdx;
        if (fragIdx != -1 && (cutoff == -1 || fragIdx < cutoff)) cutoff = fragIdx;
        if (cutoff == -1) return stripped;

        boolean cutAtQuery = queryIdx != -1 && (fragIdx == -1 || queryIdx < fragIdx);
        String base = stripped.substring(0, cutoff);
        return cutAtQuery ? base + "?<redacted>" : base;
    }
}
