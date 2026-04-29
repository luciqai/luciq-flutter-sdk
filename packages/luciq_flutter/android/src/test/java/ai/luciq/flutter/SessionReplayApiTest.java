package ai.luciq.flutter;

import ai.luciq.flutter.generated.SessionReplayPigeon;
import ai.luciq.flutter.modules.SessionReplayApi;
import ai.luciq.flutter.util.GlobalMocks;
import ai.luciq.library.OnSessionReplayLinkReady;
import ai.luciq.library.SessionSyncListener;
import ai.luciq.library.sessionreplay.CapturingMode;
import ai.luciq.library.sessionreplay.ScreenshotQuality;
import ai.luciq.library.sessionreplay.SessionReplay;
import ai.luciq.library.sessionreplay.model.SessionMetadata;
import io.flutter.plugin.common.BinaryMessenger;
import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import org.mockito.ArgumentCaptor;
import org.mockito.MockedStatic;

import java.util.Collections;

import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.timeout;
import static org.mockito.Mockito.verify;


public class SessionReplayApiTest {
    private final BinaryMessenger mMessenger = mock(BinaryMessenger.class);
    private final SessionReplayPigeon.SessionReplayFlutterApi flutterApi =
            new SessionReplayPigeon.SessionReplayFlutterApi(mMessenger);
    private final SessionReplayApi api = new SessionReplayApi(flutterApi);
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
        api.setScreenshotCapturingMode("ScreenshotCapturingMode.navigation");

        mSessionReplay.verify(() -> SessionReplay.setCapturingMode(CapturingMode.NAVIGATION));
    }

    @Test
    public void testSetScreenshotCapturingModeInteraction() {
        api.setScreenshotCapturingMode("ScreenshotCapturingMode.interaction");

        mSessionReplay.verify(() -> SessionReplay.setCapturingMode(CapturingMode.INTERACTIONS));
    }

    @Test
    public void testSetScreenshotCapturingModeFrequency() {
        api.setScreenshotCapturingMode("ScreenshotCapturingMode.frequency");

        mSessionReplay.verify(() -> SessionReplay.setCapturingMode(CapturingMode.FREQUENCY));
    }

    @Test
    public void testSetScreenshotCaptureInterval() {
        api.setScreenshotCaptureInterval(1000L);

        mSessionReplay.verify(() -> SessionReplay.setScreenshotCaptureInterval(1000));
    }

    @Test
    public void testSetScreenshotCaptureIntervalBelowMinimum() {
        api.setScreenshotCaptureInterval(499L);

        mSessionReplay.verifyNoInteractions();
    }

    @Test
    public void testSetScreenshotQualityModeNormal() {
        api.setScreenshotQualityMode("ScreenshotQualityMode.normal");

        mSessionReplay.verify(() -> SessionReplay.setScreenshotQuality(ScreenshotQuality.NORMAL));
    }

    @Test
    public void testSetScreenshotQualityModeHigh() {
        api.setScreenshotQualityMode("ScreenshotQualityMode.high");

        mSessionReplay.verify(() -> SessionReplay.setScreenshotQuality(ScreenshotQuality.HIGH));
    }

    @Test
    public void testSetScreenshotQualityModeGreyScale() {
        api.setScreenshotQualityMode("ScreenshotQualityMode.greyScale");

        mSessionReplay.verify(() -> SessionReplay.setScreenshotQuality(ScreenshotQuality.GREYSCALE));
    }

    @Test
    public void testBindOnSyncCallbackInstallsListener() {
        api.bindOnSyncCallback();

        mSessionReplay.verify(() -> SessionReplay.setSyncCallback(any(SessionSyncListener.class)));
    }

    @Test
    public void testEvaluateSyncReturnsValueToListener() throws InterruptedException {
        final SessionMetadata metadata = new SessionMetadata.Builder(
                "iPhone15,2", "iOS 17.0", "1.2.3", 42L, true,
                "Cold", 1500L, Collections.emptyList()
        ).build();

        final ArgumentCaptor<SessionSyncListener> listenerCaptor =
                ArgumentCaptor.forClass(SessionSyncListener.class);
        api.bindOnSyncCallback();
        mSessionReplay.verify(() -> SessionReplay.setSyncCallback(listenerCaptor.capture()));
        final SessionSyncListener listener = listenerCaptor.getValue();

        // Run the listener on this test thread so Mockito's thread-local static mock
        // for ThreadManager applies. evaluateSync must come from a different thread
        // so it can countDown the latch the listener awaits.
        final Thread evaluator = new Thread(() -> {
            try { Thread.sleep(100); } catch (InterruptedException ignored) {}
            api.evaluateSync(false);
        });
        evaluator.start();

        boolean result = listener.onSessionReadyToSync(metadata);
        evaluator.join(1000);

        assertFalse("listener should return evaluateSync's value", result);
    }

    @Test
    public void testEvaluateSyncTrue() throws InterruptedException {
        final SessionMetadata metadata = new SessionMetadata.Builder(
                "pixel", "Android 13", "1.0.0", 10L, false,
                null, null, Collections.emptyList()
        ).build();

        final ArgumentCaptor<SessionSyncListener> listenerCaptor =
                ArgumentCaptor.forClass(SessionSyncListener.class);
        api.bindOnSyncCallback();
        mSessionReplay.verify(() -> SessionReplay.setSyncCallback(listenerCaptor.capture()));
        final SessionSyncListener listener = listenerCaptor.getValue();

        final Thread evaluator = new Thread(() -> {
            try { Thread.sleep(100); } catch (InterruptedException ignored) {}
            api.evaluateSync(true);
        });
        evaluator.start();

        boolean result = listener.onSessionReadyToSync(metadata);
        evaluator.join(1000);

        assertTrue(result);
    }

    @Test
    public void testListenerCanBeReinvokedAfterEvaluation() throws InterruptedException {
        // A second listener invocation after the first has been resolved must not
        // reuse the already-counted-down latch. Each invocation creates a fresh
        // PendingSync; this test guards against regressing to a single shared slot.
        final SessionMetadata metadata = new SessionMetadata.Builder(
                "pixel", "Android 13", "1.0.0", 10L, false,
                "Cold", null, Collections.emptyList()
        ).build();

        final ArgumentCaptor<SessionSyncListener> listenerCaptor =
                ArgumentCaptor.forClass(SessionSyncListener.class);
        api.bindOnSyncCallback();
        mSessionReplay.verify(() -> SessionReplay.setSyncCallback(listenerCaptor.capture()));
        final SessionSyncListener listener = listenerCaptor.getValue();

        final Thread evaluator1 = new Thread(() -> {
            try { Thread.sleep(50); } catch (InterruptedException ignored) {}
            api.evaluateSync(false);
        });
        evaluator1.start();
        final boolean firstResult = listener.onSessionReadyToSync(metadata);
        evaluator1.join(1000);
        assertFalse("first invocation should reflect first evaluateSync", firstResult);

        final Thread evaluator2 = new Thread(() -> {
            try { Thread.sleep(50); } catch (InterruptedException ignored) {}
            api.evaluateSync(true);
        });
        evaluator2.start();
        final boolean secondResult = listener.onSessionReadyToSync(metadata);
        evaluator2.join(1000);
        assertTrue("second invocation should reflect second evaluateSync", secondResult);
    }

    @Test
    public void testEvaluateSyncBeforeBindIsNoOp() {
        api.evaluateSync(false);
        api.evaluateSync(true);
    }
}
