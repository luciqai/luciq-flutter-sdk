package ai;

import static ai.luciq.flutter.util.GlobalMocks.reflected;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.spy;

import ai.luciq.flutter.modules.LuciqInitializer;
import ai.luciq.flutter.util.GlobalMocks;
import ai.luciq.flutter.util.MockReflected;
import ai.luciq.library.Luciq;
import ai.luciq.library.Platform;

import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import org.mockito.MockedStatic;

import io.flutter.plugin.common.BinaryMessenger;

public class LuciqInitializerTest {
    private LuciqInitializer api;
    private MockedStatic<Luciq> mLuciq;

    @Before
    public void setUp() throws NoSuchMethodException {

        BinaryMessenger mMessenger = mock(BinaryMessenger.class);
        api = spy(LuciqInitializer.getInstance());
        mLuciq = mockStatic(Luciq.class);
        GlobalMocks.setUp();
    }

    @After
    public void cleanUp() {
        mLuciq.close();
        GlobalMocks.close();

    }

    @Test
    public void testSetCurrentPlatform() {
        api.setCurrentPlatform();

        reflected.verify(() -> MockReflected.setCurrentPlatform(Platform.FLUTTER));
    }
}
