package ai.luciq.flutter.modules.capturing;

import android.app.Activity;
import android.graphics.Bitmap;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.util.DisplayMetrics;
import android.view.PixelCopy;
import android.view.Surface;
import android.view.SurfaceHolder;
import android.view.SurfaceView;

import androidx.annotation.RequiresApi;

import ai.luciq.flutter.model.ScreenshotResult;
import ai.luciq.library.util.memory.MemoryUtils;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.android.FlutterFragment;
import io.flutter.embedding.android.FlutterView;

public class PixelCopyCaptureManager implements CaptureManager {

    @RequiresApi(api = Build.VERSION_CODES.N)
    @Override
    public void capture(Activity activity, ScreenshotResultCallback screenshotResultCallback) {
        FlutterView flutterView = getFlutterView(activity);
        if (flutterView == null || !isValidFlutterView(flutterView)) {
            screenshotResultCallback.onError();
            return;
        }

        SurfaceView surfaceView = (SurfaceView) flutterView.getChildAt(0);
        if (!isValidSurface(surfaceView)) {
            screenshotResultCallback.onError();
            return;
        }

        Bitmap bitmap = createBitmapFromSurface(surfaceView);

        if (bitmap == null) {
            screenshotResultCallback.onError();
            return;
        }

        try {
            PixelCopy.request(surfaceView, bitmap, copyResult -> {
                try {
                    if (copyResult == PixelCopy.SUCCESS) {
                        DisplayMetrics displayMetrics = activity.getResources().getDisplayMetrics();
                        screenshotResultCallback.onScreenshotResult(new ScreenshotResult(displayMetrics.density, bitmap));
                    } else {
                        screenshotResultCallback.onError();
                    }
                } catch (Exception e) {
                    screenshotResultCallback.onError();
                }
            }, new Handler(Looper.getMainLooper()));
        } catch (Exception e) {
            screenshotResultCallback.onError();
        }
    }

    private FlutterView getFlutterView(Activity activity) {
        FlutterView flutterViewInActivity = activity.findViewById(FlutterActivity.FLUTTER_VIEW_ID);
        FlutterView flutterViewInFragment = activity.findViewById(FlutterFragment.FLUTTER_VIEW_ID);
        return flutterViewInActivity != null ? flutterViewInActivity : flutterViewInFragment;
    }

    private boolean isValidFlutterView(FlutterView flutterView) {
        boolean hasChildren = flutterView.getChildCount() > 0;
        boolean isSurfaceView = flutterView.getChildAt(0) instanceof SurfaceView;
        return hasChildren && isSurfaceView;
    }

    private boolean isValidSurface(SurfaceView surfaceView) {
        SurfaceHolder holder = surfaceView.getHolder();
        if (holder == null) {
            return false;
        }

        Surface surface = holder.getSurface();
        return surface != null && surface.isValid();
    }

    private Bitmap createBitmapFromSurface(SurfaceView surfaceView) {
        int width = surfaceView.getWidth();
        int height = surfaceView.getHeight();

        if (width <= 0 || height <= 0) {
            return null;
        }
        Bitmap bitmap;
        try {
            if (((long) width * height * 4) < MemoryUtils.getFreeMemory(surfaceView.getContext())) {
                // ARGB_8888 store each pixel in 4 bytes
                bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888);
            } else {
                // RGB_565 store each pixel in 2 bytes
                bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.RGB_565);
            }

        } catch (IllegalArgumentException | OutOfMemoryError e) {
            bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.RGB_565);
        }


        return bitmap;
    }
}
