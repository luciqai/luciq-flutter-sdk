package ai.luciq.flutter;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.mockStatic;

import ai.luciq.bug.BugReporting;
import ai.luciq.bug.invocation.Option;
import ai.luciq.flutter.generated.BugReportingPigeon;
import ai.luciq.flutter.modules.BugReportingApi;
import ai.luciq.flutter.util.GlobalMocks;
import ai.luciq.library.Feature;
import ai.luciq.library.OnSdkDismissCallback;
import ai.luciq.library.extendedbugreport.ExtendedBugReport;
import ai.luciq.library.invocation.LuciqInvocationEvent;
import ai.luciq.library.invocation.OnInvokeCallback;
import ai.luciq.library.invocation.util.LuciqFloatingButtonEdge;
import ai.luciq.library.invocation.util.LuciqVideoRecordingButtonPosition;

import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import org.mockito.MockedStatic;

import java.util.Arrays;
import java.util.List;

import io.flutter.plugin.common.BinaryMessenger;

public class BugReportingApiTest {
    private final BinaryMessenger mMessenger = mock(BinaryMessenger.class);
    private final BugReportingPigeon.BugReportingFlutterApi flutterApi = new BugReportingPigeon.BugReportingFlutterApi(mMessenger);
    private final BugReportingApi api = new BugReportingApi(flutterApi);
    private MockedStatic<BugReporting> mBugReporting;
    private MockedStatic<BugReportingPigeon.BugReportingHostApi> mHostApi;

    @Before
    public void setUp() throws NoSuchMethodException {
        mBugReporting = mockStatic(BugReporting.class);
        mHostApi = mockStatic(BugReportingPigeon.BugReportingHostApi.class);
        GlobalMocks.setUp();
    }

    @After
    public void cleanUp() {
        mBugReporting.close();
        mHostApi.close();
        GlobalMocks.close();
    }

    @Test
    public void testInit() {
        BugReportingApi.init(mMessenger);

        mHostApi.verify(() -> BugReportingPigeon.BugReportingHostApi.setup(eq(mMessenger), any(BugReportingApi.class)));
    }

    @Test
    public void testSetEnabledGivenTrue() {
        boolean isEnabled = true;

        api.setEnabled(isEnabled);

        mBugReporting.verify(() -> BugReporting.setState(Feature.State.ENABLED));
    }

    @Test
    public void testSetEnabledGivenFalse() {
        boolean isEnabled = false;

        api.setEnabled(isEnabled);

        mBugReporting.verify(() -> BugReporting.setState(Feature.State.DISABLED));
    }

    @Test
    public void testShow() {
        String reportType = "ReportType.bug";
        List<String> invocationOptions = Arrays.asList("InvocationOption.emailFieldOptional", "InvocationOption.disablePostSendingDialog");

        api.show(reportType, invocationOptions);

        mBugReporting.verify(() -> BugReporting.show(BugReporting.ReportType.BUG, Option.EMAIL_FIELD_OPTIONAL, Option.DISABLE_POST_SENDING_DIALOG));
    }

    @Test
    public void testSetInvocationEvents() {
        List<String> events = Arrays.asList("InvocationEvent.floatingButton", "InvocationEvent.screenshot");

        api.setInvocationEvents(events);

        mBugReporting.verify(() -> BugReporting.setInvocationEvents(LuciqInvocationEvent.FLOATING_BUTTON, LuciqInvocationEvent.SCREENSHOT));
    }

    @Test
    public void testSetReportTypes() {
        List<String> types = Arrays.asList("ReportType.bug", "ReportType.feedback");

        api.setReportTypes(types);

        mBugReporting.verify(() -> BugReporting.setReportTypes(BugReporting.ReportType.BUG, BugReporting.ReportType.FEEDBACK));
    }

    @Test
    public void testSetExtendedBugReportingMode() {
        String mode = "ExtendedBugReportMode.enabledWithOptionalFields";

        api.setExtendedBugReportMode(mode);

        mBugReporting.verify(() -> BugReporting.setExtendedBugReportState(ExtendedBugReport.State.ENABLED_WITH_OPTIONAL_FIELDS));
    }

