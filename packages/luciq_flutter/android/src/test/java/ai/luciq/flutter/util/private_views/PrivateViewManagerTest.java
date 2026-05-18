package ai.luciq.flutter.util.private_views;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotNull;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doAnswer;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.spy;
import static org.mockito.Mockito.timeout;
import static org.mockito.Mockito.verify;
import static org.robolectric.Shadows.shadowOf;

import android.app.Activity;
import android.graphics.Bitmap;
import android.os.Build;
import android.os.Looper;

import ai.luciq.flutter.generated.LuciqPrivateViewPigeon;
import ai.luciq.flutter.model.ScreenshotResult;
import ai.luciq.flutter.modules.PrivateViewManager;
import ai.luciq.flutter.modules.capturing.CaptureManager;
import ai.luciq.flutter.modules.capturing.ScreenshotResultCallback;
import ai.luciq.flutter.util.privateViews.ScreenshotCaptor;

import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.ArgumentCaptor;
import org.robolectric.Robolectric;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;

import java.util.Arrays;
import java.util.List;

@RunWith(RobolectricTestRunner.class)
@Config(sdk = {28}, manifest = Config.NONE)
public class PrivateViewManagerTest {

    private PrivateViewManager privateViewManager;
    private LuciqPrivateViewPigeon.LuciqPrivateViewFlutterApi LuciqPrivateViewFlutterApiMock;
    private Activity activityMock;
    private Bitmap bitmap;
    private CaptureManager windowPixelCopyScreenCaptor, pixelCopyScreenCaptor, boundryScreenCaptor;

    @Before
    public void setUp() {
        LuciqPrivateViewFlutterApiMock = mock(LuciqPrivateViewPigeon.LuciqPrivateViewFlutterApi.class);
        activityMock = spy(Robolectric.buildActivity(Activity.class).setup().create().start().resume().get());
        bitmap = Bitmap.createBitmap(200, 200, Bitmap.Config.ARGB_8888);
        bitmap.eraseColor(0xFFFFFFFF);
        windowPixelCopyScreenCaptor = mock(CaptureManager.class);
        pixelCopyScreenCaptor = mock(CaptureManager.class);
        boundryScreenCaptor = mock(CaptureManager.class);
        mockSuccessfulCapture(windowPixelCopyScreenCaptor);
        mockSuccessfulCapture(pixelCopyScreenCaptor);
        mockSuccessfulCapture(boundryScreenCaptor);
        privateViewManager = spy(new PrivateViewManager(LuciqPrivateViewFlutterApiMock, windowPixelCopyScreenCaptor, pixelCopyScreenCaptor, boundryScreenCaptor));
        privateViewManager.setActivity(activityMock);

    }


    @Test
    public void testMaskGivenEmptyActivity() {
        ai.luciq.flutter.util.privateViews.ScreenshotCaptor.CapturingCallback capturingCallbackMock = mock(ScreenshotCaptor.CapturingCallback.class);
        privateViewManager.setActivity(null);
        privateViewManager.mask(capturingCallbackMock);
        ArgumentCaptor<Throwable> argumentCaptor = ArgumentCaptor.forClass(Throwable.class);
        verify(capturingCallbackMock).onCapturingFailure(argumentCaptor.capture());
        assertEquals( PrivateViewManager.EXCEPTION_MESSAGE, argumentCaptor.getValue().getMessage());
    }

    @Test
    public void testMask() throws InterruptedException {
        ai.luciq.flutter.util.privateViews.ScreenshotCaptor.CapturingCallback capturingCallbackMock = mock(ai.luciq.flutter.util.privateViews.ScreenshotCaptor.CapturingCallback.class);
        doAnswer(invocation -> {
            LuciqPrivateViewPigeon.LuciqPrivateViewFlutterApi.Reply<List<Double>> callback = invocation.getArgument(0);  // Get the callback
            callback.reply(Arrays.asList(10.0, 20.0, 100.0, 200.0));  // Trigger the success callback
            return null;
        }).when(LuciqPrivateViewFlutterApiMock).getPrivateViews(any(LuciqPrivateViewPigeon.LuciqPrivateViewFlutterApi.Reply.class));  // Mock the method call


        // Trigger the mask operation
        privateViewManager.mask(capturingCallbackMock);
        // Mock that latch.await() has been called
        shadowOf(Looper.getMainLooper()).idle();

        // Simulate a successful bitmap capture
        verify(capturingCallbackMock, timeout(1000)).onCapturingSuccess(bitmap);
    }


    @Test
    public void testMaskPrivateViews() {
        ScreenshotResult mockResult = new ScreenshotResult(2.0f, Bitmap.createBitmap(200, 200, Bitmap.Config.ARGB_8888));

        List<Double> privateViews = Arrays.asList(10.0, 20.0, 100.0, 200.0);

        privateViewManager.maskPrivateViews(mockResult, privateViews);

        assertNotNull(mockResult.getScreenshot());
    }

