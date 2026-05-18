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
        requestWindowCopy(activity, new Handler(Looper.getMainLooper()), screenshotResultCallback);
    }

    private void requestWindowCopy(Activity activity, Handler callbackHandler, ScreenshotResultCallback screenshotResultCallback) {
        try {
            if (activity == null || activity.getWindow() == null) {
                screenshotResultCallback.onError();
                return;
            }

            View rootView = activity.getWindow().getDecorView().getRootView();
            Bitmap bitmap = createBitmapFromView(rootView);
            if (bitmap == null) {
                screenshotResultCallback.onError();
                return;
            }

            PixelCopy.request(activity.getWindow(), null, bitmap, copyResult -> {
                if (copyResult == PixelCopy.SUCCESS) {
                    if (isMostlyBlack(bitmap)) {
                        screenshotResultCallback.onError();
                        return;
                    }
                    DisplayMetrics displayMetrics = activity.getResources().getDisplayMetrics();
                    float[] flutterViewOffset = getFlutterViewOffset(activity, rootView, displayMetrics.density);
                    screenshotResultCallback.onScreenshotResult(new ScreenshotResult(displayMetrics.density, bitmap, flutterViewOffset[0], flutterViewOffset[1]));
                } else {
                    screenshotResultCallback.onError();
                }
            }, callbackHandler);
        } catch (Exception e) {
            screenshotResultCallback.onError();
        }
    }

    private Bitmap createBitmapFromView(View view) {
        int width = view.getWidth();
        int height = view.getHeight();

        if (width <= 0 || height <= 0) {
            return null;
        }

        try {
            if (((long) width * height * 4) < MemoryUtils.getFreeMemory(view.getContext())) {
                return Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888);
            }
            return Bitmap.createBitmap(width, height, Bitmap.Config.RGB_565);
        } catch (IllegalArgumentException | OutOfMemoryError e) {
            return Bitmap.createBitmap(width, height, Bitmap.Config.RGB_565);
        }
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

    private static boolean isMostlyBlack(Bitmap bitmap) {
        if (bitmap == null || bitmap.getWidth() <= 0 || bitmap.getHeight() <= 0) {
            return true;
        }

        int samples = 0;
        int blackSamples = 0;
        int stepX = Math.max(1, bitmap.getWidth() / 10);
        int stepY = Math.max(1, bitmap.getHeight() / 10);

        for (int y = 0; y < bitmap.getHeight(); y += stepY) {
            for (int x = 0; x < bitmap.getWidth(); x += stepX) {
                int pixel = bitmap.getPixel(x, y);
                int red = (pixel >> 16) & 0xff;
                int green = (pixel >> 8) & 0xff;
                int blue = pixel & 0xff;

                samples++;
                if (red <= 8 && green <= 8 && blue <= 8) {
                    blackSamples++;
                }
            }
        }

        return samples > 0 && blackSamples >= samples * 0.98f;
    }
}
