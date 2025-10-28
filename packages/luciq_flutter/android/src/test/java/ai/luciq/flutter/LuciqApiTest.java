package ai.luciq.flutter;

import static ai.luciq.flutter.util.GlobalMocks.reflected;
import static ai.luciq.flutter.util.MockResult.makeResult;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.ArgumentMatchers.isNull;
import static org.mockito.Mockito.doReturn;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.mockConstruction;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.spy;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import static io.mockk.MockKKt.every;
import static io.mockk.MockKKt.mockkObject;

import io.mockk.*;

import android.app.Application;
import android.graphics.Bitmap;
import android.net.Uri;

import ai.luciq.apm.InternalAPM;
import ai.luciq.bug.BugReporting;
import ai.luciq.flutter.generated.LuciqPigeon;
import ai.luciq.flutter.modules.LuciqApi;
import ai.luciq.flutter.util.ArgsRegistry;
import ai.luciq.flutter.util.GlobalMocks;
import ai.luciq.flutter.util.MockReflected;
import ai.luciq.library.Feature;
import ai.luciq.library.Luciq;
import ai.luciq.library.LuciqColorTheme;
import ai.luciq.library.LuciqCustomTextPlaceHolder;
import ai.luciq.library.IssueType;
import ai.luciq.library.LogLevel;
import ai.luciq.library.MaskingType;
import ai.luciq.library.Platform;
import ai.luciq.library.ReproConfigurations;
import ai.luciq.library.ReproMode;
import ai.luciq.library.featuresflags.model.LuciqFeatureFlag;
import ai.luciq.library.internal.crossplatform.CoreFeature;
import ai.luciq.library.internal.crossplatform.FeaturesStateListener;
import ai.luciq.library.internal.crossplatform.InternalCore;
import ai.luciq.library.featuresflags.model.LuciqFeatureFlag;
import ai.luciq.library.internal.crossplatform.CoreFeature;
import ai.luciq.library.internal.crossplatform.FeaturesStateListener;
import ai.luciq.library.internal.crossplatform.InternalCore;
import ai.luciq.library.featuresflags.model.LuciqFeatureFlag;
import ai.luciq.library.internal.crossplatform.InternalCore;
import ai.luciq.library.invocation.LuciqInvocationEvent;
import ai.luciq.library.model.NetworkLog;
import ai.luciq.library.screenshot.ScreenshotCaptor;
import ai.luciq.library.ui.onboarding.WelcomeMessage;
import ai.luciq.survey.Surveys;
import ai.luciq.survey.callbacks.OnShowCallback;

import org.json.JSONObject;
import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import org.mockito.MockedConstruction;
import org.mockito.MockedStatic;

import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Random;
import java.util.concurrent.Callable;

import io.flutter.plugin.common.BinaryMessenger;
import kotlin.jvm.functions.Function1;

import org.mockito.Mockito;
import org.mockito.invocation.InvocationOnMock;
import org.mockito.stubbing.Answer;
import org.mockito.verification.VerificationMode;

import kotlin.jvm.functions.Function1;

import org.mockito.Mockito;
import org.mockito.invocation.InvocationOnMock;
import org.mockito.stubbing.Answer;
import org.mockito.verification.VerificationMode;

import android.graphics.Typeface;

import android.graphics.Typeface;

public class LuciqApiTest {
    private final Callable<Bitmap> screenshotProvider = () -> mock(Bitmap.class);
    private final Application mContext = mock(Application.class);
    private LuciqApi api;
    private MockedStatic<Luciq> mLuciq;
    private MockedStatic<BugReporting> mBugReporting;
    private MockedConstruction<LuciqCustomTextPlaceHolder> mCustomTextPlaceHolder;
    private MockedStatic<LuciqPigeon.LuciqHostApi> mHostApi;
    private InternalCore internalCore;
    @Before
    public void setUp() throws NoSuchMethodException {
        mCustomTextPlaceHolder = mockConstruction(LuciqCustomTextPlaceHolder.class);
        internalCore=spy(InternalCore.INSTANCE);

        BinaryMessenger mMessenger = mock(BinaryMessenger.class);
        final LuciqPigeon.FeatureFlagsFlutterApi flutterApi = new LuciqPigeon.FeatureFlagsFlutterApi(mMessenger);
        api = spy(new LuciqApi(mContext, screenshotProvider, flutterApi));
        mLuciq = mockStatic(Luciq.class);
        mBugReporting = mockStatic(BugReporting.class);
        mHostApi = mockStatic(LuciqPigeon.LuciqHostApi.class);
        GlobalMocks.setUp();
    }

