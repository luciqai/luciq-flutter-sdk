package ai.luciq.flutter.modules;

import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import org.json.JSONObject;

import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.Callable;

import ai.luciq.apm.APM;
import ai.luciq.apm.InternalAPM;
import ai.luciq.apm.configuration.cp.APMFeature;
import ai.luciq.apm.configuration.cp.FeatureAvailabilityCallback;
import ai.luciq.apm.configuration.cp.ToleranceValueCallback;
import ai.luciq.apm.networking.APMNetworkLogger;
import ai.luciq.apm.networkinterception.cp.APMCPNetworkLog;
import ai.luciq.apm.screenrendering.models.cp.LuciqFrameData;
import ai.luciq.apm.screenrendering.models.cp.LuciqScreenRenderingData;
import ai.luciq.flutter.generated.ApmPigeon;
import ai.luciq.flutter.util.Reflection;
import ai.luciq.flutter.util.RunCatching;
import io.flutter.plugin.common.BinaryMessenger;

public class ApmApi implements ApmPigeon.ApmHostApi {
    private final String TAG = ApmApi.class.getName();
    private final Callable<Float> refreshRateCallback;

    public ApmApi(Callable<Float> refreshRate) {
        this.refreshRateCallback = refreshRate;
    }

    public static void init(BinaryMessenger messenger, Callable<Float> refreshRateProvider) {

        final ApmApi api = new ApmApi(refreshRateProvider);
        ApmPigeon.ApmHostApi.setup(messenger, api);
    }

    @Override
    public void setEnabled(@NonNull Boolean isEnabled) {
        RunCatching.runCatching("ApmApi.setEnabled", () -> APM.setEnabled(isEnabled));
    }

    @Override
    public void setColdAppLaunchEnabled(@NonNull Boolean isEnabled) {
        RunCatching.runCatching("ApmApi.setColdAppLaunchEnabled",
                () -> APM.setColdAppLaunchEnabled(isEnabled));
    }

    @Override
    public void setAutoUITraceEnabled(@NonNull Boolean isEnabled) {
        RunCatching.runCatching("ApmApi.setAutoUITraceEnabled",
                () -> APM.setAutoUITraceEnabled(isEnabled));
    }

    @Override
    public void startFlow(@NonNull String name) {
        RunCatching.runCatching("ApmApi.startFlow", () -> APM.startFlow(name));
    }

    @Override
    public void setFlowAttribute(@NonNull String name, @NonNull String key, @Nullable String value) {
        RunCatching.runCatching("ApmApi.setFlowAttribute",
                () -> APM.setFlowAttribute(name, key, value));
    }

    @Override
    public void endFlow(@NonNull String name) {
        RunCatching.runCatching("ApmApi.endFlow", () -> APM.endFlow(name));
    }

    @Override
    public void startUITrace(@NonNull String name) {
        RunCatching.runCatching("ApmApi.startUITrace", () -> APM.startUITrace(name));
    }

    @Override
    public void endUITrace() {
        RunCatching.runCatching("ApmApi.endUITrace", APM::endUITrace);
    }

    @Override
    public void endAppLaunch() {
        RunCatching.runCatching("ApmApi.endAppLaunch", APM::endAppLaunch);
    }

