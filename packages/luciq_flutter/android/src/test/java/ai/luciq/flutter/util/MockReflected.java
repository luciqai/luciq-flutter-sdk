package ai.luciq.flutter.util;

import android.graphics.Bitmap;
import androidx.annotation.Nullable;

import ai.luciq.apm.networkinterception.cp.APMCPNetworkLog;
import ai.luciq.crash.models.LuciqNonFatalException;
import ai.luciq.library.model.StepType;

import org.json.JSONObject;

import java.util.Map;

/**
 * Includes fake implementations of methods called by reflection.
 * Used to verify whether or not a private methods was called.
 */
@SuppressWarnings("unused")
public class MockReflected {
    /**
     * Luciq.reportScreenChange
     */
    public static void reportScreenChange(Bitmap screenshot, String name) {}

    /**
     * Luciq.reportCurrentViewChange
     */
    public static void reportCurrentViewChange(String name) {}

    /**
     * Luciq.setCustomBrandingImage
     */
    public static void setCustomBrandingImage(Bitmap light, Bitmap dark) {}

    /**
     * Luciq.setCurrentPlatform
     */
    public static void setCurrentPlatform(int platform) {}

    /**
     * APMNetworkLogger.log
     */
    public static void apmNetworkLog(long requestStartTime, long requestDuration, String requestHeaders, String requestBody, long requestBodySize, String requestMethod, String requestUrl, String responseHeaders, String responseBody, String responseBodySize, long statusCode, int responseContentType, String errorMessage, String var18, @Nullable String gqlQueryName, @Nullable String serverErrorMessage, @Nullable APMCPNetworkLog.W3CExternalTraceAttributes w3CExternalTraceAttributes) {}

    /**
     * CrashReporting.reportException
     */
    public static void crashReportException(JSONObject exception, boolean isHandled) {}
    public static void crashReportException(JSONObject exception, boolean isHandled, Map<String,String> userAttributes, JSONObject fingerPrint, LuciqNonFatalException.Level level) {}


    public static void startUiTraceCP(String screenName, Long microTimeStamp, Long traceId) {}

    public static void reportScreenLoadingCP(Long startTimeStampMicro, Long durationMicro, Long uiTraceId) {}

    public static void endScreenLoadingCP(Long timeStampMicro, Long uiTraceId) {}
    public static void addUserStep(long timestamp, @StepType String stepType, String message, String label, String viewType) {
    }
}
