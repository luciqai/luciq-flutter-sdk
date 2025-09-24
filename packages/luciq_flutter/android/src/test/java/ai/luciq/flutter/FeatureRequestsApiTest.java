package ai.luciq.flutter;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.mockStatic;

import ai.luciq.featuresrequest.ActionType;
import ai.luciq.featuresrequest.FeatureRequests;
import ai.luciq.flutter.generated.FeatureRequestsPigeon;
import ai.luciq.flutter.modules.FeatureRequestsApi;
import ai.luciq.flutter.util.GlobalMocks;

import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import org.mockito.MockedStatic;

import java.util.Arrays;
import java.util.List;

import io.flutter.plugin.common.BinaryMessenger;


public class FeatureRequestsApiTest {
    private final FeatureRequestsApi api = new FeatureRequestsApi();
    private MockedStatic<FeatureRequests> mFeatureRequests;
    private MockedStatic<FeatureRequestsPigeon.FeatureRequestsHostApi> mHostApi;

    @Before
    public void setUp() throws NoSuchMethodException {
        mFeatureRequests = mockStatic(FeatureRequests.class);
        mHostApi = mockStatic(FeatureRequestsPigeon.FeatureRequestsHostApi.class);
        GlobalMocks.setUp();
    }

    @After
    public void cleanUp() {
        mFeatureRequests.close();
        mHostApi.close();
        GlobalMocks.close();
    }

    @Test
    public void testInit() {
        BinaryMessenger mMessenger = mock(BinaryMessenger.class);

        FeatureRequestsApi.init(mMessenger);

        mHostApi.verify(() -> FeatureRequestsPigeon.FeatureRequestsHostApi.setup(eq(mMessenger), any(FeatureRequestsApi.class)));
    }

    @Test
    public void testShow() {
        api.show();

        mFeatureRequests.verify(FeatureRequests::show);
    }

    @Test
    public void testSetEmailFieldRequired() {
        boolean isRequired = true;
        List<String> actionTypes = Arrays.asList("ActionType.requestNewFeature", "ActionType.addCommentToFeature");

        api.setEmailFieldRequired(isRequired, actionTypes);

        mFeatureRequests.verify(() -> FeatureRequests.setEmailFieldRequired(isRequired, ActionType.REQUEST_NEW_FEATURE, ActionType.ADD_COMMENT_TO_FEATURE));
    }
}
