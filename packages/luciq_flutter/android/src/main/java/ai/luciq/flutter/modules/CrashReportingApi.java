package ai.luciq.flutter.modules;

import static ai.luciq.crash.CrashReporting.getFingerprintObject;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import ai.luciq.crash.CrashReporting;
import ai.luciq.crash.models.LuciqNonFatalException;
import ai.luciq.flutter.generated.CrashReportingPigeon;
import ai.luciq.flutter.util.ArgsRegistry;
import ai.luciq.flutter.util.LuciqFlutterDebugTags;
import ai.luciq.flutter.util.LuciqFlutterLogger;
import ai.luciq.flutter.util.Reflection;
import ai.luciq.library.Feature;

import org.json.JSONObject;

import java.lang.reflect.Method;
import java.util.Map;

import io.flutter.plugin.common.BinaryMessenger;

public class CrashReportingApi implements CrashReportingPigeon.CrashReportingHostApi {
    private final String TAG = CrashReportingApi.class.getName();

    public static void init(BinaryMessenger messenger) {
        final CrashReportingApi api = new CrashReportingApi();
        CrashReportingPigeon.CrashReportingHostApi.setup(messenger, api);
    }

    @Override
    public void setEnabled(@NonNull Boolean isEnabled) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.CRASH_REPORTING,
                "[CR.setEnabled] phase=enter isEnabled=" + isEnabled);
        if (isEnabled) {
            CrashReporting.setState(Feature.State.ENABLED);
        } else {
            CrashReporting.setState(Feature.State.DISABLED);
        }
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.CRASH_REPORTING,
                "[CR.setEnabled] phase=exit");
    }

    @Override
    public void send(@NonNull String jsonCrash, @NonNull Boolean isHandled) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.CRASH_REPORTING,
                "[CR.send] phase=enter jsonCrashLength=" + jsonCrash.length()
                        + " isHandled=" + isHandled);
        try {
            final JSONObject exceptionObject = new JSONObject(jsonCrash);
            Method method = Reflection.getMethod(Class.forName("ai.luciq.crash.CrashReporting"), "reportException",
                    JSONObject.class, boolean.class);
            if (method == null) {
                LuciqFlutterLogger.e(LuciqFlutterDebugTags.CRASH_REPORTING,
                        "[CR.send] phase=error errorType=ReflectionMissing method=reportException");
                return;
            }
            method.invoke(null, exceptionObject, isHandled);
            LuciqFlutterLogger.d(LuciqFlutterDebugTags.CRASH_REPORTING,
                    "[CR.send] phase=exit");
        } catch (Exception e) {
            LuciqFlutterLogger.e(LuciqFlutterDebugTags.CRASH_REPORTING,
                    "[CR.send] phase=error errorType=" + e.getClass().getSimpleName(), e);
        }
    }

    @Override
    public void sendNonFatalError(@NonNull String jsonCrash, @Nullable Map<String, String> userAttributes, @Nullable String fingerprint, @NonNull String nonFatalExceptionLevel) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.CRASH_REPORTING,
                "[CR.sendNonFatalError] phase=enter jsonCrashLength=" + jsonCrash.length()
                        + " userAttributesPresent=" + (userAttributes != null)
                        + " fingerprintPresent=" + (fingerprint != null)
                        + " nonFatalExceptionLevel=" + nonFatalExceptionLevel);
        try {
            Method method = Reflection.getMethod(Class.forName("ai.luciq.crash.CrashReporting"), "reportException", JSONObject.class, boolean.class,
                    Map.class, JSONObject.class, LuciqNonFatalException.Level.class);
            final JSONObject exceptionObject = new JSONObject(jsonCrash);

            JSONObject fingerprintObj = null;
            if (fingerprint != null) {
                fingerprintObj = getFingerprintObject(fingerprint);
            }
            LuciqNonFatalException.Level nonFatalExceptionLevelType = ArgsRegistry.nonFatalExceptionLevel.get(nonFatalExceptionLevel);
            if (nonFatalExceptionLevelType == null) {
                LuciqFlutterLogger.e(LuciqFlutterDebugTags.CRASH_REPORTING,
                        "[CR.sendNonFatalError] phase=error errorType=UnknownEnum nonFatalExceptionLevel="
                                + nonFatalExceptionLevel);
            }
            if (method == null) {
                LuciqFlutterLogger.e(LuciqFlutterDebugTags.CRASH_REPORTING,
                        "[CR.sendNonFatalError] phase=error errorType=ReflectionMissing method=reportException");
                return;
            }
            method.invoke(null, exceptionObject, true, userAttributes, fingerprintObj, nonFatalExceptionLevelType);
            LuciqFlutterLogger.d(LuciqFlutterDebugTags.CRASH_REPORTING,
                    "[CR.sendNonFatalError] phase=exit");
        } catch (Exception e) {
            LuciqFlutterLogger.e(LuciqFlutterDebugTags.CRASH_REPORTING,
                    "[CR.sendNonFatalError] phase=error errorType=" + e.getClass().getSimpleName(), e);
        }
    }

    @Override
    public void setNDKEnabled(@NonNull Boolean isEnabled) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.CRASH_REPORTING,
                "[CR.setNDKEnabled] phase=enter isEnabled=" + isEnabled);
        if (isEnabled) {
            CrashReporting.setNDKCrashesState(Feature.State.ENABLED);
        } else {
            CrashReporting.setNDKCrashesState(Feature.State.DISABLED);
        }
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.CRASH_REPORTING,
                "[CR.setNDKEnabled] phase=exit");
    }

}
