package ai.luciq.flutter.modules;

import android.annotation.SuppressLint;

import androidx.annotation.NonNull;

import ai.luciq.featuresrequest.FeatureRequests;
import ai.luciq.flutter.generated.FeatureRequestsPigeon;
import ai.luciq.flutter.util.ArgsRegistry;
import ai.luciq.flutter.util.LuciqFlutterDebugTags;
import ai.luciq.flutter.util.LuciqFlutterLogger;

import java.util.List;

import io.flutter.plugin.common.BinaryMessenger;

public class FeatureRequestsApi implements FeatureRequestsPigeon.FeatureRequestsHostApi {

    public static void init(BinaryMessenger messenger) {
        final FeatureRequestsApi api = new FeatureRequestsApi();
        FeatureRequestsPigeon.FeatureRequestsHostApi.setup(messenger, api);
    }

    @Override
    public void show() {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.FEATURE_REQUESTS,
                "[FR.show] phase=enter");
        FeatureRequests.show();
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.FEATURE_REQUESTS,
                "[FR.show] phase=exit");
    }

    @SuppressLint("WrongConstant")
    @Override
    public void setEmailFieldRequired(@NonNull Boolean isRequired, @NonNull List<String> actionTypes) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.FEATURE_REQUESTS,
                "[FR.setEmailFieldRequired] phase=enter isRequired=" + isRequired
                        + " actionTypesCount=" + actionTypes.size());
        int[] actions = new int[actionTypes.size()];
        for (int i = 0; i < actionTypes.size(); i++) {
            Integer mapped = ArgsRegistry.actionTypes.get(actionTypes.get(i));
            if (mapped == null) {
                LuciqFlutterLogger.w(LuciqFlutterDebugTags.FEATURE_REQUESTS,
                        "[FR.setEmailFieldRequired] phase=warn errorType=UnknownEnum actionType="
                                + actionTypes.get(i));
                continue;
            }
            actions[i] = mapped;
        }

        FeatureRequests.setEmailFieldRequired(isRequired, actions);
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.FEATURE_REQUESTS,
                "[FR.setEmailFieldRequired] phase=exit");
    }
}
