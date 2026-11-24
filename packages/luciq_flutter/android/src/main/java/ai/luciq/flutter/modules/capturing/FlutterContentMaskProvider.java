package ai.luciq.flutter.modules.capturing;

import android.app.Activity;
import android.graphics.Rect;
import android.os.Handler;
import android.os.Looper;
import android.view.View;
import android.view.ViewGroup;
import android.view.Window;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.VisibleForTesting;

import java.util.ArrayList;
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
import io.flutter.embedding.android.FlutterView;
import io.flutter.embedding.engine.FlutterEngine;

/**
 * Reports the Dart private views and auto-masked widgets of the Flutter views embedded in a native
 * screen, such as {@code FlutterFragment}s in a native Activity, so the SDK masks them in that
 * screen's native screenshot.
 *
 * <p>The rects are asked from the engine attached to each Flutter view on screen, on the main
 * thread, and converted from Flutter logical pixels to window pixels. The fallback is the Flutter
 * views' visible areas: the SDK masks them whole when Dart does not answer in time.
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

    /** Finds the Flutter views in {@code activity}'s window, in view-tree order. */
    @VisibleForTesting
    public interface FlutterViewFinder {
        @NonNull
        List<FlutterView> find(@NonNull Activity activity);
    }

    private final PrivateViewsQuery query;
    private final MainThreadPoster mainThread;
    private final FlutterViewFinder finder;

    public FlutterContentMaskProvider() {
        this(FlutterContentMaskProvider::queryAttachedEngine,
                new Handler(Looper.getMainLooper())::post,
                FlutterContentMaskProvider::findFlutterViews);
    }

    @VisibleForTesting
    public FlutterContentMaskProvider(@NonNull PrivateViewsQuery query, @NonNull MainThreadPoster mainThread,
                                      @NonNull FlutterViewFinder finder) {
        this.query = query;
        this.mainThread = mainThread;
        this.finder = finder;
    }

    /**
     * Masks every Flutter view the screen shows. A screen can show several at once (two
     * {@code FlutterFragment}s stacked, each on its own engine), and each engine knows only its own
     * private views, so each shown view's engine is asked and the answers are combined. If any engine
     * fails to answer, the whole request fails and the SDK masks every shown Flutter view whole.
     */
    @Nullable
    @Override
    public CrossPlatformMasks requestMasks(@NonNull Activity activity) {
        if (activity.getWindow() == null) return null;
        final List<FlutterView> shownViews = new ArrayList<>();
        final List<Rect> visibleAreas = new ArrayList<>();
        final List<int[]> origins = new ArrayList<>();
        for (FlutterView flutterView : finder.find(activity)) {
            // isShown() also checks every parent: a hidden FlutterFragment (a bottom-navigation tab
            // behind a native one) keeps its view attached, and getGlobalVisibleRect alone ignores
            // hidden parents. Its Dart routes are still current, so asking Dart would mask its
            // private views over the native tab in front.
            if (!flutterView.isShown()) continue;
            final Rect visibleArea = new Rect();
            if (!flutterView.getGlobalVisibleRect(visibleArea)) continue;
            final int[] origin = new int[2];
            flutterView.getLocationInWindow(origin);
            shownViews.add(flutterView);
            visibleAreas.add(visibleArea);
            origins.add(origin);
        }
        if (shownViews.isEmpty()) return null;

        final float density = activity.getResources().getDisplayMetrics().density;
        final PendingRects pending = new PendingRects();
        final RectsCollector collector = new RectsCollector(shownViews.size(), pending);
        final String callId = LuciqFlutterLogger.nextCallId();

        LuciqFlutterLogger.d(LuciqFlutterDebugTags.PRIVATE_VIEW,
                "[PRIV.embedded] #" + callId + " phase=fire views=" + shownViews.size());
        mainThread.post(() -> {
            for (int i = 0; i < shownViews.size(); i++) {
                final int[] origin = origins.get(i);
                try {
                    query.query(shownViews.get(i), callId,
                            result -> collector.add(toWindowRects(result, origin, density)));
                } catch (RuntimeException e) {
                    LuciqFlutterLogger.e(LuciqFlutterDebugTags.PRIVATE_VIEW,
                            "[PRIV.embedded] #" + callId + " phase=error", e);
                    collector.add(null);
                }
            }
        });
        return new CrossPlatformMasks(pending, visibleAreas);
    }

    /** Every {@link FlutterView} in the window's view tree, in tree order. */
    @NonNull
    private static List<FlutterView> findFlutterViews(@NonNull Activity activity) {
        final List<FlutterView> found = new ArrayList<>();
        final Window window = activity.getWindow();
        collectFlutterViews(window == null ? null : window.peekDecorView(), found);
        return found;
    }

    @VisibleForTesting
    public static void collectFlutterViews(@Nullable View view, @NonNull List<FlutterView> into) {
        if (view instanceof FlutterView) {
            into.add((FlutterView) view);
            return;
        }
        if (!(view instanceof ViewGroup)) return;
        final ViewGroup group = (ViewGroup) view;
        for (int i = 0; i < group.getChildCount(); i++) collectFlutterViews(group.getChildAt(i), into);
    }

    /**
     * Completes {@code pending} once every shown view's engine answered: with all their rects, or
     * failed as soon as one answer is missing or malformed.
     */
    private static final class RectsCollector {
        private final PendingRects pending;
        private final List<Rect> rects = new ArrayList<>();
        private int remaining;

        RectsCollector(int expected, @NonNull PendingRects pending) {
            this.remaining = expected;
            this.pending = pending;
        }

        synchronized void add(@Nullable List<Rect> answer) {
            if (remaining == 0) return;
            if (answer == null) {
                remaining = 0;
                pending.complete(null);
                return;
            }
            rects.addAll(answer);
            if (--remaining == 0) pending.complete(new ArrayList<>(rects));
        }
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
