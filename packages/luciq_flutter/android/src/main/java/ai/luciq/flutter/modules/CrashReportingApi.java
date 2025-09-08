package ai.luciq.flutter.modules;

import static ai.luciq.crash.CrashReporting.getFingerprintObject;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import ai.luciq.crash.CrashReporting;
import ai.luciq.crash.models.LuciqNonFatalException;
import ai.luciq.flutter.generated.CrashReportingPigeon;
import ai.luciq.flutter.util.ArgsRegistry;
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
        if (isEnabled) {
            CrashReporting.setState(Feature.State.ENABLED);
        } else {
            CrashReporting.setState(Feature.State.DISABLED);
        }
    }

    @Override
    public void send(@NonNull String jsonCrash, @NonNull Boolean isHandled) {
        try {
            final JSONObject exceptionObject = new JSONObject(jsonCrash);
            Method method = Reflection.getMethod(Class.forName("ai.luciq.crash.CrashReporting"), "reportException",
                    JSONObject.class, boolean.class);
            if (method != null) {
                method.invoke(null, exceptionObject, isHandled);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    @Override
    public void sendNonFatalError(@NonNull String jsonCrash, @Nullable Map<String, String> userAttributes, @Nullable String fingerprint, @NonNull String nonFatalExceptionLevel) {
        try {
            Method method = Reflection.getMethod(Class.forName("ai.luciq.crash.CrashReporting"), "reportException", JSONObject.class, boolean.class,
                    Map.class, JSONObject.class, LuciqNonFatalException.Level.class);
            final JSONObject exceptionObject = new JSONObject(jsonCrash);

            JSONObject fingerprintObj = null;
            if (fingerprint != null) {
                fingerprintObj = getFingerprintObject(fingerprint);
            }
            LuciqNonFatalException.Level nonFatalExceptionLevelType = ArgsRegistry.nonFatalExceptionLevel.get(nonFatalExceptionLevel);
            if (method != null) {
                method.invoke(null, exceptionObject, true, userAttributes, fingerprintObj, nonFatalExceptionLevelType);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

}
