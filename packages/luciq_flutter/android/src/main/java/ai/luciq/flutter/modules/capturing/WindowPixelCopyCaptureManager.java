package ai.luciq.flutter.modules.capturing;

import android.app.Activity;
import android.graphics.Bitmap;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.util.DisplayMetrics;
import android.view.PixelCopy;
import android.view.View;

import androidx.annotation.RequiresApi;

import ai.luciq.flutter.model.ScreenshotResult;
import ai.luciq.library.util.memory.MemoryUtils;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.android.FlutterFragment;
import io.flutter.embedding.android.FlutterView;

public class WindowPixelCopyCaptureManager implements CaptureManager {
    @RequiresApi(api = Build.VERSION_CODES.O)
    @Override
    public void capture(Activity activity, ScreenshotResultCallback screenshotResultCallback) {
        if (activity == null || activity.getWindow() == null) {
            screenshotResultCallback.onError();
            return;
        }

        View rootView = activity.getWindow().getDecorView().getRootView();
        Bitmap bitmap = createBitmapFromWindow(rootView);

        if (bitmap == null) {
            screenshotResultCallback.onError();
            return;
        }

        try {
            PixelCopy.request(activity.getWindow(), null, bitmap, copyResult -> {
                if (copyResult == PixelCopy.SUCCESS) {
                    if (isInvalidWindowCapture(bitmap)) {
                        screenshotResultCallback.onError();
                        return;
                    }
                    DisplayMetrics displayMetrics = activity.getResources().getDisplayMetrics();
                    float[] flutterViewOffset = getFlutterViewOffset(activity, rootView, displayMetrics.density);
                    screenshotResultCallback.onScreenshotResult(new ScreenshotResult(displayMetrics.density, bitmap, flutterViewOffset[0], flutterViewOffset[1]));
                } else {
                    screenshotResultCallback.onError();
                }
            }, new Handler(Looper.getMainLooper()));
        } catch (Exception e) {
            screenshotResultCallback.onError();
        }
    }

    private Bitmap createBitmapFromWindow(View view) {
        int width = view.getWidth();
        int height = view.getHeight();

        if (width <= 0 || height <= 0) {
            return null;
        }

        Bitmap bitmap;
        try {
            if (((long) width * height * 4) < MemoryUtils.getFreeMemory(view.getContext())) {
                // ARGB_8888 stores each pixel in 4 bytes
                bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888);
            } else {
                // RGB_565 stores each pixel in 2 bytes
                bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.RGB_565);
            }
        } catch (IllegalArgumentException | OutOfMemoryError e) {
            bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.RGB_565);
        }

        return bitmap;
    }

    private float[] getFlutterViewOffset(Activity activity, View rootView, float pixelRatio) {
        FlutterView flutterView = getFlutterView(activity);
        if (flutterView == null) {
            return new float[]{0, 0};
        }

        int[] rootLocation = new int[2];
        int[] flutterViewLocation = new int[2];
        rootView.getLocationInWindow(rootLocation);
        flutterView.getLocationInWindow(flutterViewLocation);

        return new float[]{
                (flutterViewLocation[0] - rootLocation[0]) / pixelRatio,
                (flutterViewLocation[1] - rootLocation[1]) / pixelRatio
        };
    }

    private FlutterView getFlutterView(Activity activity) {
        FlutterView flutterViewInActivity = activity.findViewById(FlutterActivity.FLUTTER_VIEW_ID);
        FlutterView flutterViewInFragment = activity.findViewById(FlutterFragment.FLUTTER_VIEW_ID);
        return flutterViewInActivity != null ? flutterViewInActivity : flutterViewInFragment;
    }

    private static boolean isInvalidWindowCapture(Bitmap bitmap) {
        if (bitmap == null || bitmap.getWidth() <= 0 || bitmap.getHeight() <= 0) {
            return true;
        }

        return hasInsufficientPixelData(bitmap);
    }

    private static boolean hasInsufficientPixelData(Bitmap bitmap) {
        int samples = 0;
        int emptySamples = 0;
        int sampleStepX = Math.max(1, bitmap.getWidth() / 10);
        int sampleStepY = Math.max(1, bitmap.getHeight() / 10);

        for (int y = 0; y < bitmap.getHeight(); y += sampleStepY) {
            for (int x = 0; x < bitmap.getWidth(); x += sampleStepX) {
                if (isEmptyPixel(bitmap.getPixel(x, y))) {
                    emptySamples++;
                }
                samples++;
            }
        }

        return samples > 0 && emptySamples >= samples * 0.98f;
    }

    private static boolean isEmptyPixel(int pixel) {
        int red = (pixel >> 16) & 0xff;
        int green = (pixel >> 8) & 0xff;
        int blue = pixel & 0xff;
        return red <= 8 && green <= 8 && blue <= 8;
    }
}
