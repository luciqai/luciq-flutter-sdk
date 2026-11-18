package ai.luciq.flutter.modules.capturing;

import android.app.Activity;
import android.graphics.Rect;
import android.os.Handler;
import android.os.Looper;
import android.view.View;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.VisibleForTesting;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.CancellationException;

import ai.luciq.flutter.generated.LuciqPrivateViewPigeon;
import ai.luciq.flutter.util.LuciqFlutterDebugTags;
import ai.luciq.flutter.util.LuciqFlutterLogger;
import ai.luciq.library.crossplatform.CrossPlatformMaskProvider;
import ai.luciq.library.crossplatform.CrossPlatformMasks;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.android.FlutterFragment;
import io.flutter.embedding.android.FlutterView;
import io.flutter.embedding.engine.FlutterEngine;

/**
 * Reports the Dart private views and auto-masked widgets of a Flutter view embedded in a native
 * screen, such as a {@code FlutterFragment} in a native Activity, so the SDK masks them in that
 * screen's native screenshot.
 *
 * <p>The rects are asked from the engine attached to the Flutter view on screen, on the main
 * thread, and converted from Flutter logical pixels to window pixels. The fallback is the Flutter
 * view's visible area: the SDK masks it whole when Dart does not answer in time.
 */
public class FlutterContentMaskProvider implements CrossPlatformMaskProvider {

    /** Asks Dart for the private-view rects of the engine behind {@code view}. */
    @VisibleForTesting
    public interface PrivateViewsQuery {
        /** Calls {@code onResult} with left, top, right, bottom quadruples in logical pixels, or {@code null}. */
        void query(@NonNull FlutterView view, @NonNull String callId,
                   @NonNull LuciqPrivateViewPigeon.LuciqPrivateViewFlutterApi.Reply<List<Double>> onResult);
    }

    /** Runs work on the main thread, where Flutter's platform channels must be called. */
    @VisibleForTesting
    public interface MainThreadPoster {
        void post(@NonNull Runnable runnable);
    }

    private final PrivateViewsQuery query;
    private final MainThreadPoster mainThread;

    public FlutterContentMaskProvider() {
        this(FlutterContentMaskProvider::queryAttachedEngine,
                new Handler(Looper.getMainLooper())::post);
    }

    @VisibleForTesting
    public FlutterContentMaskProvider(@NonNull PrivateViewsQuery query, @NonNull MainThreadPoster mainThread) {
        this.query = query;
        this.mainThread = mainThread;
    }

    @Nullable
    @Override
    public CrossPlatformMasks requestMasks(@NonNull Activity activity) {
        final FlutterView flutterView = findFlutterView(activity);
        if (flutterView == null) return null;

        // isShown() also checks every parent: a hidden FlutterFragment (a bottom-navigation tab
        // behind a native one) keeps its view attached, and getGlobalVisibleRect alone ignores
        // hidden parents. Its Dart routes are still current, so asking Dart would mask its private
        // views over the native tab in front.
        if (!flutterView.isShown()) return null;
        final Rect visibleArea = new Rect();
        if (!flutterView.getGlobalVisibleRect(visibleArea)) return null;

        final int[] origin = new int[2];
        flutterView.getLocationInWindow(origin);
        final float density = activity.getResources().getDisplayMetrics().density;
        final PendingRects pending = new PendingRects();
        final String callId = LuciqFlutterLogger.nextCallId();

        LuciqFlutterLogger.d(LuciqFlutterDebugTags.PRIVATE_VIEW,
                "[PRIV.embedded] #" + callId + " phase=fire");
        mainThread.post(() -> {
            try {
                query.query(flutterView, callId,
                        result -> pending.complete(toWindowRects(result, origin, density)));
            } catch (RuntimeException e) {
                LuciqFlutterLogger.e(LuciqFlutterDebugTags.PRIVATE_VIEW,
                        "[PRIV.embedded] #" + callId + " phase=error", e);
                pending.complete(null);
            }
        });
        return new CrossPlatformMasks(pending, Collections.singletonList(visibleArea));
    }

    @Nullable
    private static FlutterView findFlutterView(@NonNull Activity activity) {
        if (activity.getWindow() == null) return null;
        View view = activity.findViewById(FlutterFragment.FLUTTER_VIEW_ID);
        if (!(view instanceof FlutterView)) view = activity.findViewById(FlutterActivity.FLUTTER_VIEW_ID);
        return view instanceof FlutterView ? (FlutterView) view : null;
    }

    /**
     * Dart's rects are logical pixels relative to the Flutter view; the SDK masks in window pixels.
     * Returns {@code null} for a missing or malformed answer, so the SDK falls back to the whole area.
     */
    @Nullable
    @VisibleForTesting
    static List<Rect> toWindowRects(@Nullable List<Double> logical, int[] origin, float density) {
        if (logical == null || logical.size() % 4 != 0) return null;
        final List<Rect> rects = new ArrayList<>(logical.size() / 4);
        for (int i = 0; i < logical.size(); i += 4) {
            final Double left = logical.get(i);
            final Double top = logical.get(i + 1);
            final Double right = logical.get(i + 2);
            final Double bottom = logical.get(i + 3);
            if (left == null || top == null || right == null || bottom == null) return null;
            rects.add(new Rect(
                    origin[0] + (int) Math.floor(left * density),
                    origin[1] + (int) Math.floor(top * density),
                    origin[0] + (int) Math.ceil(right * density),
                    origin[1] + (int) Math.ceil(bottom * density)));
        }
        return rects;
    }

    private static void queryAttachedEngine(@NonNull FlutterView view, @NonNull String callId,
                                            @NonNull LuciqPrivateViewPigeon.LuciqPrivateViewFlutterApi.Reply<List<Double>> onResult) {
        final FlutterEngine engine = view.getAttachedFlutterEngine();
        if (engine == null) {
            onResult.reply(null);
            return;
        }
        new LuciqPrivateViewPigeon.LuciqPrivateViewFlutterApi(engine.getDartExecutor())
                .getPrivateViews(callId, onResult);
    }

    /** A future completed once by Dart's answer. A {@code null} answer fails it. */
    @VisibleForTesting
    static final class PendingRects implements Future<List<Rect>> {
        private final CountDownLatch done = new CountDownLatch(1);
        private final AtomicBoolean settled = new AtomicBoolean(false);
        private volatile List<Rect> rects;
        private volatile boolean cancelled;

        void complete(@Nullable List<Rect> result) {
            if (!settled.compareAndSet(false, true)) return;
            rects = result;
            done.countDown();
        }

        @Override
        public boolean cancel(boolean mayInterruptIfRunning) {
            if (!settled.compareAndSet(false, true)) return false;
            cancelled = true;
            done.countDown();
            return true;
        }

        @Override
        public boolean isCancelled() {
            return cancelled;
        }

        @Override
        public boolean isDone() {
            return done.getCount() == 0;
        }

        @Override
        public List<Rect> get() throws InterruptedException, ExecutionException {
            done.await();
            return result();
        }

        @Override
        public List<Rect> get(long timeout, @NonNull TimeUnit unit)
                throws InterruptedException, ExecutionException, TimeoutException {
            if (!done.await(timeout, unit)) throw new TimeoutException();
            return result();
        }

        private List<Rect> result() throws ExecutionException {
            if (cancelled) throw new CancellationException();
            final List<Rect> result = rects;
            if (result == null) throw new ExecutionException(new IllegalStateException("No private views from Dart"));
            return result;
        }
    }
}