    @After
    public void cleanUp() {
        mCustomTextPlaceHolder.close();
        mLuciq.close();
        mBugReporting.close();
        mHostApi.close();
        GlobalMocks.close();

    }

    @Test
    public void testInit() {
        BinaryMessenger messenger = mock(BinaryMessenger.class);

        LuciqApi.init(messenger, mContext, screenshotProvider);

        mHostApi.verify(() -> LuciqPigeon.LuciqHostApi.setup(eq(messenger), any(LuciqApi.class)));
    }

    @Test
    public void testSetCurrentPlatform() {
        api.setCurrentPlatform();

        reflected.verify(() -> MockReflected.setCurrentPlatform(Platform.FLUTTER));
    }

    @Test
    public void testSdkInit() {
        String token = "app-token";
        String appVariant = "app-variant";

        List<String> invocationEvents = Collections.singletonList("InvocationEvent.floatingButton");
        String logLevel = "LogLevel.error";

        MockedConstruction<Luciq.Builder> mLuciqBuilder = mockConstruction(Luciq.Builder.class, (mock, context) -> {
            String actualToken = (String) context.arguments().get(1);
            // Initializes Luciq with the correct token
            assertEquals(token, actualToken);
            when(mock.setInvocationEvents(any())).thenReturn(mock);
            when(mock.setSdkDebugLogsLevel(anyInt())).thenReturn(mock);
        });

        api.init(token, invocationEvents, logLevel,appVariant);

        Luciq.Builder builder = mLuciqBuilder.constructed().get(0);

        // Initializes Luciq with correct the invocation events
        assertEquals(
                "expected Luciq to be initialized using Luciq.Builder",
                1,
                mLuciqBuilder.constructed().size()
        );
        verify(builder).setInvocationEvents(LuciqInvocationEvent.FLOATING_BUTTON);
        verify(builder).setSdkDebugLogsLevel(LogLevel.ERROR);
        verify(builder).setAppVariant(appVariant);

        verify(builder).build();

        // Sets screenshot provider
        mLuciq.verify(() -> Luciq.setScreenshotProvider(screenshotProvider));

        // Sets current platform
        reflected.verify(() -> MockReflected.setCurrentPlatform(Platform.FLUTTER));
    }

    @Test
    public void testSetEnabledGivenTrue() {
        boolean isEnabled = true;

        api.setEnabled(isEnabled);

        mLuciq.verify(Luciq::enable);
    }

    @Test
    public void testSetEnabledGivenFalse() {
        boolean isEnabled = false;

        api.setEnabled(isEnabled);

        mLuciq.verify(Luciq::disable);
    }

    @Test
    public void testIsEnabled() {
        api.isEnabled();

        mLuciq.verify(Luciq::isEnabled);
    }

    @Test
    public void testIsBuilt() {
        api.isBuilt();

        mLuciq.verify(Luciq::isBuilt);
    }

    @Test
    public void testShow() {
        api.show();
        mLuciq.verify(Luciq::show);
    }

    @Test
    public void testShowWelcomeMessageWithMode() {
        String mode = "WelcomeMessageMode.live";

        api.showWelcomeMessageWithMode(mode);

        mLuciq.verify(() -> Luciq.showWelcomeMessage(WelcomeMessage.State.LIVE));
    }

    @Test
    public void testIdentifyUser() {
        String email = "inst@bug.com";
        String name = "John Doe";
        String id = "123";

        api.identifyUser(email, name, id);

        mLuciq.verify(() -> Luciq.identifyUser(name, email, id));
    }

    @Test
    public void testSetUserData() {
        String data = "premium";

        api.setUserData(data);

        mLuciq.verify(() -> Luciq.setUserData(data));
    }