    @Override
    public void networkLogAndroid(@NonNull Map<String, Object> data) {
        RunCatching.runCatching("ApmApi.networkLogAndroid", () -> {
            APMNetworkLogger apmNetworkLogger = new APMNetworkLogger();
            final String requestUrl = (String) data.get("url");
            final String requestBody = (String) data.get("requestBody");
            final String responseBody = (String) data.get("responseBody");
            final String requestMethod = (String) data.get("method");
            //--------------------------------------------
            final String requestContentType = (String) data.get("requestContentType");
            final String responseContentType = (String) data.get("responseContentType");
            //--------------------------------------------
            final long requestBodySize = ((Number) data.get("requestBodySize")).longValue();
            final long responseBodySize = ((Number) data.get("responseBodySize")).longValue();
            //--------------------------------------------
            final String errorDomain = (String) data.get("errorDomain");
            final Integer statusCode = (Integer) data.get("responseCode");
            final long requestDuration = ((Number) data.get("duration")).longValue() / 1000;
            final long requestStartTime = ((Number) data.get("startTime")).longValue() * 1000;
            final String requestHeaders = (new JSONObject((HashMap<String, String>) data.get("requestHeaders"))).toString(4);
            final String responseHeaders = (new JSONObject((HashMap<String, String>) data.get("responseHeaders"))).toString(4);
            final String errorMessage;

            if (errorDomain.equals("")) {
                errorMessage = null;
            } else {
                errorMessage = errorDomain;
            }
            //--------------------------------------------------
            String gqlQueryName = null;
            if (data.containsKey("gqlQueryName")) {
                gqlQueryName = (String) data.get("gqlQueryName");
            }
            String serverErrorMessage = "";
            if (data.containsKey("serverErrorMessage")) {
                serverErrorMessage = (String) data.get("serverErrorMessage");
            }
            Boolean isW3cHeaderFound = null;
            Number partialId = null;
            Number networkStartTimeInSeconds = null;
            String w3CGeneratedHeader = null;
            String w3CCaughtHeader = null;

            if (data.containsKey("isW3cHeaderFound")) {
                isW3cHeaderFound = (Boolean) data.get("isW3cHeaderFound");
            }

            if (data.containsKey("partialId")) {
                partialId = ((Number) data.get("partialId"));
            }
            if (data.containsKey("networkStartTimeInSeconds")) {
                networkStartTimeInSeconds = ((Number) data.get("networkStartTimeInSeconds"));
            }

            if (data.containsKey("w3CGeneratedHeader")) {
                w3CGeneratedHeader = (String) data.get("w3CGeneratedHeader");
            }
            if (data.containsKey("w3CCaughtHeader")) {
                w3CCaughtHeader = (String) data.get("w3CCaughtHeader");
            }

            APMCPNetworkLog.W3CExternalTraceAttributes w3cExternalTraceAttributes = null;
            if (isW3cHeaderFound != null) {
                w3cExternalTraceAttributes = new APMCPNetworkLog.W3CExternalTraceAttributes(isW3cHeaderFound, partialId == null ? null : partialId.longValue(), networkStartTimeInSeconds == null ? null : networkStartTimeInSeconds.longValue(), w3CGeneratedHeader, w3CCaughtHeader);
            }

            Method method = Reflection.getMethod(Class.forName("ai.luciq.apm.networking.APMNetworkLogger"), "log", long.class, long.class, String.class, String.class, long.class, String.class, String.class, String.class, String.class, String.class, long.class, int.class, String.class, String.class, String.class, String.class, APMCPNetworkLog.W3CExternalTraceAttributes.class);
            if (method != null) {
                method.invoke(apmNetworkLogger, requestStartTime, requestDuration, requestHeaders, requestBody, requestBodySize, requestMethod, requestUrl, requestContentType, responseHeaders, responseBody, responseBodySize, statusCode, responseContentType, errorMessage, gqlQueryName, serverErrorMessage, w3cExternalTraceAttributes);
            } else {
                Log.e(TAG, "APMNetworkLogger.log was not found by reflection");
            }
        });
    }

    @Override
    public void startCpUiTrace(@NonNull String screenName, @NonNull Long microTimeStamp, @NonNull Long traceId) {
        RunCatching.runCatching("ApmApi.startCpUiTrace",
                () -> InternalAPM._startUiTraceCP(screenName, microTimeStamp, traceId));
    }

    @Override
    public void reportScreenLoadingCP(@NonNull Long startTimeStampMicro, @NonNull Long durationMicro, @NonNull Long uiTraceId) {
        RunCatching.runCatching("ApmApi.reportScreenLoadingCP",
                () -> InternalAPM._reportScreenLoadingCP(startTimeStampMicro, durationMicro, uiTraceId));
    }

    @Override
    public void endScreenLoadingCP(@NonNull Long timeStampMicro, @NonNull Long uiTraceId) {
        RunCatching.runCatching("ApmApi.endScreenLoadingCP",
                () -> InternalAPM._endScreenLoadingCP(timeStampMicro, uiTraceId));
    }

    @Override
    public void isEndScreenLoadingEnabled(@NonNull ApmPigeon.Result<Boolean> result) {
        isScreenLoadingEnabled(result);
    }

    @Override
    public void isAutoUiTraceEnabled(@NonNull ApmPigeon.Result<Boolean> result) {
        RunCatching.runCatching("ApmApi.isAutoUiTraceEnabled", () -> {
            InternalAPM._isFeatureEnabledCP(APMFeature.UI_TRACE, "LuciqCaptureScreenLoading", new FeatureAvailabilityCallback() {
                @Override
                public void invoke(boolean isFeatureAvailable) {
                    result.success(isFeatureAvailable);
                }
            });
        });
    }

    @Override
    public void isEnabled(@NonNull ApmPigeon.Result<Boolean> result) {
        RunCatching.runCatching("ApmApi.isEnabled", () -> {
            InternalAPM._isFeatureEnabledCP(APMFeature.APM, "APM", new FeatureAvailabilityCallback() {
                @Override
                public void invoke(boolean isEnabled) {
                    result.success(isEnabled);
                }
            });
        });
    }

    @Override
    public void isScreenLoadingEnabled(@NonNull ApmPigeon.Result<Boolean> result) {
        RunCatching.runCatching("ApmApi.isScreenLoadingEnabled", () -> {
            InternalAPM._isFeatureEnabledCP(APMFeature.SCREEN_LOADING, "LuciqCaptureScreenLoading", new FeatureAvailabilityCallback() {
                @Override
                public void invoke(boolean isFeatureAvailable) {
                    result.success(isFeatureAvailable);
                }
            });
        });
    }

    @Override
    public void setScreenLoadingEnabled(@NonNull Boolean isEnabled) {
        RunCatching.runCatching("ApmApi.setScreenLoadingEnabled",
                () -> APM.setScreenLoadingEnabled(isEnabled));
    }

