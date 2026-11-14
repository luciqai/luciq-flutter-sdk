package ai.luciq.flutter.util.private_views;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertTrue;
import static org.junit.Assert.fail;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doAnswer;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import android.app.Activity;
import android.content.res.Resources;
import android.graphics.Rect;
import android.util.DisplayMetrics;
import android.view.Window;

import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;

import ai.luciq.flutter.modules.capturing.FlutterContentMaskProvider;
import ai.luciq.library.crossplatform.CrossPlatformMasks;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.android.FlutterFragment;
import io.flutter.embedding.android.FlutterView;

@RunWith(RobolectricTestRunner.class)
@Config(sdk = {28}, manifest = Config.NONE)
public class FlutterContentMaskProviderTest {

    private static final float DENSITY = 2.75f;
    // The FlutterFragment sits below a 420px native toolbar and fills the rest of the window.
    private static final Rect VISIBLE_AREA = new Rect(0, 420, 1080, 2340);

    private final Activity activity = mock(Activity.class);
    private final FlutterView flutterView = mock(FlutterView.class);
    private final List<Runnable> mainThread = new ArrayList<>();
    private List<Double> dartAnswer;
    private RuntimeException queryFailure;
    private boolean visible = true;

    private final FlutterContentMaskProvider.PrivateViewsQuery query = (view, callId, onResult) -> {
        assertTrue(view == flutterView);
        if (queryFailure != null) throw queryFailure;
        onResult.reply(dartAnswer);
    };

    private final FlutterContentMaskProvider provider =
            new FlutterContentMaskProvider(query, mainThread::add);

    @Before
    public void setUp() {
        when(activity.getWindow()).thenReturn(mock(Window.class));
        when(flutterView.isShown()).thenReturn(true);
        when(activity.findViewById(FlutterFragment.FLUTTER_VIEW_ID)).thenReturn(flutterView);
        Resources resources = mock(Resources.class);
        DisplayMetrics metrics = new DisplayMetrics();
        metrics.density = DENSITY;
        when(resources.getDisplayMetrics()).thenReturn(metrics);
        when(activity.getResources()).thenReturn(resources);
        doAnswer(invocation -> {
            ((Rect) invocation.getArgument(0)).set(VISIBLE_AREA);
            return visible;
        }).when(flutterView).getGlobalVisibleRect(any(Rect.class));
        doAnswer(invocation -> {
            int[] location = invocation.getArgument(0);
            location[0] = VISIBLE_AREA.left;
            location[1] = VISIBLE_AREA.top;
            return null;
        }).when(flutterView).getLocationInWindow(any(int[].class));
    }

    @Test
    public void givenNoFlutterViewWhenRequestingMasksThenNothingIsReported() {
        when(activity.findViewById(FlutterFragment.FLUTTER_VIEW_ID)).thenReturn(null);
        when(activity.findViewById(FlutterActivity.FLUTTER_VIEW_ID)).thenReturn(null);

        assertNull(provider.requestMasks(activity));
        assertTrue(mainThread.isEmpty());
    }

    @Test
    public void givenAFlutterActivityViewWhenRequestingMasksThenItIsUsed() {
        when(activity.findViewById(FlutterFragment.FLUTTER_VIEW_ID)).thenReturn(null);
        when(activity.findViewById(FlutterActivity.FLUTTER_VIEW_ID)).thenReturn(flutterView);

        assertNotNull(provider.requestMasks(activity));
    }

    @Test
    public void givenTheFlutterViewIsInAHiddenTabWhenRequestingMasksThenNothingIsReported() {
        when(flutterView.isShown()).thenReturn(false);

        assertNull(provider.requestMasks(activity));
        assertTrue(mainThread.isEmpty());
    }

    @Test
    public void givenTheFlutterViewIsNotVisibleWhenRequestingMasksThenNothingIsReported() {
        visible = false;

        assertNull(provider.requestMasks(activity));
    }

