package ai.luciq.flutter;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.mockStatic;

import ai.luciq.library.logging.LuciqLog;
import ai.luciq.flutter.generated.LuciqLogPigeon;
import ai.luciq.flutter.modules.LuciqLogApi;
import ai.luciq.flutter.util.GlobalMocks;

import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import org.mockito.MockedStatic;

import io.flutter.plugin.common.BinaryMessenger;


public class LuciqLogApiTest {
    private final LuciqLogApi api = new LuciqLogApi();
    private MockedStatic<LuciqLog> mLuciqLog;
    private MockedStatic<LuciqLogPigeon.LuciqLogHostApi> mHostApi;

    @Before
    public void setUp() throws NoSuchMethodException {
        mLuciqLog = mockStatic(LuciqLog.class);
        mHostApi = mockStatic(LuciqLogPigeon.LuciqLogHostApi.class);
        GlobalMocks.setUp();
    }

    @After
    public void cleanUp() {
        mLuciqLog.close();
        mHostApi.close();
        GlobalMocks.close();
    }

    @Test
    public void testInit() {
        BinaryMessenger messenger = mock(BinaryMessenger.class);

        LuciqLogApi.init(messenger);

        mHostApi.verify(() -> LuciqLogPigeon.LuciqLogHostApi.setup(eq(messenger), any(LuciqLogApi.class)));
    }

    @Test
    public void testLogVerbose() {
        String message = "created an account";

        api.logVerbose(message);

        mLuciqLog.verify(() -> LuciqLog.v(message));
    }
    @Test
    public void testLogDebug() {
        String message = "created an account";

        api.logDebug(message);

        mLuciqLog.verify(() -> LuciqLog.d(message));
    }
    @Test
    public void testLogInfo() {
        String message = "created an account";

        api.logInfo(message);

        mLuciqLog.verify(() -> LuciqLog.i(message));
    }
    @Test
    public void testLogWarn() {
        String message = "created an account";

        api.logWarn(message);

        mLuciqLog.verify(() -> LuciqLog.w(message));
    }
    @Test
    public void testLogError() {
        String message = "something went wrong";

        api.logError(message);

        mLuciqLog.verify(() -> LuciqLog.e(message));
    }
    @Test
    public void testClearAllLogs() {
        api.clearAllLogs();

        mLuciqLog.verify(LuciqLog::clearLogs);
    }
}