    @Test
    public void testLogUserEvent() {
        String event = "sign_up";

        api.logUserEvent(event);

        mLuciq.verify(() -> Luciq.logUserEvent(event));
    }

    @Test
    public void testLogOut() {
        api.logOut();

        mLuciq.verify(Luciq::logoutUser);
    }

    @Test
    public void testSetLocale() {
        String locale = "LCQLocale.japanese";

        api.setLocale(locale);

        mLuciq.verify(() -> Luciq.setLocale(any(Locale.class)));
    }

    @Test
    public void testSetColorTheme() {
        String theme = "ColorTheme.dark";

        api.setColorTheme(theme);

        mLuciq.verify(() -> Luciq.setColorTheme(LuciqColorTheme.LuciqColorThemeDark));
    }

    @Test
    public void testSetWelcomeMessageMode() {
        String mode = "WelcomeMessageMode.beta";

        api.setWelcomeMessageMode(mode);

        mLuciq.verify(() -> Luciq.setWelcomeMessageState(WelcomeMessage.State.BETA));
    }

    @Test
    public void testSetPrimaryColor() {
    }
    @Test
    public void testSetSessionProfilerEnabledGivenTrue() {
        Boolean isEnabled = true;

        api.setSessionProfilerEnabled(isEnabled);

        mLuciq.verify(() -> Luciq.setSessionProfilerState(Feature.State.ENABLED));
    }

    @Test
    public void testSetSessionProfilerEnabledGivenFalse() {
        Boolean isEnabled = false;

        api.setSessionProfilerEnabled(isEnabled);

        mLuciq.verify(() -> Luciq.setSessionProfilerState(Feature.State.DISABLED));
    }

    @Test
    public void testSetValueForStringWithKeyWhenKeyExists() {
        String value = "Send a bug report";
        String key = "CustomTextPlaceHolderKey.reportBug";

        api.setValueForStringWithKey(value, key);

        mLuciq.verify(() -> Luciq.setCustomTextPlaceHolders(any(LuciqCustomTextPlaceHolder.class)));
    }

    @Test
    public void testSetValueForStringWithKeyWhenKeyDoesNotExists() {
        String value = "Wingardium Leviosa";
        String key = "CustomTextPlaceHolderKey.wingardiumLeviosa";

        api.setValueForStringWithKey(value, key);

        mLuciq.verify(() -> Luciq.setCustomTextPlaceHolders(any(LuciqCustomTextPlaceHolder.class)), never());
    }

    @Test
    public void testAppendTags() {
        List<String> tags = Arrays.asList("premium", "star");

        api.appendTags(tags);

        mLuciq.verify(() -> Luciq.addTags("premium", "star"));
    }

    @Test
    public void testResetTags() {
        api.resetTags();

        mLuciq.verify(Luciq::resetTags);
    }

    @Test
    public void testGetTags() {
        LuciqPigeon.Result<List<String>> result = makeResult((tags) -> assertEquals(Collections.emptyList(), tags));

        api.getTags(result);

        mLuciq.verify(Luciq::getTags);
    }



    @Test
    public void testAddFeatureFlags() {
        Map<String, String> featureFlags = new HashMap<>();
        featureFlags.put("key1", "variant1");
        api.addFeatureFlags(featureFlags);
        List<LuciqFeatureFlag> flags = new ArrayList<LuciqFeatureFlag>();
        flags.add(new LuciqFeatureFlag("key1", "variant1"));
        mLuciq.verify(() -> Luciq.addFeatureFlags(flags));
    }

    @Test
    public void testRemoveFeatureFlags() {
        List<String> featureFlags = Arrays.asList("premium", "star");

        api.removeFeatureFlags(featureFlags);

        mLuciq.verify(() -> Luciq.removeFeatureFlag(featureFlags));
    }

    @Test
    public void testClearAllFeatureFlags() {
        api.removeAllFeatureFlags();

        mLuciq.verify(Luciq::removeAllFeatureFlags);
    }

    @Test
    public void testSetUserAttribute() {
        String key = "is_premium";
        String value = "true";
        api.setUserAttribute(value, key);

        mLuciq.verify(() -> Luciq.setUserAttribute(key, value));
    }

