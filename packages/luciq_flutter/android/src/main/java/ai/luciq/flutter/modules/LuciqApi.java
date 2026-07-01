package ai.luciq.flutter.modules;

import android.app.Application;
import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Typeface;
import android.net.Uri;
import android.os.Build;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.VisibleForTesting;

import org.jetbrains.annotations.NotNull;
import org.json.JSONObject;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.concurrent.Callable;

import ai.luciq.flutter.generated.LuciqPigeon;
import ai.luciq.flutter.util.ArgsRegistry;
import ai.luciq.flutter.util.LuciqFlutterDebugTags;
import ai.luciq.flutter.util.LuciqFlutterLogger;
import ai.luciq.flutter.util.Reflection;
import ai.luciq.flutter.util.ThreadManager;
import ai.luciq.flutter.util.privateViews.ScreenshotCaptor;
import ai.luciq.library.Feature;
import ai.luciq.library.IssueType;
import ai.luciq.library.LogLevel;
import ai.luciq.library.Luciq;
import ai.luciq.library.LuciqColorTheme;
import ai.luciq.library.LuciqCustomTextPlaceHolder;
import ai.luciq.library.Platform;
import ai.luciq.library.ReproConfigurations;
import ai.luciq.library.featuresflags.model.LuciqFeatureFlag;
import ai.luciq.library.internal.crossplatform.CoreFeature;
import ai.luciq.library.internal.crossplatform.CoreFeaturesState;
import ai.luciq.library.internal.crossplatform.FeaturesStateListener;
import ai.luciq.library.internal.crossplatform.InternalCore;
import ai.luciq.library.internal.module.LuciqLocale;
import ai.luciq.library.invocation.LuciqInvocationEvent;
import ai.luciq.library.model.NetworkLog;
import ai.luciq.library.screenshot.instacapture.ScreenshotRequest;
import ai.luciq.library.ui.onboarding.WelcomeMessage;
import io.flutter.FlutterInjector;
import io.flutter.embedding.engine.loader.FlutterLoader;
import io.flutter.plugin.common.BinaryMessenger;

public class LuciqApi implements LuciqPigeon.LuciqHostApi {
    private final String TAG = LuciqApi.class.getName();
    private final Context context;
    private final Callable<Bitmap> screenshotProvider;
    private final LuciqCustomTextPlaceHolder placeHolder = new LuciqCustomTextPlaceHolder();

    private final LuciqPigeon.FeatureFlagsFlutterApi featureFlagsFlutterApi;

    public static void init(BinaryMessenger messenger, Context context, Callable<Bitmap> screenshotProvider) {
        final LuciqPigeon.FeatureFlagsFlutterApi flutterApi = new LuciqPigeon.FeatureFlagsFlutterApi(messenger);

        final LuciqApi api = new LuciqApi(context, screenshotProvider, flutterApi);
        LuciqPigeon.LuciqHostApi.setup(messenger, api);
    }

    public LuciqApi(Context context, Callable<Bitmap> screenshotProvider, LuciqPigeon.FeatureFlagsFlutterApi featureFlagsFlutterApi) {
        this.context = context;
        this.screenshotProvider = screenshotProvider;
        this.featureFlagsFlutterApi = featureFlagsFlutterApi;
    }

