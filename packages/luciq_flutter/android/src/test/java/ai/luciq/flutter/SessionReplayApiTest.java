package ai.luciq.flutter;

import ai.luciq.flutter.generated.SessionReplayPigeon;
import ai.luciq.flutter.modules.SessionReplayApi;
import ai.luciq.flutter.util.GlobalMocks;
import ai.luciq.library.OnSessionReplayLinkReady;
import ai.luciq.library.sessionreplay.CapturingMode;
import ai.luciq.library.sessionreplay.ScreenshotQuality;
import ai.luciq.library.sessionreplay.SessionReplay;
import io.flutter.plugin.common.BinaryMessenger;
import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import org.mockito.MockedStatic;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.timeout;
import static org.mockito.Mockito.verify;


public class SessionReplayApiTest {
    private final SessionReplayApi api = new SessionReplayApi();
    private MockedStatic<SessionReplay> mSessionReplay;
    private MockedStatic<SessionReplayPigeon.SessionReplayHostApi> mHostApi;

    @Before
    public void setUp() throws NoSuchMethodException {
        mSessionReplay = mockStatic(SessionReplay.class);
        mHostApi = mockStatic(SessionReplayPigeon.SessionReplayHostApi.class);
        GlobalMocks.setUp();
    }

    @After
    public void cleanUp() {
        mSessionReplay.close();
        mHostApi.close();
        GlobalMocks.close();
    }

    @Test
    public void testInit() {
        BinaryMessenger messenger = mock(BinaryMessenger.class);

        SessionReplayApi.init(messenger);

        mHostApi.verify(() -> SessionReplayPigeon.SessionReplayHostApi.setup(eq(messenger), any(SessionReplayApi.class)));
    }

    @Test
    public void testSetEnabled() {
        boolean isEnabled = true;

        api.setEnabled(isEnabled);

        mSessionReplay.verify(() -> SessionReplay.setEnabled(true));
    }

    @Test
    public void testSetNetworkLogsEnabled() {
        boolean isEnabled = true;

        api.setNetworkLogsEnabled(isEnabled);

        mSessionReplay.verify(() -> SessionReplay.setNetworkLogsEnabled(true));
    }

    @Test
    public void testSetLuciqLogsEnabled() {
        boolean isEnabled = true;

        api.setLuciqLogsEnabled(isEnabled);

        mSessionReplay.verify(() -> SessionReplay.setLuciqLogsEnabled(true));
    }

    @Test
    public void testSetUserStepsEnabled() {
        boolean isEnabled = true;

        api.setUserStepsEnabled(isEnabled);

        mSessionReplay.verify(() -> SessionReplay.setUserStepsEnabled(true));
    }
    @Test
    public void testGetSessionReplayLink() {
        SessionReplayPigeon.Result<String> result = mock(SessionReplayPigeon.Result.class);
        String link="luciq link";

        mSessionReplay.when(() -> SessionReplay.getSessionReplayLink(any())).thenAnswer(
                invocation -> {
                    OnSessionReplayLinkReady callback = (OnSessionReplayLinkReady) invocation.getArguments()[0];
                    callback.onSessionReplayLinkReady(link);
                    return callback;
                });
        api.getSessionReplayLink(result);


        mSessionReplay.verify(() -> SessionReplay.getSessionReplayLink(any()));
        mSessionReplay.verifyNoMoreInteractions();


        verify(result, timeout(1000)).success(link);


    }

    @Test
    public void testSetScreenshotCapturingModeNavigation() {
        api.setScreenshotCapturingMode(SessionReplayPigeon.ScreenshotCapturingMode.NAVIGATION);

        mSessionReplay.verify(() -> SessionReplay.setCapturingMode(CapturingMode.NAVIGATION));
    }

    @Test
    public void testSetScreenshotCapturingModeInteraction() {
        api.setScreenshotCapturingMode(SessionReplayPigeon.ScreenshotCapturingMode.INTERACTION);

        mSessionReplay.verify(() -> SessionReplay.setCapturingMode(CapturingMode.INTERACTIONS));
    }

    @Test
    public void testSetScreenshotCapturingModeFrequency() {
        api.setScreenshotCapturingMode(SessionReplayPigeon.ScreenshotCapturingMode.FREQUENCY);

        mSessionReplay.verify(() -> SessionReplay.setCapturingMode(CapturingMode.FREQUENCY));
    }

    @Test
    public void testSetScreenshotCaptureInterval() {
        api.setScreenshotCaptureInterval(1000L);

        mSessionReplay.verify(() -> SessionReplay.setScreenshotCaptureInterval(1000));
    }

    @Test(expected = SessionReplayPigeon.FlutterError.class)
    public void testSetScreenshotCaptureIntervalBelowMinimum() {
        api.setScreenshotCaptureInterval(499L);
    }

    @Test
    public void testSetScreenshotQualityModeNormal() {
        api.setScreenshotQualityMode(SessionReplayPigeon.ScreenshotQualityMode.NORMAL);

        mSessionReplay.verify(() -> SessionReplay.setScreenshotQuality(ScreenshotQuality.NORMAL));
    }

    @Test
    public void testSetScreenshotQualityModeHigh() {
        api.setScreenshotQualityMode(SessionReplayPigeon.ScreenshotQualityMode.HIGH);

        mSessionReplay.verify(() -> SessionReplay.setScreenshotQuality(ScreenshotQuality.HIGH));
    }

    @Test
    public void testSetScreenshotQualityModeGreyScale() {
        api.setScreenshotQualityMode(SessionReplayPigeon.ScreenshotQualityMode.GREY_SCALE);

        mSessionReplay.verify(() -> SessionReplay.setScreenshotQuality(ScreenshotQuality.GREYSCALE));
    }

}