    @Test
    public void testRemoveUserAttribute() {
        String key = "is_premium";

        api.removeUserAttribute(key);

        mLuciq.verify(() -> Luciq.removeUserAttribute(key));
    }

    @Test
    public void testGetUserAttributeForKey() {
        String key = "is_premium";
        String expected = "yup";

        LuciqPigeon.Result<String> result = makeResult((actual) -> assertEquals(expected, actual));

        mLuciq.when(() -> Luciq.getUserAttribute(key)).thenReturn(expected);

        api.getUserAttributeForKey(key, result);

        mLuciq.verify(() -> Luciq.getUserAttribute(key));
    }

    @Test
    public void testGetUserAttributes() {
        Map<String, String> expected = new HashMap<>();
        expected.put("plan", "hobby");

        LuciqPigeon.Result<Map<String, String>> result = makeResult((actual) -> assertEquals(expected, actual));

        mLuciq.when(Luciq::getAllUserAttributes).thenReturn(expected);

        api.getUserAttributes(result);

        mLuciq.verify(Luciq::getAllUserAttributes);
    }

    @Test
    public void testSetReproStepsConfig() {
        String bug = "ReproStepsMode.enabled";
        String crash = "ReproStepsMode.disabled";
        String sessionReplay = "ReproStepsMode.disabled";

        ReproConfigurations config = mock(ReproConfigurations.class);
        MockedConstruction<ReproConfigurations.Builder> mReproConfigurationsBuilder = mockConstruction(ReproConfigurations.Builder.class, (mock, context) -> {
            when(mock.setIssueMode(anyInt(), anyInt())).thenReturn(mock);
            when(mock.build()).thenReturn(config);
        });

        api.setReproStepsConfig(bug, crash, sessionReplay);

        ReproConfigurations.Builder builder = mReproConfigurationsBuilder.constructed().get(0);

        verify(builder).setIssueMode(IssueType.Bug, ReproMode.EnableWithScreenshots);
        verify(builder).setIssueMode(IssueType.AllCrashes, ReproMode.Disable);
        verify(builder).setIssueMode(IssueType.SessionReplay, ReproMode.Disable);
        verify(builder).build();

        mLuciq.verify(() -> Luciq.setReproConfigurations(config));
    }

    @Test
    public void testReportScreenChange() {
        String screenName = "HomeScreen";

        api.reportScreenChange(screenName);

        reflected.verify(() -> MockReflected.reportScreenChange(null, screenName));
        reflected.verify(() -> MockReflected.reportCurrentViewChange(screenName));
    }

    @Test
    public void testSetCustomBrandingImageGivenLightAndDark() {
        String light = "images/light_logo.png";
        String dark = "images/dark_logo.png";
        Bitmap lightLogoVariant = mock(Bitmap.class);
        Bitmap darkLogoVariant = mock(Bitmap.class);

        doReturn(lightLogoVariant).when(api).getBitmapForAsset(light);
        doReturn(darkLogoVariant).when(api).getBitmapForAsset(dark);

        api.setCustomBrandingImage(light, dark);

        reflected.verify(() -> MockReflected.setCustomBrandingImage(lightLogoVariant, darkLogoVariant));
    }

    @Test
    public void testSetCustomBrandingImageGivenLightOnly() {
        String light = "images/light_logo.png";
        String dark = "images/dark_logo.png";
        Bitmap lightLogoVariant = mock(Bitmap.class);

        doReturn(lightLogoVariant).when(api).getBitmapForAsset(light);
        doReturn(null).when(api).getBitmapForAsset(dark);

        api.setCustomBrandingImage(light, dark);

        reflected.verify(() -> MockReflected.setCustomBrandingImage(lightLogoVariant, lightLogoVariant));
    }

    @Test
    public void testSetCustomBrandingImageGivenDarkOnly() {
        String light = "images/light_logo.png";
        String dark = "images/dark_logo.png";
        Bitmap darkLogoVariant = mock(Bitmap.class);

        doReturn(null).when(api).getBitmapForAsset(light);
        doReturn(darkLogoVariant).when(api).getBitmapForAsset(dark);

        api.setCustomBrandingImage(light, dark);

        reflected.verify(() -> MockReflected.setCustomBrandingImage(darkLogoVariant, darkLogoVariant));
    }

