package ai.luciq.flutter.util;

import android.util.Log;

/**
 * Defensive try/catch wrapper for native Pigeon API entry points so the SDK
 * never crashes the host app. Mirrors the Dart-side {@code runCatching}
 * helper at {@code lib/src/utils/run_catching.dart}.
 *
 * <p>Catches {@link Throwable} (including {@code Error} subclasses) — the
 * mandate is that an observability SDK must never be the cause of a crash,
 * which the Dart layer also enforces. Logs the failure to Logcat.
 */
public final class RunCatching {
    private static final String TAG = "Luciq";

    private RunCatching() {}

    @FunctionalInterface
    public interface ThrowingRunnable {
        void run() throws Throwable;
    }

    @FunctionalInterface
    public interface ThrowingSupplier<T> {
        T get() throws Throwable;
    }

    /** Runs {@code action}; logs and swallows anything thrown. */
    public static void runCatching(String method, ThrowingRunnable action) {
        try {
            action.run();
        } catch (Throwable t) {
            Log.e(TAG, method + " failed", t);
        }
    }

    /** Runs {@code action}; logs and returns {@code fallback} on throw. */
    public static <T> T runCatchingReturn(String method, T fallback, ThrowingSupplier<T> action) {
        try {
            return action.get();
        } catch (Throwable t) {
            Log.e(TAG, method + " failed", t);
            return fallback;
        }
    }
}