    @Test
    public void givenTheFlutterViewIsVisibleWhenRequestingMasksThenItsAreaIsTheFallback() {
        CrossPlatformMasks masks = provider.requestMasks(activity);

        assertEquals(Collections.singletonList(VISIBLE_AREA), masks.getFallback());
    }

    @Test
    public void givenDartAnswersWhenRequestingMasksThenItsRectsAreInWindowPixels() throws Exception {
        dartAnswer = Arrays.asList(10.0, 20.0, 110.0, 70.0);

        CrossPlatformMasks masks = provider.requestMasks(activity);
        assertFalse("Dart is only asked on the main thread", masks.getPending().isDone());
        runMainThread();

        // 10 x 2.75 = 27.5 -> 27, 420 + 20 x 2.75 = 475, 110 x 2.75 = 302.5 -> 303, 420 + 192.5 -> 613
        assertEquals(Collections.singletonList(new Rect(27, 475, 303, 613)),
                masks.getPending().get(1, TimeUnit.SECONDS));
    }

    @Test
    public void givenDartHasNoPrivateViewsWhenRequestingMasksThenNoRectsAreReported() throws Exception {
        dartAnswer = Collections.emptyList();

        CrossPlatformMasks masks = provider.requestMasks(activity);
        runMainThread();

        assertTrue(masks.getPending().get(1, TimeUnit.SECONDS).isEmpty());
    }

    @Test
    public void givenDartAnswersNothingWhenRequestingMasksThenTheRequestFails() throws Exception {
        dartAnswer = null;

        CrossPlatformMasks masks = provider.requestMasks(activity);
        runMainThread();

        assertFails(masks);
    }

    @Test
    public void givenAMalformedAnswerWhenRequestingMasksThenTheRequestFails() throws Exception {
        dartAnswer = Arrays.asList(1.0, 2.0, 3.0);

        CrossPlatformMasks masks = provider.requestMasks(activity);
        runMainThread();

        assertFails(masks);
    }

    @Test
    public void givenAnAnswerWithANullCoordinateWhenRequestingMasksThenTheRequestFails() throws Exception {
        dartAnswer = Arrays.asList(1.0, null, 3.0, 4.0);

        CrossPlatformMasks masks = provider.requestMasks(activity);
        runMainThread();

        assertFails(masks);
    }

    @Test
    public void givenTheQueryThrowsWhenRequestingMasksThenTheRequestFails() throws Exception {
        queryFailure = new IllegalStateException("channel closed");

        CrossPlatformMasks masks = provider.requestMasks(activity);
        runMainThread();

        assertFails(masks);
    }

    @Test
    public void givenDartHasNotAnsweredWhenWaitingThenItTimesOut() throws Exception {
        CrossPlatformMasks masks = provider.requestMasks(activity);

        try {
            masks.getPending().get(10, TimeUnit.MILLISECONDS);
            fail("Expected TimeoutException");
        } catch (TimeoutException expected) {
            assertFalse(masks.getPending().isDone());
        }
    }

    @Test
    public void givenTheRequestWasCancelledWhenDartAnswersThenTheAnswerIsIgnored() {
        dartAnswer = Arrays.asList(10.0, 20.0, 110.0, 70.0);
        CrossPlatformMasks masks = provider.requestMasks(activity);

        assertTrue(masks.getPending().cancel(false));
        runMainThread();

        assertTrue(masks.getPending().isCancelled());
        assertTrue(masks.getPending().isDone());
        assertFalse(masks.getPending().cancel(false));
    }

    private void runMainThread() {
        for (Runnable runnable : mainThread) runnable.run();
        mainThread.clear();
    }

    private static void assertFails(CrossPlatformMasks masks) throws Exception {
        try {
            masks.getPending().get(1, TimeUnit.SECONDS);
            fail("Expected ExecutionException");
        } catch (ExecutionException expected) {
            assertTrue(masks.getPending().isDone());
        }
    }
}