    @Test
    public void testSetCustomBrandingImageGivenNoLogo() {
        String light = "images/light_logo.png";
        String dark = "images/dark_logo.png";

        doReturn(null).when(api).getBitmapForAsset(any());

        api.setCustomBrandingImage(light, dark);

        reflected.verify(() -> MockReflected.setCustomBrandingImage(any(), any()), never());
    }

    @Test
    public void testAddFileAttachmentWithURLWhenFileExists() throws IOException {
        String path = "buggy.txt";
        String name = "Buggy";

        // Create file for file.exists() to be true
        File file = new File(path);
        boolean fileCreated = file.exists() || file.createNewFile();
        assertTrue("Failed to create a file", fileCreated);

        api.addFileAttachmentWithURL(path, name);

        mLuciq.verify(() -> Luciq.addFileAttachment(any(Uri.class), eq(name)));

        file.delete();
    }

    @Test
    public void testAddFileAttachmentWithURLWhenFileDoesNotExists() {
        String path = "somewhere/that_does_not_exist.png";
        String name = "Buggy";

        api.addFileAttachmentWithURL(path, name);

        mLuciq.verify(() -> Luciq.addFileAttachment(any(Uri.class), eq(name)), never());
    }

    @Test
    public void testAddFileAttachmentWithData() {
        byte[] data = new byte[]{65, 100};
        String name = "Issue";

        api.addFileAttachmentWithData(data, name);

        mLuciq.verify(() -> Luciq.addFileAttachment(data, name));
    }

    @Test
    public void testClearFileAttachments() {
        api.clearFileAttachments();

        mLuciq.verify(Luciq::clearFileAttachment);
    }

    @Test
    public void testNetworkLog() {
        String url = "https://example.com";
        String requestBody = "hi";
        String responseBody = "{\"hello\":\"world\"}";
        String method = "POST";
        int responseCode = 201;
        long duration = 23000;
        HashMap<String, String> requestHeaders = new HashMap<>();
        HashMap<String, String> responseHeaders = new HashMap<>();
        Map<String, Object> data = new HashMap<>();
        data.put("url", url);
        data.put("requestBody", requestBody);
        data.put("responseBody", responseBody);
        data.put("method", method);
        data.put("responseCode", responseCode);
        data.put("requestHeaders", requestHeaders);
        data.put("responseHeaders", responseHeaders);
        data.put("duration", duration);

        MockedConstruction<NetworkLog> mNetworkLog = mockConstruction(NetworkLog.class);

        MockedConstruction<JSONObject> mJSONObject = mockConstruction(JSONObject.class, (mock, context) -> when(mock.toString(anyInt())).thenReturn("{}"));

        api.networkLog(data);

        NetworkLog networkLog = mNetworkLog.constructed().get(0);

        verify(networkLog).setDate(anyString());
        verify(networkLog).setUrl(url);
        verify(networkLog).setRequest(requestBody);
        verify(networkLog).setResponse(responseBody);
        verify(networkLog).setMethod(method);
        verify(networkLog).setResponseCode(responseCode);
        verify(networkLog).setRequestHeaders("{}");
        verify(networkLog).setResponseHeaders("{}");
        verify(networkLog).setTotalDuration(duration / 1000);
        verify(networkLog).insert();

        mJSONObject.close();
    }

    @Test
    public void testWillRedirectToStore() {
        api.willRedirectToStore();
        mLuciq.verify(Luciq::willRedirectToStore);
    }