    @Test
    public void testMaskPrivateViewsAppliesScreenshotOffsets() {
        Bitmap screenshot = Bitmap.createBitmap(200, 200, Bitmap.Config.ARGB_8888);
        ScreenshotResult result = new ScreenshotResult(2.0f, screenshot, 5.0f, 10.0f);

        privateViewManager.maskPrivateViews(result, Arrays.asList(10.0, 20.0, 20.0, 30.0));

        assertEquals(0xFF000000, screenshot.getPixel(30, 60));
    }

    @Test
    @Config(sdk = {Build.VERSION_CODES.M})
    public void testMaskShouldGetScreenshotWhenAPIVersionLessThan28() {
        ScreenshotCaptor.CapturingCallback capturingCallbackMock = mock(ScreenshotCaptor.CapturingCallback.class);
        privateViewManager.mask(capturingCallbackMock);
        shadowOf(Looper.getMainLooper()).idle();

        verify(boundryScreenCaptor).capture(any(), any());

    }

    @Test
    public void testMaskShouldCallWindowPixelCopyWhenAPIVersionMoreThan28() {
        ai.luciq.flutter.util.privateViews.ScreenshotCaptor.CapturingCallback capturingCallbackMock = mock(ai.luciq.flutter.util.privateViews.ScreenshotCaptor.CapturingCallback.class);
        privateViewManager.mask(capturingCallbackMock);
        shadowOf(Looper.getMainLooper()).idle();
        verify(boundryScreenCaptor, never()).capture(any(), any());
        verify(pixelCopyScreenCaptor, never()).capture(any(), any());
        verify(windowPixelCopyScreenCaptor).capture(any(), any());


    }

    @Test
    public void testMaskShouldFallbackToFlutterSurfacePixelCopyWhenWindowPixelCopyFails() {
        ai.luciq.flutter.util.privateViews.ScreenshotCaptor.CapturingCallback capturingCallbackMock = mock(ai.luciq.flutter.util.privateViews.ScreenshotCaptor.CapturingCallback.class);
        mockFailedCapture(windowPixelCopyScreenCaptor);

        privateViewManager.mask(capturingCallbackMock);
        shadowOf(Looper.getMainLooper()).idle();

        verify(windowPixelCopyScreenCaptor).capture(any(), any());
        verify(pixelCopyScreenCaptor).capture(any(), any());
        verify(boundryScreenCaptor, never()).capture(any(), any());
    }

    @Test
    public void testMaskShouldFallbackToFlutterSurfacePixelCopyWhenWindowPixelCopyIsBlack() {
        ai.luciq.flutter.util.privateViews.ScreenshotCaptor.CapturingCallback capturingCallbackMock = mock(ai.luciq.flutter.util.privateViews.ScreenshotCaptor.CapturingCallback.class);
        mockSuccessfulCapture(
                windowPixelCopyScreenCaptor,
                Bitmap.createBitmap(200, 200, Bitmap.Config.ARGB_8888)
        );

        privateViewManager.mask(capturingCallbackMock);
        shadowOf(Looper.getMainLooper()).idle();

        verify(windowPixelCopyScreenCaptor).capture(any(), any());
        verify(pixelCopyScreenCaptor).capture(any(), any());
        verify(boundryScreenCaptor, never()).capture(any(), any());
    }

    @Test
    public void testMaskShouldFallbackToBoundryCaptureWhenPixelCopyFails() {
        ai.luciq.flutter.util.privateViews.ScreenshotCaptor.CapturingCallback capturingCallbackMock = mock(ai.luciq.flutter.util.privateViews.ScreenshotCaptor.CapturingCallback.class);
        mockFailedCapture(windowPixelCopyScreenCaptor);
        mockFailedCapture(pixelCopyScreenCaptor);

        privateViewManager.mask(capturingCallbackMock);
        shadowOf(Looper.getMainLooper()).idle();

        verify(windowPixelCopyScreenCaptor).capture(any(), any());
        verify(pixelCopyScreenCaptor).capture(any(), any());
        verify(boundryScreenCaptor).capture(any(), any());
    }

    private void mockSuccessfulCapture(CaptureManager captureManager) {
        mockSuccessfulCapture(captureManager, bitmap);
    }

    private void mockSuccessfulCapture(CaptureManager captureManager, Bitmap screenshot) {
        doAnswer(invocation -> {
            ScreenshotResultCallback callback = invocation.getArgument(1);
            callback.onScreenshotResult(new ScreenshotResult(1.0f, screenshot));
            return null;
        }).when(captureManager).capture(any(), any());
    }

    private void mockFailedCapture(CaptureManager captureManager) {
        doAnswer(invocation -> {
            ScreenshotResultCallback callback = invocation.getArgument(1);
            callback.onError();
            return null;
        }).when(captureManager).capture(any(), any());
    }
}