    @Override
    public void setScreenRenderEnabled(@NonNull Boolean isEnabled) {
        RunCatching.runCatching("ApmApi.setScreenRenderEnabled",
                () -> APM.setScreenRenderingEnabled(isEnabled));
    }

    @Override
    public void isScreenRenderEnabled(@NonNull ApmPigeon.Result<Boolean> result) {
        RunCatching.runCatching("ApmApi.isScreenRenderEnabled", () -> {
            InternalAPM._isFeatureEnabledCP(APMFeature.SCREEN_RENDERING, "LuciqCaptureScreenRender", new FeatureAvailabilityCallback() {
                @Override
                public void invoke(boolean isEnabled) {
                    result.success(isEnabled);
                }
            });
        });
    }

    @Override
    public void isCustomSpanEnabled(@NonNull ApmPigeon.Result<Boolean> result) {
        RunCatching.runCatching("ApmApi.isCustomSpanEnabled", () -> {
            InternalAPM._isFeatureEnabledCP(APMFeature.CUSTOM_SPANS, "LuciqCustomSpan", new FeatureAvailabilityCallback() {
                @Override
                public void invoke(boolean isEnabled) {
                    result.success(isEnabled);
                }
            });
        });
    }

    @Override
    public void getDeviceRefreshRateAndTolerance(@NonNull ApmPigeon.Result<List<Double>> result) {
        RunCatching.runCatching("ApmApi.getDeviceRefreshRateAndTolerance", () -> {
            final double refreshRate = refreshRateCallback.call().doubleValue();
            InternalAPM._getToleranceValueForScreenRenderingCP(new ToleranceValueCallback() {
                @Override
                public void invoke(long tolerance) {
                    result.success(java.util.Arrays.asList(refreshRate, (double) tolerance));
                }
            });
        });
    }

    @Override
    public void endScreenRenderForAutoUiTrace(@NonNull Map<String, Object> data) {
        RunCatching.runCatching("ApmApi.endScreenRenderForAutoUiTrace", () -> {
            final long traceId = ((Number) data.get("traceId")).longValue();
            final long slowFramesTotalDuration = ((Number) data.get("slowFramesTotalDuration")).longValue();
            final long frozenFramesTotalDuration = ((Number) data.get("frozenFramesTotalDuration")).longValue();
            final long endTime = ((Number) data.get("endTime")).longValue();

            // Don't cast directly to ArrayList<ArrayList<Long>> because the inner lists may actually be ArrayList<Integer>
            // Instead, cast to List<List<Number>> and convert each value to long explicitly
            List<List<Number>> rawFrames = (List<List<Number>>) data.get("frameData");
            ArrayList<LuciqFrameData> frames = new ArrayList<>();
            if (rawFrames != null) {
                for (List<Number> frameValues : rawFrames) {
                    // Defensive: check size and nulls
                    if (frameValues != null && frameValues.size() >= 2) {
                        long frameStart = frameValues.get(0).longValue();
                        long frameDuration = frameValues.get(1).longValue();
                        frames.add(new LuciqFrameData(frameStart, frameDuration));
                    }
                }
            }
            LuciqScreenRenderingData screenRenderingData = new LuciqScreenRenderingData(traceId, slowFramesTotalDuration, frozenFramesTotalDuration, frames);
            InternalAPM._endAutoUiTraceWithScreenRendering(screenRenderingData, endTime);
        });
    }

    @Override
    public void endScreenRenderForCustomUiTrace(@NonNull Map<String, Object> data) {
        RunCatching.runCatching("ApmApi.endScreenRenderForCustomUiTrace", () -> {
            final long traceId = ((Number) data.get("traceId")).longValue();
            final long slowFramesTotalDuration = ((Number) data.get("slowFramesTotalDuration")).longValue();
            final long frozenFramesTotalDuration = ((Number) data.get("frozenFramesTotalDuration")).longValue();

            List<List<Number>> rawFrames = (List<List<Number>>) data.get("frameData");
            ArrayList<LuciqFrameData> frames = new ArrayList<>();
            if (rawFrames != null) {
                for (List<Number> frameValues : rawFrames) {
                    // Defensive: check size and nulls
                    if (frameValues != null && frameValues.size() >= 2) {
                        long frameStart = frameValues.get(0).longValue();
                        long frameDuration = frameValues.get(1).longValue();
                        frames.add(new LuciqFrameData(frameStart, frameDuration));
                    }
                }
            }
            LuciqScreenRenderingData screenRenderingData = new LuciqScreenRenderingData(traceId, slowFramesTotalDuration, frozenFramesTotalDuration, frames);
            InternalAPM._endCustomUiTraceWithScreenRenderingCP(screenRenderingData);
        });
    }

    @Override
    public void syncCustomSpan(@NonNull String name, @NonNull Long startTimestamp, @NonNull Long endTimestamp) {
        RunCatching.runCatching("ApmApi.syncCustomSpan", () -> {
            // Convert microseconds to milliseconds for Date objects
            Date startDate = new Date(startTimestamp / 1000);
            Date endDate = new Date(endTimestamp / 1000);

            APM.addCompletedCustomSpan(name, startDate, endDate);
        });
    }

}
