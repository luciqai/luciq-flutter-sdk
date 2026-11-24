package ai.luciq.flutter.modules.capturing;

import android.os.Handler;
import android.os.Looper;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.VisibleForTesting;

import java.util.concurrent.atomic.AtomicBoolean;

import ai.luciq.flutter.modules.LuciqApi;
import ai.luciq.library.crossplatform.CrossPlatformFrameNotifier;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.renderer.FlutterRenderer;
import io.flutter.embedding.engine.renderer.FlutterUiDisplayListener;

/**
 * Tells the SDK when a Flutter host (a {@code FlutterFragment} or {@code FlutterActivity}) draws
 * a frame, so the screenshot of its route is not taken before Flutter has drawn anything.
 *
 * <p>It listens to the renderer of the host's engine. The renderer reports the first frame drawn
 * to each new surface: a host's first frame, and its first frame after a hidden tab is shown or
 * its Activity comes back. A renderer already drawing reports at once.
 */
public class FlutterFrameNotifier implements CrossPlatformFrameNotifier {

    /** The renderer of the engine {@code host} shows, or {@code null} when it has none. */
    @VisibleForTesting
    public interface RendererLookup {
        @Nullable
        FlutterRenderer rendererOf(@NonNull Object host);
    }

    private final RendererLookup lookup;
    private final FlutterContentMaskProvider.MainThreadPoster mainThread;

    public FlutterFrameNotifier() {
        this(FlutterFrameNotifier::rendererOfHost, new Handler(Looper.getMainLooper())::post);
    }

    @VisibleForTesting
    public FlutterFrameNotifier(@NonNull RendererLookup lookup,
                                @NonNull FlutterContentMaskProvider.MainThreadPoster mainThread) {
        this.lookup = lookup;
        this.mainThread = mainThread;
    }

    @Override
    public boolean whenHostDisplayed(@NonNull Object host, @NonNull Runnable onDisplayed) {
        final FlutterRenderer renderer = lookup.rendererOf(host);
        if (renderer == null) return false;
        final AtomicBoolean fired = new AtomicBoolean(false);
        renderer.addIsDisplayingFlutterUiListener(new FlutterUiDisplayListener() {
            @Override
            public void onFlutterUiDisplayed() {
                if (!fired.compareAndSet(false, true)) return;
                // Removed on a later turn of the main loop: the renderer may be iterating its
                // listeners right now, and removing one during that loop is not safe on every
                // Flutter version.
                mainThread.post(() -> renderer.removeIsDisplayingFlutterUiListener(this));
                onDisplayed.run();
            }

            @Override
            public void onFlutterUiNoLongerDisplayed() {
                // Only the next frame drawn matters.
            }
        });
        return true;
    }

    @Nullable
    private static FlutterRenderer rendererOfHost(@NonNull Object host) {
        Object engine = LuciqApi.engineOfHost(host);
        return engine instanceof FlutterEngine ? ((FlutterEngine) engine).getRenderer() : null;
    }
}
