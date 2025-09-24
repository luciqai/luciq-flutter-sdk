package ai.luciq.flutter;

import static ai.luciq.crash.CrashReporting.getFingerprintObject;
import static ai.luciq.flutter.util.GlobalMocks.reflected;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.mockStatic;

import ai.luciq.crash.CrashReporting;
import ai.luciq.crash.models.LuciqNonFatalException;
import ai.luciq.flutter.generated.CrashReportingPigeon;
import ai.luciq.flutter.modules.CrashReportingApi;
import ai.luciq.flutter.util.ArgsRegistry;
import ai.luciq.flutter.util.GlobalMocks;
import ai.luciq.flutter.util.MockReflected;
import ai.luciq.library.Feature;

import org.json.JSONObject;
import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import org.mockito.MockedStatic;

import java.util.HashMap;
import java.util.Map;

import io.flutter.plugin.common.BinaryMessenger;


public class CrashReportingApiTest {
    private final CrashReportingApi api = new CrashReportingApi();
    private MockedStatic<CrashReporting> mCrashReporting;
    private MockedStatic<CrashReportingPigeon.CrashReportingHostApi> mHostApi;

    @Before
    public void setUp() throws NoSuchMethodException {
        mCrashReporting = mockStatic(CrashReporting.class);
        mHostApi = mockStatic(CrashReportingPigeon.CrashReportingHostApi.class);
        GlobalMocks.setUp();
    }

    @After
    public void cleanUp() {
        mCrashReporting.close();
        mHostApi.close();
        GlobalMocks.close();
    }

    @Test
    public void testInit() {
        BinaryMessenger messenger = mock(BinaryMessenger.class);

        CrashReportingApi.init(messenger);

        mHostApi.verify(() -> CrashReportingPigeon.CrashReportingHostApi.setup(eq(messenger), any(CrashReportingApi.class)));
    }

    @Test
    public void testSetEnabledGivenTrue() {
        boolean isEnabled = true;

        api.setEnabled(isEnabled);

        mCrashReporting.verify(() -> CrashReporting.setState(Feature.State.ENABLED));
    }

    @Test
    public void testSetEnabledGivenFalse() {
        boolean isEnabled = false;

        api.setEnabled(isEnabled);

        mCrashReporting.verify(() -> CrashReporting.setState(Feature.State.DISABLED));
    }

    @Test
    public void testSend() {
        String jsonCrash = "{}";
        boolean isHandled = false;

        api.send(jsonCrash, isHandled);

        reflected.verify(() -> MockReflected.crashReportException(any(JSONObject.class), eq(isHandled)));
    }

    @Test
    public void testSendNonFatalError() {
        String jsonCrash = "{}";
        boolean isHandled = true;
        String fingerPrint = "test";

        Map<String, String> expectedUserAttributes = new HashMap<>();
        String level = ArgsRegistry.nonFatalExceptionLevel.keySet().iterator().next();
        JSONObject expectedFingerprint = getFingerprintObject(fingerPrint);
        LuciqNonFatalException.Level expectedLevel = ArgsRegistry.nonFatalExceptionLevel.get(level);
        api.sendNonFatalError(jsonCrash, expectedUserAttributes, fingerPrint, level);

        reflected.verify(() -> MockReflected.crashReportException(any(JSONObject.class), eq(isHandled), eq(expectedUserAttributes), eq(expectedFingerprint), eq(expectedLevel)));
    }
}
