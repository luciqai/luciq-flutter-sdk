package ai.luciq.flutter.util.private_views;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;

import org.junit.Test;
import org.mockito.ArgumentCaptor;

import java.util.ArrayList;
import java.util.List;

import ai.luciq.flutter.modules.capturing.FlutterFrameNotifier;
import io.flutter.embedding.engine.renderer.FlutterRenderer;
import io.flutter.embedding.engine.renderer.FlutterUiDisplayListener;

public class FlutterFrameNotifierTest {

    private final FlutterRenderer renderer = mock(FlutterRenderer.class);
    private final List<Runnable> mainThreadTasks = new ArrayList<>();
    private int displayed = 0;

    private FlutterFrameNotifier notifier(FlutterRenderer rendererOfHost) {
        return new FlutterFrameNotifier(host -> rendererOfHost, mainThreadTasks::add);
    }

    private FlutterUiDisplayListener registeredListener() {
        ArgumentCaptor<FlutterUiDisplayListener> listener = ArgumentCaptor.forClass(FlutterUiDisplayListener.class);
        verify(renderer).addIsDisplayingFlutterUiListener(listener.capture());
        return listener.getValue();
    }

    @Test
    public void givenAHostWithNoEngine_whenAskedToSignal_thenItCannotTell() {
        boolean willSignal = notifier(null).whenHostDisplayed(new Object(), () -> displayed++);

        assertFalse(willSignal);
        assertEquals(0, displayed);
    }

    @Test
    public void givenAHostWithAnEngine_whenItsFirstFrameIsDrawn_thenTheSdkIsSignalledOnce() {
        boolean willSignal = notifier(renderer).whenHostDisplayed(new Object(), () -> displayed++);
        FlutterUiDisplayListener listener = registeredListener();

        assertTrue(willSignal);
        assertEquals(0, displayed);

        listener.onFlutterUiDisplayed();
        listener.onFlutterUiNoLongerDisplayed();
        listener.onFlutterUiDisplayed();

        assertEquals(1, displayed);
    }

    @Test
    public void givenTheSignalFired_whenTheMainThreadRuns_thenTheListenerIsRemovedThere() {
        notifier(renderer).whenHostDisplayed(new Object(), () -> displayed++);
        FlutterUiDisplayListener listener = registeredListener();

        listener.onFlutterUiDisplayed();
        // Not removed inside the renderer's own listener loop.
        verify(renderer, never()).removeIsDisplayingFlutterUiListener(any());
        mainThreadTasks.forEach(Runnable::run);

        verify(renderer).removeIsDisplayingFlutterUiListener(listener);
    }
}