    @Test
    public void isW3CFeatureFlagsEnabled() {
        mockkObject(new InternalCore[]{InternalCore.INSTANCE},false);
        Random random=new Random();
        Boolean isW3cExternalGeneratedHeaderEnabled = random.nextBoolean();
        Boolean isW3cExternalTraceIDEnabled = random.nextBoolean();
        Boolean isW3cCaughtHeaderEnabled = random.nextBoolean();

        every((Function1<MockKMatcherScope, Boolean>) mockKMatcherScope -> InternalCore.INSTANCE._isFeatureEnabled(CoreFeature.W3C_ATTACHING_GENERATED_HEADER)).returns(isW3cExternalGeneratedHeaderEnabled);
        every((Function1<MockKMatcherScope, Boolean>) mockKMatcherScope -> InternalCore.INSTANCE._isFeatureEnabled(CoreFeature.W3C_EXTERNAL_TRACE_ID)).returns(isW3cExternalTraceIDEnabled);
        every((Function1<MockKMatcherScope, Boolean>) mockKMatcherScope -> InternalCore.INSTANCE._isFeatureEnabled(CoreFeature.W3C_ATTACHING_CAPTURED_HEADER)).returns(isW3cCaughtHeaderEnabled);


        Map<String, Boolean> flags = api.isW3CFeatureFlagsEnabled();
        assertEquals(isW3cExternalGeneratedHeaderEnabled, flags.get("isW3cExternalGeneratedHeaderEnabled"));
        assertEquals(isW3cExternalTraceIDEnabled, flags.get("isW3cExternalTraceIDEnabled"));
        assertEquals(isW3cCaughtHeaderEnabled, flags.get("isW3cCaughtHeaderEnabled"));

    }

    @Test
    public void testSetNetworkLogBodyEnabled() {
        api.setNetworkLogBodyEnabled(true);

        mLuciq.verify(() -> Luciq.setNetworkLogBodyEnabled(true));
    }

    @Test
    public void testSetAppVariant() {
        String appVariant = "app-variant";
        api.setAppVariant(appVariant);

        mLuciq.verify(() -> Luciq.setAppVariant(appVariant));
    }

    @Test
    public void testSetNetworkLogBodyDisabled() {
        api.setNetworkLogBodyEnabled(false);

        mLuciq.verify(() -> Luciq.setNetworkLogBodyEnabled(false));
    }

    @Test
    public void testSetThemeWithAllProperties() {
        Map<String, Object> themeConfig = new HashMap<>();
        themeConfig.put("primaryColor", "#FF6B6B");
        themeConfig.put("backgroundColor", "#FFFFFF");
        themeConfig.put("titleTextColor", "#000000");
        themeConfig.put("primaryTextColor", "#333333");
        themeConfig.put("secondaryTextColor", "#666666");
        themeConfig.put("primaryTextStyle", "bold");
        themeConfig.put("secondaryTextStyle", "italic");
        themeConfig.put("ctaTextStyle", "bold_italic");
        themeConfig.put("primaryFontAsset", "assets/fonts/CustomFont-Regular.ttf");
        themeConfig.put("secondaryFontAsset", "assets/fonts/CustomFont-Bold.ttf");
        themeConfig.put("ctaFontAsset", "assets/fonts/CustomFont-Italic.ttf");

        MockedConstruction<ai.luciq.library.model.LuciqTheme.Builder> mThemeBuilder =
            mockConstruction(ai.luciq.library.model.LuciqTheme.Builder.class, (mock, context) -> {
                when(mock.setPrimaryColor(anyInt())).thenReturn(mock);
                when(mock.setBackgroundColor(anyInt())).thenReturn(mock);
                when(mock.setTitleTextColor(anyInt())).thenReturn(mock);
                when(mock.setPrimaryTextColor(anyInt())).thenReturn(mock);
                when(mock.setSecondaryTextColor(anyInt())).thenReturn(mock);
                when(mock.setPrimaryTextStyle(anyInt())).thenReturn(mock);
                when(mock.setSecondaryTextStyle(anyInt())).thenReturn(mock);
                when(mock.setCtaTextStyle(anyInt())).thenReturn(mock);
                when(mock.setPrimaryTextFont(any(Typeface.class))).thenReturn(mock);
                when(mock.setSecondaryTextFont(any(Typeface.class))).thenReturn(mock);
                when(mock.setCtaTextFont(any(Typeface.class))).thenReturn(mock);
                when(mock.build()).thenReturn(mock(ai.luciq.library.model.LuciqTheme.class));
            });

        api.setTheme(themeConfig);

        ai.luciq.library.model.LuciqTheme.Builder builder = mThemeBuilder.constructed().get(0);

        verify(builder).setPrimaryColor(anyInt());
        verify(builder).setBackgroundColor(anyInt());
        verify(builder).setTitleTextColor(anyInt());
        verify(builder).setPrimaryTextColor(anyInt());
        verify(builder).setSecondaryTextColor(anyInt());
        verify(builder).setPrimaryTextStyle(Typeface.BOLD);
        verify(builder).setSecondaryTextStyle(Typeface.ITALIC);
        verify(builder).setCtaTextStyle(Typeface.BOLD_ITALIC);

        mLuciq.verify(() -> Luciq.setTheme(any(ai.luciq.library.model.LuciqTheme.class)));
    }