    @VisibleForTesting
    public void setCurrentPlatform() {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.CORE, "[Luciq.setCurrentPlatform] phase=enter");
        try {
            Method method = Reflection.getMethod(Class.forName("ai.luciq.library.Luciq"), "setCurrentPlatform", int.class);
            if (method != null) {
                method.invoke(null, Platform.FLUTTER);
                LuciqFlutterLogger.d(LuciqFlutterDebugTags.CORE, "[Luciq.setCurrentPlatform] phase=exit");
            } else {
                LuciqFlutterLogger.e(LuciqFlutterDebugTags.CORE,
                        "[Luciq.setCurrentPlatform] phase=error errorType=NoSuchMethodException reflectionFailure=true");
            }
        } catch (Exception e) {
            LuciqFlutterLogger.e(LuciqFlutterDebugTags.CORE,
                    "[Luciq.setCurrentPlatform] phase=error errorType=" + e.getClass().getSimpleName(),
                    e);
        }
    }

    @Override
    public void setEnabled(@NonNull Boolean isEnabled) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.CORE, "[Luciq.setEnabled] phase=enter isEnabled=" + isEnabled);
        try {
            if (isEnabled)
                Luciq.enable();
            else
                Luciq.disable();
            LuciqFlutterLogger.d(LuciqFlutterDebugTags.CORE, "[Luciq.setEnabled] phase=exit");
        } catch (Exception e) {
            LuciqFlutterLogger.e(LuciqFlutterDebugTags.CORE,
                    "[Luciq.setEnabled] phase=error errorType=" + e.getClass().getSimpleName(),
                    e);
        }
    }

    @NotNull
    @Override
    public Boolean isEnabled() {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.CORE, "[Luciq.isEnabled] phase=enter");
        Boolean enabled = Luciq.isEnabled();
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.CORE, "[Luciq.isEnabled] phase=exit result=" + enabled);
        return enabled;
    }

    @NotNull
    @Override
    public Boolean isBuilt() {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.CORE, "[Luciq.isBuilt] phase=enter");
        Boolean built = Luciq.isBuilt();
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.CORE, "[Luciq.isBuilt] phase=exit result=" + built);
        return built;
    }

    @Override
    public void init(@NonNull String token, @NonNull List<String> invocationEvents, @NonNull String debugLogsLevel, @Nullable String appVariant) {
        final Application application = (Application) context;
        // HashMap.getOrDefault bypasses ArgsMap's NonNull-checking get override,
        // so an unrecognized debugLogsLevel string falls back to ERROR instead
        // of NPE-ing init.
        int parsedLogLevel = LogLevel.ERROR;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            parsedLogLevel = ArgsRegistry.sdkLogLevels.getOrDefault(debugLogsLevel, LogLevel.ERROR);
        }
        LuciqFlutterLogger.setLevel(parsedLogLevel);
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.CORE,
                "[Luciq.init] phase=enter tokenPresent=" + (token != null && !token.isEmpty())
                        + " invocationEventsCount=" + invocationEvents.size()
                        + " debugLogsLevel=" + debugLogsLevel
                        + " appVariantPresent=" + (appVariant != null));

        setCurrentPlatform();

        LuciqInvocationEvent[] invocationEventsArray = new LuciqInvocationEvent[invocationEvents.size()];
        for (int i = 0; i < invocationEvents.size(); i++) {
            String key = invocationEvents.get(i);
            invocationEventsArray[i] = ArgsRegistry.invocationEvents.get(key);
        }

        Luciq.Builder builder = new Luciq.Builder(application, token)
                .setInvocationEvents(invocationEventsArray)
                .setSdkDebugLogsLevel(parsedLogLevel);
        if (appVariant != null) {
            builder.setAppVariant(appVariant);
        }

        builder.build();

        Luciq.setScreenshotProvider(screenshotProvider);
        try {
            Class<?> myClass = Class.forName("ai.luciq.library.Luciq");
            // Enable/Disable native user steps capturing
            Method method = myClass.getDeclaredMethod("shouldDisableNativeUserStepsCapturing", boolean.class);
            method.setAccessible(true);
            method.invoke(null, true);
        } catch (Exception e) {
            LuciqFlutterLogger.e(LuciqFlutterDebugTags.CORE,
                    "[Luciq.init] phase=error errorType=" + e.getClass().getSimpleName(),
                    e);
        }
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.CORE, "[Luciq.init] phase=exit");
    }

    @Override
    public void enableAutoMasking(@NonNull List<String> autoMasking) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.CORE,
                "[Luciq.enableAutoMasking] phase=enter autoMaskingCount=" + autoMasking.size());
        int[] autoMaskingArray = new int[autoMasking.size()];
        for (int i = 0; i < autoMasking.size(); i++) {
            String key = autoMasking.get(i);
            autoMaskingArray[i] = ArgsRegistry.autoMasking.get(key);
        }

        Luciq.setAutoMaskScreenshotsTypes(Arrays.copyOf(autoMaskingArray, autoMaskingArray.length));
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.CORE, "[Luciq.enableAutoMasking] phase=exit");
    }

    @Override
    public void show() {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.CORE, "[Luciq.show] phase=enter");
        Luciq.show();
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.CORE, "[Luciq.show] phase=exit");
    }

    @Override
    public void showWelcomeMessageWithMode(@NonNull String mode) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.CORE,
                "[Luciq.showWelcomeMessageWithMode] phase=enter mode=" + mode);
        WelcomeMessage.State resolvedMode = ArgsRegistry.welcomeMessageStates.get(mode);
        Luciq.showWelcomeMessage(resolvedMode);
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.CORE, "[Luciq.showWelcomeMessageWithMode] phase=exit");
    }

    @Override
    public void identifyUser(@Nullable String email, @Nullable String name, @Nullable String userId) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.CORE,
                "[Luciq.identifyUser] phase=enter emailPresent=" + (email != null && !email.isEmpty())
                        + " namePresent=" + (name != null && !name.isEmpty())
                        + " userIdPresent=" + (userId != null && !userId.isEmpty()));
        Luciq.identifyUser(name, email, userId);
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.CORE, "[Luciq.identifyUser] phase=exit");
    }

    @Override
    public void setUserData(@NonNull String data) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.CORE,
                "[Luciq.setUserData] phase=enter length=" + data.length());
        Luciq.setUserData(data);
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.CORE, "[Luciq.setUserData] phase=exit");
    }

    @Override
    public void setAppVariant(@NonNull String appVariant) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.CORE,
                "[Luciq.setAppVariant] phase=enter length=" + appVariant.length());
        try {
            Luciq.setAppVariant(appVariant);
            LuciqFlutterLogger.d(LuciqFlutterDebugTags.CORE, "[Luciq.setAppVariant] phase=exit");
        } catch (Exception e) {
            LuciqFlutterLogger.e(LuciqFlutterDebugTags.CORE,
                    "[Luciq.setAppVariant] phase=error errorType=" + e.getClass().getSimpleName(),
                    e);
        }

    }

    @Override
    public void logUserEvent(@NonNull String name) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.CORE,
                "[Luciq.logUserEvent] phase=enter length=" + name.length());
        Luciq.logUserEvent(name);
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.CORE, "[Luciq.logUserEvent] phase=exit");
    }

    @Override
    public void logOut() {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.CORE, "[Luciq.logOut] phase=enter");
        Luciq.logoutUser();
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.CORE, "[Luciq.logOut] phase=exit");
    }

    @Override
    public void setEnableUserSteps(@NonNull Boolean isEnabled) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.CORE,
                "[Luciq.setEnableUserSteps] phase=enter isEnabled=" + isEnabled);
        Luciq.setTrackingUserStepsState(isEnabled ? Feature.State.ENABLED : Feature.State.DISABLED);
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.CORE, "[Luciq.setEnableUserSteps] phase=exit");
    }

    @Override

    public void logUserSteps(@NonNull String gestureType, @NonNull String message, @Nullable String viewName) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.CORE,
                "[Luciq.logUserSteps] phase=enter gestureType=" + gestureType
                        + " messageLength=" + message.length()
                        + " viewNamePresent=" + (viewName != null));
        try {
            final String stepType = ArgsRegistry.gestureStepType.get(gestureType);
            final long timeStamp = System.currentTimeMillis();
            String view = "";

            Method method = Reflection.getMethod(Class.forName("ai.luciq.library.Luciq"), "addUserStep",
                    long.class, String.class, String.class, String.class, String.class);
            if (method != null) {
                if (viewName != null) {
                    view = viewName;
                }

                method.invoke(null, timeStamp, stepType, message, null, view);
                LuciqFlutterLogger.d(LuciqFlutterDebugTags.CORE, "[Luciq.logUserSteps] phase=exit");
            } else {
                LuciqFlutterLogger.e(LuciqFlutterDebugTags.CORE,
                        "[Luciq.logUserSteps] phase=error errorType=NoSuchMethodException reflectionFailure=true");
            }
        } catch (Exception e) {
            LuciqFlutterLogger.e(LuciqFlutterDebugTags.CORE,
                    "[Luciq.logUserSteps] phase=error errorType=" + e.getClass().getSimpleName(),
                    e);
        }
    }

    @Override
    public void setLocale(@NonNull String locale) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.CORE, "[Luciq.setLocale] phase=enter locale=" + locale);
        final LuciqLocale resolvedLocale = ArgsRegistry.locales.get(locale);
        Luciq.setLocale(new Locale(resolvedLocale.getCode(), resolvedLocale.getCountry()));
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.CORE, "[Luciq.setLocale] phase=exit");
    }

    @Override
    public void setColorTheme(@NonNull String theme) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.CORE, "[Luciq.setColorTheme] phase=enter theme=" + theme);
        LuciqColorTheme resolvedTheme = ArgsRegistry.colorThemes.get(theme);
        Luciq.setColorTheme(resolvedTheme);
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.CORE, "[Luciq.setColorTheme] phase=exit");
    }

    @Override
    public void setWelcomeMessageMode(@NonNull String mode) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.CORE, "[Luciq.setWelcomeMessageMode] phase=enter mode=" + mode);
        WelcomeMessage.State resolvedMode = ArgsRegistry.welcomeMessageStates.get(mode);
        Luciq.setWelcomeMessageState(resolvedMode);
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.CORE, "[Luciq.setWelcomeMessageMode] phase=exit");
    }


    @Override
    public void setSessionProfilerEnabled(@NonNull Boolean enabled) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.CORE,
                "[Luciq.setSessionProfilerEnabled] phase=enter enabled=" + enabled);
        if (enabled) {
            Luciq.setSessionProfilerState(Feature.State.ENABLED);
        } else {
            Luciq.setSessionProfilerState(Feature.State.DISABLED);
        }
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.CORE, "[Luciq.setSessionProfilerEnabled] phase=exit");
    }

    @Override
    public void setValueForStringWithKey(@NonNull String value, @NonNull String key) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.CORE,
                "[Luciq.setValueForStringWithKey] phase=enter key=" + key + " valueLength=" + value.length());
        if (ArgsRegistry.placeholders.containsKey(key)) {
            LuciqCustomTextPlaceHolder.Key resolvedKey = ArgsRegistry.placeholders.get(key);
            placeHolder.set(resolvedKey, value);
            Luciq.setCustomTextPlaceHolders(placeHolder);
            LuciqFlutterLogger.d(LuciqFlutterDebugTags.CORE, "[Luciq.setValueForStringWithKey] phase=exit");
        } else {
            LuciqFlutterLogger.d(LuciqFlutterDebugTags.CORE,
                    "[Luciq.setValueForStringWithKey] phase=exit iosOnly=true key=" + key);
        }
    }

    @Override
    public void appendTags(@NonNull List<String> tags) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.CORE,
                "[Luciq.appendTags] phase=enter count=" + tags.size());
        Luciq.addTags(tags.toArray(new String[0]));
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.CORE, "[Luciq.appendTags] phase=exit");
    }

    @Override
    public void resetTags() {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.CORE, "[Luciq.resetTags] phase=enter");
        Luciq.resetTags();
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.CORE, "[Luciq.resetTags] phase=exit");
    }

    @Override
    public void getTags(LuciqPigeon.Result<List<String>> result) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.CORE, "[Luciq.getTags] phase=enter");
        ThreadManager.runOnBackground(
                new Runnable() {
                    @Override
                    public void run() {
                        final List<String> tags = Luciq.getTags();

                        ThreadManager.runOnMainThread(new Runnable() {
                            @Override
                            public void run() {
                                LuciqFlutterLogger.d(LuciqFlutterDebugTags.CORE,
                                        "[Luciq.getTags] phase=exit resultPresent=" + (tags != null)
                                                + " resultCount=" + (tags != null ? tags.size() : 0));
                                result.success(tags);
                            }
                        });
                    }
                }
        );
    }



    @Override
    public void addFeatureFlags(@NonNull Map<String, String> featureFlags) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.FEATURE_FLAGS,
                "[Luciq.addFeatureFlags] phase=enter count=" + featureFlags.size());
        try {
            List<LuciqFeatureFlag> features = new ArrayList<>();
            for (Map.Entry<String, String> entry : featureFlags.entrySet()) {
                features.add(new LuciqFeatureFlag(entry.getKey(), entry.getValue().isEmpty() ? null : entry.getValue()));
            }
            Luciq.addFeatureFlags(features);
            LuciqFlutterLogger.d(LuciqFlutterDebugTags.FEATURE_FLAGS, "[Luciq.addFeatureFlags] phase=exit");
        } catch (Exception e) {
            LuciqFlutterLogger.e(LuciqFlutterDebugTags.FEATURE_FLAGS,
                    "[Luciq.addFeatureFlags] phase=error errorType=" + e.getClass().getSimpleName(),
                    e);
        }
    }

    @Override
    public void removeFeatureFlags(@NonNull List<String> featureFlags) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.FEATURE_FLAGS,
                "[Luciq.removeFeatureFlags] phase=enter count=" + featureFlags.size());
        try {
            Luciq.removeFeatureFlag(featureFlags);
            LuciqFlutterLogger.d(LuciqFlutterDebugTags.FEATURE_FLAGS, "[Luciq.removeFeatureFlags] phase=exit");
        } catch (Exception e) {
            LuciqFlutterLogger.e(LuciqFlutterDebugTags.FEATURE_FLAGS,
                    "[Luciq.removeFeatureFlags] phase=error errorType=" + e.getClass().getSimpleName(),
                    e);
        }
    }

    @Override
    public void removeAllFeatureFlags() {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.FEATURE_FLAGS, "[Luciq.removeAllFeatureFlags] phase=enter");
        try {
            Luciq.removeAllFeatureFlags();
            LuciqFlutterLogger.d(LuciqFlutterDebugTags.FEATURE_FLAGS, "[Luciq.removeAllFeatureFlags] phase=exit");
        } catch (Exception e) {
            LuciqFlutterLogger.e(LuciqFlutterDebugTags.FEATURE_FLAGS,
                    "[Luciq.removeAllFeatureFlags] phase=error errorType=" + e.getClass().getSimpleName(),
                    e);
        }
    }

    @Override
    public void setUserAttribute(@NonNull String value, @NonNull String key) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.CORE,
                "[Luciq.setUserAttribute] phase=enter key=" + key + " valueLength=" + value.length());
        Luciq.setUserAttribute(key, value);
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.CORE, "[Luciq.setUserAttribute] phase=exit");
    }

    @Override
    public void removeUserAttribute(@NonNull String key) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.CORE,
                "[Luciq.removeUserAttribute] phase=enter key=" + key);
        Luciq.removeUserAttribute(key);
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.CORE, "[Luciq.removeUserAttribute] phase=exit");
    }


    @Override
    public void getUserAttributeForKey(@NonNull String key, LuciqPigeon.Result<String> result) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.CORE,
                "[Luciq.getUserAttributeForKey] phase=enter key=" + key);
        ThreadManager.runOnBackground(
                new Runnable() {
                    @Override
                    public void run() {
                        final String attribute = Luciq.getUserAttribute(key);

                        ThreadManager.runOnMainThread(new Runnable() {
                            @Override
                            public void run() {
                                LuciqFlutterLogger.d(LuciqFlutterDebugTags.CORE,
                                        "[Luciq.getUserAttributeForKey] phase=exit resultPresent=" + (attribute != null)
                                                + " resultLength=" + (attribute != null ? attribute.length() : 0));
                                result.success(attribute);
                            }
                        });
                    }
                }
        );
    }

    @Override
    public void getUserAttributes(LuciqPigeon.Result<Map<String, String>> result) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.CORE, "[Luciq.getUserAttributes] phase=enter");
        ThreadManager.runOnBackground(
                new Runnable() {
                    @Override
                    public void run() {
                        final Map<String, String> attributes = Luciq.getAllUserAttributes();

                        ThreadManager.runOnMainThread(new Runnable() {
                            @Override
                            public void run() {
                                LuciqFlutterLogger.d(LuciqFlutterDebugTags.CORE,
                                        "[Luciq.getUserAttributes] phase=exit resultPresent=" + (attributes != null)
                                                + " resultCount=" + (attributes != null ? attributes.size() : 0));
                                result.success(attributes);
                            }
                        });
                    }
                }
        );
    }

    @Override
    public void setReproStepsConfig(@Nullable String bugMode, @Nullable String crashMode, @Nullable String sessionReplayMode) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.CORE,
                "[Luciq.setReproStepsConfig] phase=enter bugMode=" + bugMode
                        + " crashMode=" + crashMode
                        + " sessionReplayMode=" + sessionReplayMode);
        try {
            final ReproConfigurations.Builder builder = new ReproConfigurations.Builder();

            if (bugMode != null) {
                final Integer resolvedBugMode = ArgsRegistry.reproModes.get(bugMode);
                builder.setIssueMode(IssueType.Bug, resolvedBugMode);
            }

            if (crashMode != null) {
                final Integer resolvedCrashMode = ArgsRegistry.reproModes.get(crashMode);
                builder.setIssueMode(IssueType.AllCrashes, resolvedCrashMode);
            }

            if (sessionReplayMode != null) {
                final Integer resolvedSessionReplayMode = ArgsRegistry.reproModes.get(sessionReplayMode);
                builder.setIssueMode(IssueType.SessionReplay, resolvedSessionReplayMode);
            }

            final ReproConfigurations config = builder.build();

            Luciq.setReproConfigurations(config);
            LuciqFlutterLogger.d(LuciqFlutterDebugTags.CORE, "[Luciq.setReproStepsConfig] phase=exit");
        } catch (Exception e) {
            LuciqFlutterLogger.e(LuciqFlutterDebugTags.CORE,
                    "[Luciq.setReproStepsConfig] phase=error errorType=" + e.getClass().getSimpleName(),
                    e);
        }
    }

    @Override
    public void reportScreenChange(@NonNull String screenName) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.SCREEN_TRACKING,
                "[Luciq.reportScreenChange] phase=enter screenNameLength=" + screenName.length());
        try {
            Method method = Reflection.getMethod(Class.forName("ai.luciq.library.Luciq"), "reportScreenChange",
                    Bitmap.class, String.class, Long.class);
            if (method != null) {
                method.invoke(null, null, screenName, null);
            }
            Method reportView = Reflection.getMethod(Class.forName("ai.luciq.library.Luciq"), "reportCurrentViewChange",
                    String.class);

            if (reportView != null) {
                reportView.invoke(null, screenName);
            }
            LuciqFlutterLogger.d(LuciqFlutterDebugTags.SCREEN_TRACKING,
                    "[Luciq.reportScreenChange] phase=exit");
        } catch (Exception e) {
            LuciqFlutterLogger.e(LuciqFlutterDebugTags.SCREEN_TRACKING,
                    "[Luciq.reportScreenChange] phase=error errorType=" + e.getClass().getSimpleName(),
                    e);
        }
    }

    @VisibleForTesting
    public Bitmap getBitmapForAsset(String assetName) {
        try {
            FlutterLoader loader = FlutterInjector.instance().flutterLoader();
            String key = loader.getLookupKeyForAsset(assetName);
            InputStream stream = context.getAssets().open(key);
            return BitmapFactory.decodeStream(stream);
        } catch (IOException exception) {
            return null;
        }
    }

    @Override
    public void setCustomBrandingImage(@NonNull String light, @NonNull String dark) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.CORE,
                "[Luciq.setCustomBrandingImage] phase=enter lightLength=" + light.length()
                        + " darkLength=" + dark.length());
        try {
            Bitmap lightLogoVariant = getBitmapForAsset(light);
            Bitmap darkLogoVariant = getBitmapForAsset(dark);

            if (lightLogoVariant == null) {
                lightLogoVariant = darkLogoVariant;
            }
            if (darkLogoVariant == null) {
                darkLogoVariant = lightLogoVariant;
            }
            if (lightLogoVariant == null) {
                throw new Exception("Couldn't find the light or dark logo images");
            }

            Method method = Reflection.getMethod(Class.forName("ai.luciq.library.Luciq"), "setCustomBrandingImage", Bitmap.class, Bitmap.class);

            if (method != null) {
                method.invoke(null, lightLogoVariant, darkLogoVariant);
            }
            LuciqFlutterLogger.d(LuciqFlutterDebugTags.CORE, "[Luciq.setCustomBrandingImage] phase=exit");
        } catch (Exception e) {
            LuciqFlutterLogger.e(LuciqFlutterDebugTags.CORE,
                    "[Luciq.setCustomBrandingImage] phase=error errorType=" + e.getClass().getSimpleName(),
                    e);
        }
    }

    @Override
    public void setFont(@NonNull String font) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.CORE,
                "[Luciq.setFont] phase=enter fontLength=" + font.length());
        // iOS Only
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.CORE, "[Luciq.setFont] phase=exit iosOnly=true");
    }

    @Override
    public void addFileAttachmentWithURL(@NonNull String filePath, @NonNull String fileName) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.CORE,
                "[Luciq.addFileAttachmentWithURL] phase=enter filePathLength=" + filePath.length()
                        + " fileNameLength=" + fileName.length());
        final File file = new File(filePath);
        if (file.exists()) {
            Luciq.addFileAttachment(Uri.fromFile(file), fileName);
            LuciqFlutterLogger.d(LuciqFlutterDebugTags.CORE,
                    "[Luciq.addFileAttachmentWithURL] phase=exit fileExists=true");
        } else {
            LuciqFlutterLogger.e(LuciqFlutterDebugTags.CORE,
                    "[Luciq.addFileAttachmentWithURL] phase=error errorType=InvalidArgument fileExists=false");
        }
    }

    @Override
    public void addFileAttachmentWithData(@NonNull byte[] data, @NonNull String fileName) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.CORE,
                "[Luciq.addFileAttachmentWithData] phase=enter dataLength=" + data.length
                        + " fileNameLength=" + fileName.length());
        Luciq.addFileAttachment(data, fileName);
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.CORE, "[Luciq.addFileAttachmentWithData] phase=exit");
    }

    @Override
    public void clearFileAttachments() {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.CORE, "[Luciq.clearFileAttachments] phase=enter");
        Luciq.clearFileAttachment();
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.CORE, "[Luciq.clearFileAttachments] phase=exit");
    }

    @Override
    public void networkLog(@NonNull Map<String, Object> data) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.NETWORK,
                "[Luciq.networkLog] phase=enter url=" + LuciqFlutterLogger.redactUrl((String) data.get("url"))
                        + " method=" + data.get("method")
                        + " responseCode=" + data.get("responseCode"));
        try {
            NetworkLog networkLog = new NetworkLog();
            String date = System.currentTimeMillis() + "";

            networkLog.setDate(date);
            networkLog.setUrl((String) data.get("url"));
            networkLog.setRequest((String) data.get("requestBody"));
            networkLog.setResponse((String) data.get("responseBody"));
            networkLog.setMethod((String) data.get("method"));
            networkLog.setResponseCode((Integer) data.get("responseCode"));
            networkLog.setRequestHeaders((new JSONObject((HashMap<String, String>) data.get("requestHeaders"))).toString(4));
            networkLog.setResponseHeaders((new JSONObject((HashMap<String, String>) data.get("responseHeaders"))).toString(4));
            networkLog.setTotalDuration(((Number) data.get("duration")).longValue() / 1000);

            networkLog.insert();
            LuciqFlutterLogger.d(LuciqFlutterDebugTags.NETWORK, "[Luciq.networkLog] phase=exit");
        } catch (Exception e) {
            LuciqFlutterLogger.e(LuciqFlutterDebugTags.NETWORK,
                    "[Luciq.networkLog] phase=error errorType=" + e.getClass().getSimpleName(),
                    e);
        }
    }

    @Override
    public void registerFeatureFlagChangeListener() {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.FEATURE_FLAGS,
                "[Luciq.registerFeatureFlagChangeListener] phase=enter");
        try {
            InternalCore.INSTANCE._setFeaturesStateListener(new FeaturesStateListener() {
                @Override
                public void invoke(@NonNull CoreFeaturesState featuresState) {
                    ThreadManager.runOnMainThread(new Runnable() {
                        @Override
                        public void run() {
                            featureFlagsFlutterApi.onW3CFeatureFlagChange(featuresState.isW3CExternalTraceIdEnabled(),
                                    featuresState.isAttachingGeneratedHeaderEnabled(),
                                    featuresState.isAttachingCapturedHeaderEnabled(),
                                    new LuciqPigeon.FeatureFlagsFlutterApi.Reply<Void>() {
                                        @Override
                                        public void reply(Void reply) {

                                        }
                                    });

                            featureFlagsFlutterApi.onNetworkLogBodyMaxSizeChange(
                                    (long) featuresState.getNetworkLogCharLimit(),
                                    reply -> {}
                            );
                        }
                    });
                }

            });
            LuciqFlutterLogger.d(LuciqFlutterDebugTags.FEATURE_FLAGS,
                    "[Luciq.registerFeatureFlagChangeListener] phase=exit");
        } catch (Exception e) {
            LuciqFlutterLogger.e(LuciqFlutterDebugTags.FEATURE_FLAGS,
                    "[Luciq.registerFeatureFlagChangeListener] phase=error errorType=" + e.getClass().getSimpleName(),
                    e);
        }

    }

    @NonNull
    @Override
    public Map<String, Boolean> isW3CFeatureFlagsEnabled() {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.FEATURE_FLAGS, "[Luciq.isW3CFeatureFlagsEnabled] phase=enter");
        Map<String, Boolean> params = new HashMap<String, Boolean>();
        params.put("isW3cExternalTraceIDEnabled", InternalCore.INSTANCE._isFeatureEnabled(CoreFeature.W3C_EXTERNAL_TRACE_ID));
        params.put("isW3cExternalGeneratedHeaderEnabled", InternalCore.INSTANCE._isFeatureEnabled(CoreFeature.W3C_ATTACHING_GENERATED_HEADER));
        params.put("isW3cCaughtHeaderEnabled", InternalCore.INSTANCE._isFeatureEnabled(CoreFeature.W3C_ATTACHING_CAPTURED_HEADER));

        LuciqFlutterLogger.d(LuciqFlutterDebugTags.FEATURE_FLAGS,
                "[Luciq.isW3CFeatureFlagsEnabled] phase=exit resultCount=" + params.size());
        return params;
    }

    @Override
    public void willRedirectToStore() {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.CORE, "[Luciq.willRedirectToStore] phase=enter");
        Luciq.willRedirectToStore();
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.CORE, "[Luciq.willRedirectToStore] phase=exit");
    }

    public static void setScreenshotCaptor(ScreenshotCaptor screenshotCaptor, InternalCore internalCore) {
        internalCore._setScreenshotCaptor(new ai.luciq.library.screenshot.ScreenshotCaptor() {
            @Override
            public void capture(@NonNull ScreenshotRequest screenshotRequest) {
                screenshotCaptor.capture(new ScreenshotCaptor.CapturingCallback() {
                    @Override
                    public void onCapturingFailure(Throwable throwable) {
                        screenshotRequest.getListener().onCapturingFailure(throwable);
                    }

                    @Override
                    public void onCapturingSuccess(Bitmap bitmap) {
                        screenshotRequest.getListener().onCapturingSuccess(bitmap);
                    }
                });
            }
        });
    }

    @Override
    public void setNetworkLogBodyEnabled(@NonNull Boolean isEnabled) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.NETWORK,
                "[Luciq.setNetworkLogBodyEnabled] phase=enter isEnabled=" + isEnabled);
        try {
            Luciq.setNetworkLogBodyEnabled(isEnabled);
            LuciqFlutterLogger.d(LuciqFlutterDebugTags.NETWORK, "[Luciq.setNetworkLogBodyEnabled] phase=exit");
        } catch (Exception e) {
            LuciqFlutterLogger.e(LuciqFlutterDebugTags.NETWORK,
                    "[Luciq.setNetworkLogBodyEnabled] phase=error errorType=" + e.getClass().getSimpleName(),
                    e);
        }
    }

    @Override
    public void setTheme(@NonNull Map<String, Object> themeConfig) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.CORE,
                "[Luciq.setTheme] phase=enter keyCount=" + themeConfig.size());
        try {
            ai.luciq.library.model.LuciqTheme.Builder builder = new ai.luciq.library.model.LuciqTheme.Builder();

            if (themeConfig.containsKey("primaryColor")) {
                builder.setPrimaryColor(getColor(themeConfig, "primaryColor"));
            }
            if (themeConfig.containsKey("secondaryTextColor")) {
                builder.setSecondaryTextColor(getColor(themeConfig, "secondaryTextColor"));
            }
            if (themeConfig.containsKey("primaryTextColor")) {
                builder.setPrimaryTextColor(getColor(themeConfig, "primaryTextColor"));
            }
            if (themeConfig.containsKey("titleTextColor")) {
                builder.setTitleTextColor(getColor(themeConfig, "titleTextColor"));
            }
            if (themeConfig.containsKey("backgroundColor")) {
                builder.setBackgroundColor(getColor(themeConfig, "backgroundColor"));
            }

            if (themeConfig.containsKey("primaryTextStyle")) {
                builder.setPrimaryTextStyle(getTextStyle(themeConfig, "primaryTextStyle"));
            }
            if (themeConfig.containsKey("secondaryTextStyle")) {
                builder.setSecondaryTextStyle(getTextStyle(themeConfig, "secondaryTextStyle"));
            }
            if (themeConfig.containsKey("ctaTextStyle")) {
                builder.setCtaTextStyle(getTextStyle(themeConfig, "ctaTextStyle"));
            }

            setFontIfPresent(themeConfig, builder, "primaryFontPath", "primaryFontAsset", "primary");
            setFontIfPresent(themeConfig, builder, "secondaryFontPath", "secondaryFontAsset", "secondary");
            setFontIfPresent(themeConfig, builder, "ctaFontPath", "ctaFontAsset", "CTA");

            ai.luciq.library.model.LuciqTheme theme = builder.build();
            Luciq.setTheme(theme);
            LuciqFlutterLogger.d(LuciqFlutterDebugTags.CORE, "[Luciq.setTheme] phase=exit");

        } catch (Exception e) {
            LuciqFlutterLogger.e(LuciqFlutterDebugTags.CORE,
                    "[Luciq.setTheme] phase=error errorType=" + e.getClass().getSimpleName(),
                    e);
        }
    }



    /**
     * Retrieves a color value from the Map.
     *
     * @param map The Map object.
     * @param key The key to look for.
     * @return The parsed color as an integer, or black if missing or invalid.
     */
    private int getColor(Map<String, Object> map, String key) {
        try {
            if (map != null && map.containsKey(key) && map.get(key) != null) {
                String colorString = (String) map.get(key);
                return android.graphics.Color.parseColor(colorString);
            }
        } catch (Exception e) {
            LuciqFlutterLogger.w(LuciqFlutterDebugTags.CORE,
                    "[Luciq.setTheme.color] phase=warn errorType=" + e.getClass().getSimpleName() + " key=" + key);
        }
        return android.graphics.Color.BLACK;
    }

    /**
     * Retrieves a text style from the Map.
     *
     * @param map The Map object.
     * @param key The key to look for.
     * @return The corresponding Typeface style, or Typeface.NORMAL if missing or invalid.
     */
    private int getTextStyle(Map<String, Object> map, String key) {
        try {
            if (map != null && map.containsKey(key) && map.get(key) != null) {
                String style = (String) map.get(key);
                switch (style.toLowerCase()) {
                    case "bold":
                        return Typeface.BOLD;
                    case "italic":
                        return Typeface.ITALIC;
                    case "bold_italic":
                        return Typeface.BOLD_ITALIC;
                    case "normal":
                    default:
                        return Typeface.NORMAL;
                }
            }
        } catch (Exception e) {
            LuciqFlutterLogger.w(LuciqFlutterDebugTags.CORE,
                    "[Luciq.setTheme.textStyle] phase=warn errorType=" + e.getClass().getSimpleName() + " key=" + key);
        }
        return Typeface.NORMAL;
    }

    /**
     * Sets a font on the theme builder if the font configuration is present in the theme config.
     *
     * @param themeConfig The theme configuration map
     * @param builder The theme builder
     * @param fileKey The key for font file path
     * @param assetKey The key for font asset path
     * @param fontType The type of font (for logging purposes)
     */
    private void setFontIfPresent(Map<String, Object> themeConfig, ai.luciq.library.model.LuciqTheme.Builder builder,
                                 String fileKey, String assetKey, String fontType) {
        if (themeConfig.containsKey(fileKey) || themeConfig.containsKey(assetKey)) {
            Typeface typeface = getTypeface(themeConfig, fileKey, assetKey);
            if (typeface != null) {
                switch (fontType) {
                    case "primary":
                        builder.setPrimaryTextFont(typeface);
                        break;
                    case "secondary":
                        builder.setSecondaryTextFont(typeface);
                        break;
                    case "CTA":
                        builder.setCtaTextFont(typeface);
                        break;
                }
            }
        }
    }

    private Typeface getTypeface(Map<String, Object> map, String fileKey, String assetKey) {
        String fontName = null;

        if (assetKey != null && map.containsKey(assetKey) && map.get(assetKey) != null) {
            fontName = (String) map.get(assetKey);
        } else if (fileKey != null && map.containsKey(fileKey) && map.get(fileKey) != null) {
            fontName = (String) map.get(fileKey);
        }

        if (fontName == null) {
            return Typeface.DEFAULT;
        }

        try {
            String assetPath = "fonts/" + fontName;
            return Typeface.createFromAsset(context.getAssets(), assetPath);
        } catch (Exception e) {
            try {
                return Typeface.create(fontName, Typeface.NORMAL);
            } catch (Exception e2) {
                LuciqFlutterLogger.w(LuciqFlutterDebugTags.CORE,
                        "[Luciq.setTheme.typeface] phase=warn errorType=" + e2.getClass().getSimpleName());
                return Typeface.DEFAULT;
            }
        }
    }
    /**
     * Enables or disables displaying in full-screen mode, hiding the status and navigation bars.
     * @param isEnabled A boolean to enable/disable setFullscreen.
     */
    @Override
    public void setFullscreen(@NonNull final Boolean isEnabled) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.CORE,
                "[Luciq.setFullscreen] phase=enter isEnabled=" + isEnabled);
        try {
            Luciq.setFullscreen(isEnabled);
            LuciqFlutterLogger.d(LuciqFlutterDebugTags.CORE, "[Luciq.setFullscreen] phase=exit");
        } catch (Exception e) {
            LuciqFlutterLogger.e(LuciqFlutterDebugTags.CORE,
                    "[Luciq.setFullscreen] phase=error errorType=" + e.getClass().getSimpleName(),
                    e);
        }
    }

    @Override
    public void getNetworkBodyMaxSize(@NonNull LuciqPigeon.Result<Double> result) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.NETWORK, "[Luciq.getNetworkBodyMaxSize] phase=enter");
        ThreadManager.runOnMainThread(
            new Runnable() {
                @Override
                public void run() {
                    try {
                        double networkCharLimit = InternalCore.INSTANCE.get_networkLogCharLimit();
                        LuciqFlutterLogger.d(LuciqFlutterDebugTags.NETWORK,
                                "[Luciq.getNetworkBodyMaxSize] phase=exit result=" + networkCharLimit);
                        result.success(networkCharLimit);
                    } catch (Exception e) {
                        LuciqFlutterLogger.e(LuciqFlutterDebugTags.NETWORK,
                                "[Luciq.getNetworkBodyMaxSize] phase=error errorType=" + e.getClass().getSimpleName(),
                                e);
                    }
                }
            }
        );
    }
    @Override
    public void setNetworkAutoMaskingEnabled(@NonNull Boolean isEnabled) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.NETWORK,
                "[Luciq.setNetworkAutoMaskingEnabled] phase=enter isEnabled=" + isEnabled);
        try {
            if (isEnabled)
                Luciq.setNetworkAutoMaskingState(Feature.State.ENABLED);
            else
                Luciq.setNetworkAutoMaskingState(Feature.State.DISABLED);
            LuciqFlutterLogger.d(LuciqFlutterDebugTags.NETWORK, "[Luciq.setNetworkAutoMaskingEnabled] phase=exit");
        } catch (Exception e) {
            LuciqFlutterLogger.e(LuciqFlutterDebugTags.NETWORK,
                    "[Luciq.setNetworkAutoMaskingEnabled] phase=error errorType=" + e.getClass().getSimpleName(),
                    e);
        }
    }

    @Override
    public void setWebViewMonitoringEnabled(@NonNull Boolean isEnabled) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.CORE,
                "[Luciq.setWebViewMonitoringEnabled] phase=enter isEnabled=" + isEnabled);
        try {
            Luciq.setWebViewMonitoringEnabled(isEnabled);
            LuciqFlutterLogger.d(LuciqFlutterDebugTags.CORE, "[Luciq.setWebViewMonitoringEnabled] phase=exit");
        } catch (Exception e) {
            LuciqFlutterLogger.e(LuciqFlutterDebugTags.CORE,
                    "[Luciq.setWebViewMonitoringEnabled] phase=error errorType=" + e.getClass().getSimpleName(),
                    e);
        }
    }

    @Override
    public void setWebViewUserInteractionsTrackingEnabled(@NonNull Boolean isEnabled) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.CORE,
                "[Luciq.setWebViewUserInteractionsTrackingEnabled] phase=enter isEnabled=" + isEnabled);
        try {
            Luciq.setWebViewUserInteractionsTrackingEnabled(isEnabled);
            LuciqFlutterLogger.d(LuciqFlutterDebugTags.CORE,
                    "[Luciq.setWebViewUserInteractionsTrackingEnabled] phase=exit");
        } catch (Exception e) {
            LuciqFlutterLogger.e(LuciqFlutterDebugTags.CORE,
                    "[Luciq.setWebViewUserInteractionsTrackingEnabled] phase=error errorType=" + e.getClass().getSimpleName(),
                    e);
        }
    }

    @Override
    public void setWebViewNetworkTrackingEnabled(@NonNull Boolean isEnabled) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.CORE,
                "[Luciq.setWebViewNetworkTrackingEnabled] phase=enter isEnabled=" + isEnabled);
        try {
            Luciq.setWebViewNetworkTrackingEnabled(isEnabled);
            LuciqFlutterLogger.d(LuciqFlutterDebugTags.CORE,
                    "[Luciq.setWebViewNetworkTrackingEnabled] phase=exit");
        } catch (Exception e) {
            LuciqFlutterLogger.e(LuciqFlutterDebugTags.CORE,
                    "[Luciq.setWebViewNetworkTrackingEnabled] phase=error errorType=" + e.getClass().getSimpleName(),
                    e);
        }
    }
}
