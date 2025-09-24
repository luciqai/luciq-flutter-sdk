package ai.luciq.flutter.modules;

import android.os.Handler;
import android.os.Looper;

import ai.luciq.flutter.generated.LuciqPrivateViewPigeon;
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
        LuciqApi.setScreenshotCaptor(new ScreenshotCaptor() {
            @Override
            public void capture(CapturingCallback listener) {

                (new Handler(Looper.getMainLooper())).postDelayed(new Runnable() {
                    @Override
                    public void run() {
                        time = System.currentTimeMillis();
                        privateViewManager.mask(listener);

                    }
                }, 300);


            }
        }, InternalCore.INSTANCE);
    }
}
