package ai.luciq.flutter.util.private_views;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.timeout;
import static org.mockito.Mockito.verify;
import static org.robolectric.Shadows.shadowOf;

import android.app.Activity;
import android.os.Looper;
import android.view.View;

import ai.luciq.flutter.model.ScreenshotResult;
import ai.luciq.flutter.modules.capturing.CaptureManager;
import ai.luciq.flutter.modules.capturing.ScreenshotResultCallback;
import ai.luciq.flutter.modules.capturing.WindowPixelCopyCaptureManager;
import ai.luciq.library.util.memory.MemoryUtils;

import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.MockedStatic;
import org.robolectric.Robolectric;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;

@RunWith(RobolectricTestRunner.class)
@Config(sdk = {28}, manifest = Config.NONE)
public class WindowPixelCopyCaptureManagerTest {
    private Activity activity;
    private CaptureManager captureManager;

    @Before
    public void setUp() {
        activity = Robolectric.buildActivity(Activity.class).setup().create().start().resume().get();
        captureManager = new WindowPixelCopyCaptureManager();
    }

    @Test
    public void testCaptureWithWindowPixelCopyGivenEmptyActivity() {
        ScreenshotResultCallback mockScreenshotResultCallback = mock(ScreenshotResultCallback.class);

        captureManager.capture(null, mockScreenshotResultCallback);

        verify(mockScreenshotResultCallback).onError();
    }

    @Test
    public void testCaptureWithWindowPixelCopyGivenEmptyView() {
        ScreenshotResultCallback mockScreenshotResultCallback = mock(ScreenshotResultCallback.class);
        View rootView = activity.getWindow().getDecorView().getRootView();
        rootView.layout(0, 0, 0, 0);

        captureManager.capture(activity, mockScreenshotResultCallback);

        verify(mockScreenshotResultCallback).onError();
    }

    @Test
    public void testCaptureRejectsInvalidWindowCopy() {
        try (MockedStatic<MemoryUtils> mockedStatic = mockStatic(MemoryUtils.class)) {
            mockedStatic.when(() -> MemoryUtils.getFreeMemory(any())).thenReturn(Long.MAX_VALUE);
            ScreenshotResultCallback mockScreenshotResultCallback = mock(ScreenshotResultCallback.class);
            View rootView = activity.getWindow().getDecorView().getRootView();
            rootView.layout(0, 0, 100, 100);

            captureManager.capture(activity, mockScreenshotResultCallback);
            shadowOf(Looper.getMainLooper()).idle();

            verify(mockScreenshotResultCallback, timeout(1000)).onError();
        }
    }
}
