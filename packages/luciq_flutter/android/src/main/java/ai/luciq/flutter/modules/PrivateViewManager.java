package ai.luciq.flutter.modules;

import android.app.Activity;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Paint;
import android.os.Build;

import androidx.annotation.NonNull;
import androidx.annotation.VisibleForTesting;

import ai.luciq.flutter.generated.LuciqPrivateViewPigeon;
import ai.luciq.flutter.model.ScreenshotResult;
import ai.luciq.flutter.modules.capturing.CaptureManager;
import ai.luciq.flutter.modules.capturing.ScreenshotResultCallback;
import ai.luciq.flutter.util.ThreadManager;
import ai.luciq.flutter.util.privateViews.ScreenshotCaptor;

import java.util.List;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.atomic.AtomicReference;

public class PrivateViewManager {
    private static final String THREAD_NAME = "LCQ-Flutter-Screenshot";
    public static final String EXCEPTION_MESSAGE = "LCQ-Flutter-Screenshot: error capturing screenshot";

    private final ExecutorService screenshotExecutor = Executors.newSingleThreadExecutor(runnable -> {
        Thread thread = new Thread(runnable);
        thread.setName(THREAD_NAME);
        return thread;
    });

    private final LuciqPrivateViewPigeon.LuciqPrivateViewFlutterApi luciqPrivateViewApi;
    private Activity activity;
    final CaptureManager pixelCopyScreenshotCaptor;
    final CaptureManager boundryScreenshotCaptor;

    public PrivateViewManager(@NonNull LuciqPrivateViewPigeon.LuciqPrivateViewFlutterApi luciqPrivateViewApi, CaptureManager pixelCopyCaptureManager, CaptureManager boundryCaptureManager) {
        this.luciqPrivateViewApi = luciqPrivateViewApi;
        this.pixelCopyScreenshotCaptor = pixelCopyCaptureManager;
        this.boundryScreenshotCaptor = boundryCaptureManager;


    }

    public void setActivity(Activity activity) {
        this.activity = activity;
    }


    public void mask(ScreenshotCaptor.CapturingCallback capturingCallback) {
        if (activity != null) {
            CountDownLatch latch = new CountDownLatch(1);
            AtomicReference<List<Double>> privateViews = new AtomicReference<>();
            final ScreenshotResultCallback boundryScreenshotResult = new ScreenshotResultCallback() {

                @Override
                public void onScreenshotResult(ScreenshotResult screenshotResult) {
                    processScreenshot(screenshotResult, privateViews, latch, capturingCallback);

                }

                @Override
                public void onError() {
                    capturingCallback.onCapturingFailure(new Exception(EXCEPTION_MESSAGE));
                }
            };

            try {
                ThreadManager.runOnMainThread(new Runnable() {
                    @Override
                    public void run() {
                        luciqPrivateViewApi.getPrivateViews(result -> {
                            privateViews.set(result);
                            latch.countDown();
                        });
                    }
                });


                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    pixelCopyScreenshotCaptor.capture(activity, new ScreenshotResultCallback() {
                        @Override
                        public void onScreenshotResult(ScreenshotResult result) {
                            processScreenshot(result, privateViews, latch, capturingCallback);

                        }

                        @Override
                        public void onError() {
                            boundryScreenshotCaptor.capture(activity, boundryScreenshotResult);

                        }
                    });
                } else {
                    boundryScreenshotCaptor.capture(activity, boundryScreenshotResult);
                }

            } catch (Exception e) {
                capturingCallback.onCapturingFailure(e);
            }
        } else {
            capturingCallback.onCapturingFailure(new Exception(EXCEPTION_MESSAGE));
        }
    }


    private void processScreenshot(ScreenshotResult result, AtomicReference<List<Double>> privateViews, CountDownLatch latch, ScreenshotCaptor.CapturingCallback capturingCallback) {
        screenshotExecutor.execute(() -> {
            try {
                latch.await();  // Wait
                Bitmap bitmap = result.getScreenshot();
                maskPrivateViews(result, privateViews.get());
                capturingCallback.onCapturingSuccess(bitmap);
                long lastTime = System.currentTimeMillis();
                System.out.println("Time:" + (lastTime - LuciqPrivateView.time));

            } catch (InterruptedException e) {
                capturingCallback.onCapturingFailure(e);
            }
        });
    }

    @VisibleForTesting
    public void maskPrivateViews(ScreenshotResult result, List<Double> privateViews) {
        try {
            if (privateViews == null || privateViews.isEmpty()) return;

            Bitmap bitmap = result.getScreenshot();
            float pixelRatio = result.getPixelRatio();
            Canvas canvas = new Canvas(bitmap);
            Paint paint = new Paint();  // Default color is black

            for (int i = 0; i < privateViews.size(); i += 4) {
                float left = privateViews.get(i).floatValue() * pixelRatio;
                float top = privateViews.get(i + 1).floatValue() * pixelRatio;
                float right = privateViews.get(i + 2).floatValue() * pixelRatio;
                float bottom = privateViews.get(i + 3).floatValue() * pixelRatio;
                canvas.drawRect(left, top, right, bottom, paint);  // Mask private view
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}