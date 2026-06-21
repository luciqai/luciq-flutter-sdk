package ai.luciq.flutter.modules;

import android.os.Handler;
import android.os.Looper;

import ai.luciq.flutter.generated.LuciqPrivateViewPigeon;
import ai.luciq.flutter.util.LuciqFlutterDebugTags;
import ai.luciq.flutter.util.LuciqFlutterLogger;
import ai.luciq.flutter.util.privateViews.ScreenshotCaptor;
import ai.luciq.library.internal.crossplatform.InternalCore;

import io.flutter.plugin.common.BinaryMessenger;

public class LuciqPrivateView implements LuciqPrivateViewPigeon.LuciqPrivateViewHostApi {
    PrivateViewManager privateViewManager;

    public static void init(BinaryMessenger messenger, PrivateViewManager privateViewManager) {
        final LuciqPrivateView api = new LuciqPrivateView(messenger, privateViewManager);
        LuciqPrivateViewPigeon.LuciqPrivateViewHostApi.setup(messenger, api);
    }

    public LuciqPrivateView(BinaryMessenger messenger, PrivateViewManager privateViewManager) {
        this.privateViewManager = privateViewManager;
        LuciqPrivateViewPigeon.LuciqPrivateViewHostApi.setup(messenger, this);
    }

    static long time = System.currentTimeMillis();

    @Override
    public void init() {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.PRIVATE_VIEW,
                "[PRIV.init] phase=enter");
        LuciqApi.setScreenshotCaptor(new ScreenshotCaptor() {
            @Override
            public void capture(CapturingCallback listener) {
                String callId = LuciqFlutterLogger.nextCallId();
                LuciqFlutterLogger.d(LuciqFlutterDebugTags.PRIVATE_VIEW,
                        "[PRIV.capture] #" + callId + " phase=fire delayMs=300");
                (new Handler(Looper.getMainLooper())).postDelayed(new Runnable() {
                    @Override
                    public void run() {
                        time = System.currentTimeMillis();
                        LuciqFlutterLogger.d(LuciqFlutterDebugTags.PRIVATE_VIEW,
                                "[PRIV.capture.mask] #" + callId + " phase=enter");
                        privateViewManager.mask(listener);
                    }
                }, 300);
            }
        }, InternalCore.INSTANCE);
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.PRIVATE_VIEW,
                "[PRIV.init] phase=exit");
    }
}
