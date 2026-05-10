package ai.luciq.flutter;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.contains;
import static org.mockito.Mockito.mockStatic;

import android.util.Log;

import ai.luciq.flutter.util.RunCatching;

import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import org.mockito.MockedStatic;

public class RunCatchingTest {
    private MockedStatic<Log> mLog;

    @Before
    public void setUp() {
        mLog = mockStatic(Log.class);
    }

    @After
    public void cleanUp() {
        mLog.close();
    }

    @Test
    public void runCatching_runsTheActionWhenItDoesNotThrow() {
        final boolean[] ran = {false};

        RunCatching.runCatching("Test.method", () -> ran[0] = true);

        assertTrue(ran[0]);
        mLog.verifyNoInteractions();
    }

    @Test
    public void runCatching_swallowsExceptionAndLogs() {
        RunCatching.runCatching("Test.method", () -> {
            throw new RuntimeException("boom");
        });

        mLog.verify(() -> Log.e(eq("Luciq"), contains("Test.method failed"), any(Throwable.class)));
    }

    @Test
    public void runCatching_swallowsErrorSubclasses() {
        // Errors (e.g. OutOfMemoryError) are caught too — observability SDK
        // must never crash the host.
        RunCatching.runCatching("Test.method", () -> {
            throw new StackOverflowError("boom");
        });

        mLog.verify(() -> Log.e(eq("Luciq"), contains("Test.method failed"), any(Throwable.class)));
    }

    @Test
    public void runCatching_swallowsCheckedExceptions() {
        RunCatching.runCatching("Test.method", () -> {
            throw new Exception("checked");
        });

        mLog.verify(() -> Log.e(eq("Luciq"), contains("Test.method failed"), any(Throwable.class)));
    }

    @Test
    public void runCatchingReturn_returnsActionResultOnSuccess() {
        Integer result = RunCatching.runCatchingReturn("Test.method", 0, () -> 42);

        assertEquals(Integer.valueOf(42), result);
        mLog.verifyNoInteractions();
    }

    @Test
    public void runCatchingReturn_returnsFallbackOnException() {
        Boolean result = RunCatching.runCatchingReturn("Test.method", false, () -> {
            throw new RuntimeException("boom");
        });

        assertFalse(result);
        mLog.verify(() -> Log.e(eq("Luciq"), contains("Test.method failed"), any(Throwable.class)));
    }

    @Test
    public void runCatchingReturn_returnsFallbackOnError() {
        String result = RunCatching.runCatchingReturn("Test.method", "fallback", () -> {
            throw new OutOfMemoryError("boom");
        });

        assertEquals("fallback", result);
        mLog.verify(() -> Log.e(eq("Luciq"), contains("Test.method failed"), any(Throwable.class)));
    }

    @Test
    public void runCatchingReturn_acceptsNullFallback() {
        Object result = RunCatching.runCatchingReturn("Test.method", null, () -> {
            throw new RuntimeException("boom");
        });

        assertNull(result);
    }

    private static <T> T eq(T value) {
        return org.mockito.ArgumentMatchers.eq(value);
    }
}
