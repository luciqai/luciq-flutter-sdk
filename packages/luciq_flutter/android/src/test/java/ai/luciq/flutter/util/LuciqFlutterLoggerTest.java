package ai.luciq.flutter.util;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;

import android.util.Log;

import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import org.mockito.MockedStatic;

import ai.luciq.library.LogLevel;

public class LuciqFlutterLoggerTest {

    private static final String TAG = "LCQ-Flutter-NET";
    private MockedStatic<Log> mockLog;

    @Before
    public void setUp() {
        mockLog = mockStatic(Log.class);
        LuciqFlutterLogger.setLevel(LogLevel.ERROR);
    }

    @After
    public void tearDown() {
        LuciqFlutterLogger.setLevel(LogLevel.ERROR);
        mockLog.close();
    }

    @Test
    public void defaultLevel_isError_suppressesDebugAndWarn_allowsError() {
        LuciqFlutterLogger.d(TAG, "debug-msg");
        LuciqFlutterLogger.w(TAG, "warn-msg");
        LuciqFlutterLogger.e(TAG, "error-msg");
        mockLog.verify(() -> Log.d(TAG, "debug-msg"), never());
        mockLog.verify(() -> Log.w(TAG, "warn-msg"), never());
        mockLog.verify(() -> Log.e(TAG, "error-msg"), times(1));
    }

    @Test
    public void debugLevel_allowsDebugAndWarnAndError() {
        LuciqFlutterLogger.setLevel(LogLevel.DEBUG);
        LuciqFlutterLogger.d(TAG, "debug-msg");
        LuciqFlutterLogger.w(TAG, "warn-msg");
        LuciqFlutterLogger.e(TAG, "error-msg");
        mockLog.verify(() -> Log.d(TAG, "debug-msg"), times(1));
        mockLog.verify(() -> Log.w(TAG, "warn-msg"), times(1));
        mockLog.verify(() -> Log.e(TAG, "error-msg"), times(1));
    }

    @Test
    public void verboseLevel_allowsEverything() {
        LuciqFlutterLogger.setLevel(LogLevel.VERBOSE);
        LuciqFlutterLogger.d(TAG, "debug-msg");
        LuciqFlutterLogger.w(TAG, "warn-msg");
        LuciqFlutterLogger.e(TAG, "error-msg");
        mockLog.verify(() -> Log.d(TAG, "debug-msg"), times(1));
        mockLog.verify(() -> Log.w(TAG, "warn-msg"), times(1));
        mockLog.verify(() -> Log.e(TAG, "error-msg"), times(1));
    }

    @Test
    public void noneLevel_suppressesEverything() {
        LuciqFlutterLogger.setLevel(LogLevel.NONE);
        LuciqFlutterLogger.d(TAG, "debug-msg");
        LuciqFlutterLogger.w(TAG, "warn-msg");
        LuciqFlutterLogger.e(TAG, "error-msg");
        LuciqFlutterLogger.e(TAG, "error-throwable", new RuntimeException("boom"));
        mockLog.verify(() -> Log.d(TAG, "debug-msg"), never());
        mockLog.verify(() -> Log.w(TAG, "warn-msg"), never());
        mockLog.verify(() -> Log.e(TAG, "error-msg"), never());
        mockLog.verify(() -> Log.e(eq(TAG), eq("error-throwable"), any(Throwable.class)), never());
    }

    @Test
    public void errorWithThrowable_respectsLevel() {
        RuntimeException ex = new RuntimeException("boom");
        LuciqFlutterLogger.setLevel(LogLevel.ERROR);
        LuciqFlutterLogger.e(TAG, "with-throwable", ex);
        mockLog.verify(() -> Log.e(TAG, "with-throwable", ex), times(1));

        LuciqFlutterLogger.setLevel(LogLevel.NONE);
        LuciqFlutterLogger.e(TAG, "with-throwable-2", ex);
        mockLog.verify(() -> Log.e(TAG, "with-throwable-2", ex), never());
    }

    @Test public void redactUrl_null_returnsEmpty() {
        org.junit.Assert.assertEquals("", LuciqFlutterLogger.redactUrl(null));
    }

    @Test public void redactUrl_empty_returnsEmpty() {
        org.junit.Assert.assertEquals("", LuciqFlutterLogger.redactUrl(""));
    }

    @Test public void redactUrl_preservesUrlWithoutQueryOrFragment() {
        org.junit.Assert.assertEquals(
                "https://api.example.com/users/123",
                LuciqFlutterLogger.redactUrl("https://api.example.com/users/123"));
    }

    @Test public void redactUrl_stripsSimpleQuery() {
        org.junit.Assert.assertEquals(
                "https://api.example.com/users?<redacted>",
                LuciqFlutterLogger.redactUrl("https://api.example.com/users?email=u@x.com"));
    }

    @Test public void redactUrl_stripsMultiParamQuery() {
        org.junit.Assert.assertEquals(
                "https://api.example.com/auth?<redacted>",
                LuciqFlutterLogger.redactUrl("https://api.example.com/auth?token=abc&user=12345&hash=xyz"));
    }

    @Test public void redactUrl_neverLeaksSensitiveQueryValue() {
        String sensitive = "super-secret-token-value-9876";
        String result = LuciqFlutterLogger.redactUrl("https://api.example.com/users?token=" + sensitive);
        org.junit.Assert.assertFalse(result.contains(sensitive));
        org.junit.Assert.assertFalse(result.contains("token="));
    }

    @Test public void redactUrl_stripsFragmentSilently() {
        org.junit.Assert.assertEquals(
                "https://app.example.com/page",
                LuciqFlutterLogger.redactUrl("https://app.example.com/page#section-2"));
    }

    @Test public void redactUrl_cutsAtQueryWhenQueryComesFirst() {
        org.junit.Assert.assertEquals(
                "https://api.example.com/users?<redacted>",
                LuciqFlutterLogger.redactUrl("https://api.example.com/users?email=u@x.com#anchor"));
    }

    @Test public void redactUrl_cutsAtFragmentWhenFragmentComesFirst() {
        org.junit.Assert.assertEquals(
                "https://app.example.com/page",
                LuciqFlutterLogger.redactUrl("https://app.example.com/page#frag?fake"));
    }

    @Test public void redactUrl_neverReturnsUnredactedQueryParamValue() {
        String[] inputs = {
                "https://x.com/p?a=1",
                "https://x.com/p?a=1&b=2",
                "https://x.com/p#frag",
                "https://x.com/p?a=1#frag",
                "http://localhost:1234/foo?bar=baz",
        };
        for (String url : inputs) {
            String out = LuciqFlutterLogger.redactUrl(url);
            org.junit.Assert.assertEquals("query '=' should not leak: " + url, -1, out.indexOf('='));
            org.junit.Assert.assertEquals("fragment '#' should not leak: " + url, -1, out.indexOf('#'));
        }
    }
}