    @Test
    public void testSetInvocationOptions() {
        List<String> options = Arrays.asList("InvocationOption.emailFieldHidden", "InvocationOption.commentFieldRequired");

        api.setInvocationOptions(options);

        mBugReporting.verify(() -> BugReporting.setOptions(Option.EMAIL_FIELD_HIDDEN, Option.COMMENT_FIELD_REQUIRED));
    }

    @Test
    public void testSetFloatingButtonEdge() {
        String edge = "FloatingButtonEdge.left";
        Long offset = 100L;

        api.setFloatingButtonEdge(edge, offset);

        mBugReporting.verify(() -> BugReporting.setFloatingButtonEdge(LuciqFloatingButtonEdge.LEFT));
        mBugReporting.verify(() -> BugReporting.setFloatingButtonOffset(offset.intValue()));
    }

    @Test
    public void testSetVideoRecordingFloatingButtonPosition() {
        String position = "Position.topRight";

        api.setVideoRecordingFloatingButtonPosition(position);

        mBugReporting.verify(() -> BugReporting.setVideoRecordingFloatingButtonPosition(LuciqVideoRecordingButtonPosition.TOP_RIGHT));
    }

    @Test
    public void testSetShakingThresholdForAndroid() {
        Long threshold = 300L;
        
        api.setShakingThresholdForAndroid(threshold);

        mBugReporting.verify(() -> BugReporting.setShakingThreshold(threshold.intValue()));
    }

    @Test
    public void testSetEnabledAttachmentTypes() {
        boolean screenshot = true;
        boolean extraScreenshot = true;
        boolean galleryImage = false;
        boolean screenRecording = true;

        api.setEnabledAttachmentTypes(screenshot, extraScreenshot, galleryImage, screenRecording);

        mBugReporting.verify(() -> BugReporting.setAttachmentTypesEnabled(screenshot, extraScreenshot, galleryImage, screenRecording));
    }

    @Test
    public void testBindOnInvokeCallback() {
        api.bindOnInvokeCallback();

        mBugReporting.verify(() -> BugReporting.setOnInvokeCallback(any(OnInvokeCallback.class)));
    }

    @Test
    public void testBindOnDismissCallback() {
        api.bindOnDismissCallback();

        mBugReporting.verify(() -> BugReporting.setOnDismissCallback(any(OnSdkDismissCallback.class)));
    }

    @Test
    public void testSetDisclaimerText() {
        String text = "My very own disclaimer text";

        api.setDisclaimerText(text);

        mBugReporting.verify(() -> BugReporting.setDisclaimerText(text));
    }

    @Test
    public void testSetCommentMinimumCharacterCount() {
        Long limit = 100L;
        List<String> reportTypes = Arrays.asList("ReportType.bug", "ReportType.question");

        api.setCommentMinimumCharacterCount(limit, reportTypes);

        mBugReporting.verify(() -> BugReporting.setCommentMinimumCharacterCountForBugReportType(limit.intValue(), BugReporting.ReportType.BUG, BugReporting.ReportType.QUESTION));
    }

    @Test
    public void TestAddUserConsents() {

               final String key = "testKey";
               final String description = "Consent description";
               final boolean mandatory = true;
               final boolean checked = true;
               final String actionType = "UserConsentActionType.dropAutoCapturedMedia";


               api.addUserConsents(key, description, mandatory, checked, actionType);

               mBugReporting.verify(()->BugReporting.addUserConsent(key, description, mandatory, checked,"drop_auto_captured_media"));
    }
    @Test
    public void testSetProactiveReportingConfigurations() {
        // given
        boolean enabled = true;
        long gapBetweenDialogs = 20;
        long modeDelay = 30;

        // when
        api.setProactiveReportingConfigurations(enabled, gapBetweenDialogs, modeDelay);

        // then
        mBugReporting.verify(() -> BugReporting.setProactiveReportingConfigurations(argThat(config ->
                config.getModalsGap() == gapBetweenDialogs &&
                        config.getDetectionGap() == modeDelay &&
                        config.isEnabled() == enabled
        )));


    }
}
