package ai.luciq.flutter;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.Context;
import android.graphics.Bitmap;
import android.util.Log;
import android.view.View;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import ai.luciq.flutter.generated.LuciqPrivateViewPigeon;
import ai.luciq.flutter.modules.ApmApi;
import ai.luciq.flutter.modules.BugReportingApi;
import ai.luciq.flutter.modules.CrashReportingApi;
import ai.luciq.flutter.modules.FeatureRequestsApi;
import ai.luciq.flutter.modules.LuciqApi;
import ai.luciq.flutter.modules.LuciqLogApi;
import ai.luciq.flutter.modules.LuciqPrivateView;
import ai.luciq.flutter.modules.PrivateViewManager;
import ai.luciq.flutter.modules.RepliesApi;
import ai.luciq.flutter.modules.SessionReplayApi;
import ai.luciq.flutter.modules.SurveysApi;
import ai.luciq.flutter.modules.capturing.BoundryCaptureManager;
import ai.luciq.flutter.modules.capturing.PixelCopyCaptureManager;

import java.util.concurrent.Callable;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.embedding.engine.renderer.FlutterRenderer;
import io.flutter.plugin.common.BinaryMessenger;

public class LuciqFlutterPlugin implements FlutterPlugin, ActivityAware {
    private static final String TAG = LuciqFlutterPlugin.class.getName();

    @SuppressLint("StaticFieldLeak")
    private static Activity activity;


    private static PrivateViewManager privateViewManager;



    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        register(binding.getApplicationContext(), binding.getBinaryMessenger(), (FlutterRenderer) binding.getTextureRegistry());
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        activity = null;
    }

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        activity = binding.getActivity();
        if (privateViewManager != null) {
            privateViewManager.setActivity(activity);
        }
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        activity = null;
        privateViewManager.setActivity(null);

    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
        activity = binding.getActivity();
        if (privateViewManager != null) {
            privateViewManager.setActivity(activity);
        }
    }

    @Override
    public void onDetachedFromActivity() {
        activity = null;
        privateViewManager.setActivity(null);

    }

    private static void register(Context context, BinaryMessenger messenger, FlutterRenderer renderer) {
        final Callable<Bitmap> screenshotProvider = new Callable<Bitmap>() {
            @Override
            public Bitmap call() {
                return takeScreenshot(renderer);
            }
        };

        privateViewManager = new PrivateViewManager(new LuciqPrivateViewPigeon.LuciqPrivateViewFlutterApi(messenger), new PixelCopyCaptureManager(), new BoundryCaptureManager(renderer));
        LuciqPrivateView.init(messenger, privateViewManager);

        ApmApi.init(messenger);
        BugReportingApi.init(messenger);
        CrashReportingApi.init(messenger);
        FeatureRequestsApi.init(messenger);
        LuciqApi.init(messenger, context, screenshotProvider);
        LuciqLogApi.init(messenger);
        RepliesApi.init(messenger);
        SessionReplayApi.init(messenger);
        SurveysApi.init(messenger);

    }

    @Nullable
    private static Bitmap takeScreenshot(FlutterRenderer renderer) {
        try {
            final View view = activity.getWindow().getDecorView().getRootView();

            view.setDrawingCacheEnabled(true);
            final Bitmap bitmap = renderer.getBitmap();
            view.setDrawingCacheEnabled(false);

            return bitmap;
        } catch (Exception e) {
            Log.e(TAG, "Failed to take screenshot using " + renderer.toString() + ". Cause: " + e);
            return null;
        }
    }
}