    @Test
    public void testSetFullscreen() {
        boolean isEnabled = true;

        api.setFullscreen(isEnabled);

        mLuciq.verify(() -> Luciq.setFullscreen(isEnabled));
    }

    @Test
    public void testSetFullscreenDisabled() {
        boolean isEnabled = false;

        api.setFullscreen(isEnabled);

        mLuciq.verify(() -> Luciq.setFullscreen(isEnabled));
    }

    @Test
    public void testSetScreenshotCaptor() {
        InternalCore internalCore = spy(InternalCore.INSTANCE);

        LuciqApi.setScreenshotCaptor(any(), internalCore);
        verify(internalCore)._setScreenshotCaptor(any(ScreenshotCaptor.class));
    }

    @Test
    public void testSetUserStepsEnabledGivenTrue() {
        boolean isEnabled = true;

        api.setEnableUserSteps(isEnabled);

        mLuciq.verify(() -> Luciq.setTrackingUserStepsState(Feature.State.ENABLED));
    }

    @Test
    public void testSetUserStepsEnabledGivenFalse() {
        boolean isEnabled = false;

        api.setEnableUserSteps(isEnabled);

        mLuciq.verify(() -> Luciq.setTrackingUserStepsState(Feature.State.DISABLED));
    }

    @Test
    public void testLogUserSteps() {

        final String gestureType = "GestureType.tap";
        final String message = "message";
        final String view = "view";

        api.logUserSteps(gestureType, message,view);

        reflected.verify(() -> MockReflected.addUserStep(anyLong(), eq(ArgsRegistry.gestureStepType.get(gestureType)), eq(message), isNull(), eq(view)));

    }

    @Test
    public void testAutoMasking() {
        String maskLabel = "AutoMasking.labels";
        String maskTextInputs = "AutoMasking.textInputs";
        String maskMedia = "AutoMasking.media";
        String maskNone = "AutoMasking.none";


        api.enableAutoMasking(List.of(maskLabel, maskMedia, maskTextInputs,maskNone));

        mLuciq.verify(() -> Luciq.setAutoMaskScreenshotsTypes(MaskingType.LABELS,MaskingType.MEDIA,MaskingType.TEXT_INPUTS,MaskingType.MASK_NOTHING));
    }


    @Test
    public void testGetNetworkBodyMaxSize() {
        double expected = 10240;
        LuciqPigeon.Result<Double> result = makeResult((actual) -> assertEquals((Double) expected, actual));

        mockkObject(new InternalCore[]{InternalCore.INSTANCE}, false);
        every(mockKMatcherScope -> InternalCore.INSTANCE.get_networkLogCharLimit()).returns((int) expected);

        api.getNetworkBodyMaxSize(result);
    }
    @Test
    public void testSetNetworkAutoMaskingEnabledGivenFalse() {
        boolean isEnabled = false;

        api.setNetworkAutoMaskingEnabled(isEnabled);
        mLuciq.verify(() -> Luciq.setNetworkAutoMaskingState(Feature.State.DISABLED));
    }
    @Test
    public void testSetNetworkAutoMaskingEnabledGivenTrue() {
        boolean isEnabled = true;

        api.setNetworkAutoMaskingEnabled(isEnabled);
        mLuciq.verify(() -> Luciq.setNetworkAutoMaskingState(Feature.State.ENABLED));
    }
}
