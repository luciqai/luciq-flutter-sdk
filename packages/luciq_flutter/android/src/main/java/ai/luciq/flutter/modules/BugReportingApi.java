package ai.luciq.flutter.modules;

import android.annotation.SuppressLint;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import ai.luciq.bug.BugReporting;
import ai.luciq.bug.ProactiveReportingConfigs;
import ai.luciq.flutter.generated.BugReportingPigeon;
import ai.luciq.flutter.util.ArgsRegistry;
import ai.luciq.flutter.util.LuciqFlutterDebugTags;
import ai.luciq.flutter.util.LuciqFlutterLogger;
import ai.luciq.flutter.util.ThreadManager;
import ai.luciq.library.Feature;
import ai.luciq.library.OnSdkDismissCallback;
import ai.luciq.library.extendedbugreport.ExtendedBugReport;
import ai.luciq.library.invocation.LuciqInvocationEvent;
import ai.luciq.library.invocation.OnInvokeCallback;
import ai.luciq.library.invocation.util.LuciqFloatingButtonEdge;
import ai.luciq.library.invocation.util.LuciqVideoRecordingButtonPosition;

import java.util.List;

import io.flutter.plugin.common.BinaryMessenger;

public class BugReportingApi implements BugReportingPigeon.BugReportingHostApi {
    private final BugReportingPigeon.BugReportingFlutterApi flutterApi;

    public static void init(BinaryMessenger messenger) {
        final BugReportingPigeon.BugReportingFlutterApi flutterApi = new BugReportingPigeon.BugReportingFlutterApi(messenger);
        final BugReportingApi api = new BugReportingApi(flutterApi);
        BugReportingPigeon.BugReportingHostApi.setup(messenger, api);
    }

    public BugReportingApi(BugReportingPigeon.BugReportingFlutterApi flutterApi) {
        this.flutterApi = flutterApi;
    }

    @Override
    public void setEnabled(@NonNull Boolean isEnabled) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.BUG_REPORTING, "[BR.setEnabled] phase=enter isEnabled=" + isEnabled);
        if (isEnabled) {
            BugReporting.setState(Feature.State.ENABLED);
        } else {
            BugReporting.setState(Feature.State.DISABLED);
        }
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.BUG_REPORTING, "[BR.setEnabled] phase=exit");
    }

    @SuppressLint("WrongConstant")
    @Override
    public void show(@NonNull String reportType, @Nullable List<String> invocationOptions) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.BUG_REPORTING,
                "[BR.show] phase=enter reportType=" + reportType
                        + " invocationOptionsCount=" + (invocationOptions != null ? invocationOptions.size() : 0));
        int[] options = new int[invocationOptions.size()];
        for (int i = 0; i < invocationOptions.size(); i++) {
            options[i] = ArgsRegistry.invocationOptions.get(invocationOptions.get(i));
        }
        int reportTypeInt = ArgsRegistry.reportTypes.get(reportType);
        BugReporting.show(reportTypeInt, options);
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.BUG_REPORTING, "[BR.show] phase=exit");
    }

    @Override
    public void setInvocationEvents(@NonNull List<String> events) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.BUG_REPORTING, "[BR.setInvocationEvents] phase=enter eventsCount=" + events.size());
        LuciqInvocationEvent[] invocationEventsArray = new LuciqInvocationEvent[events.size()];

        for (int i = 0; i < events.size(); i++) {
            String key = events.get(i);
            invocationEventsArray[i] = ArgsRegistry.invocationEvents.get(key);
        }

        BugReporting.setInvocationEvents(invocationEventsArray);
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.BUG_REPORTING, "[BR.setInvocationEvents] phase=exit");
    }

    @SuppressLint("WrongConstant")
    @Override
    public void setReportTypes(@NonNull List<String> types) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.BUG_REPORTING, "[BR.setReportTypes] phase=enter typesCount=" + types.size());
        int[] reportTypesArray = new int[types.size()];

        for (int i = 0; i < types.size(); i++) {
            String key = types.get(i);
            reportTypesArray[i] = ArgsRegistry.reportTypes.get(key);
        }

        BugReporting.setReportTypes(reportTypesArray);
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.BUG_REPORTING, "[BR.setReportTypes] phase=exit");
    }

    @Override
    public void setExtendedBugReportMode(@NonNull String mode) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.BUG_REPORTING, "[BR.setExtendedBugReportMode] phase=enter mode=" + mode);
        final ExtendedBugReport.State resolvedMode = ArgsRegistry.extendedBugReportStates.get(mode);
        BugReporting.setExtendedBugReportState(resolvedMode);
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.BUG_REPORTING, "[BR.setExtendedBugReportMode] phase=exit");
    }

    @SuppressLint("WrongConstant")
    @Override
    public void setInvocationOptions(@NonNull List<String> options) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.BUG_REPORTING, "[BR.setInvocationOptions] phase=enter optionsCount=" + options.size());
        int[] resolvedOptions = new int[options.size()];
        for (int i = 0; i < options.size(); i++) {
            resolvedOptions[i] = ArgsRegistry.invocationOptions.get(options.get(i));
        }
        BugReporting.setOptions(resolvedOptions);
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.BUG_REPORTING, "[BR.setInvocationOptions] phase=exit");
    }

    @Override
    public void setFloatingButtonEdge(@NonNull String edge, @NonNull Long offset) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.BUG_REPORTING,
                "[BR.setFloatingButtonEdge] phase=enter edge=" + edge + " offset=" + offset);
        final LuciqFloatingButtonEdge resolvedEdge = ArgsRegistry.floatingButtonEdges.get(edge);
        BugReporting.setFloatingButtonEdge(resolvedEdge);
        BugReporting.setFloatingButtonOffset(offset.intValue());
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.BUG_REPORTING, "[BR.setFloatingButtonEdge] phase=exit");
    }

    @Override
    public void setVideoRecordingFloatingButtonPosition(@NonNull String position) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.BUG_REPORTING,
                "[BR.setVideoRecordingFloatingButtonPosition] phase=enter position=" + position);
        final LuciqVideoRecordingButtonPosition resolvedPosition = ArgsRegistry.recordButtonPositions.get(position);
        BugReporting.setVideoRecordingFloatingButtonPosition(resolvedPosition);
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.BUG_REPORTING, "[BR.setVideoRecordingFloatingButtonPosition] phase=exit");
    }

    @Override
    public void setShakingThresholdForiPhone(@NonNull Double threshold) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.BUG_REPORTING,
                "[BR.setShakingThresholdForiPhone] phase=enter threshold=" + threshold);
        // iOS Only
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.BUG_REPORTING, "[BR.setShakingThresholdForiPhone] phase=exit");
    }

    @Override
    public void setShakingThresholdForiPad(@NonNull Double threshold) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.BUG_REPORTING,
                "[BR.setShakingThresholdForiPad] phase=enter threshold=" + threshold);
        // iOS Only
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.BUG_REPORTING, "[BR.setShakingThresholdForiPad] phase=exit");
    }

    @Override
    public void setShakingThresholdForAndroid(@NonNull Long threshold) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.BUG_REPORTING,
                "[BR.setShakingThresholdForAndroid] phase=enter threshold=" + threshold);
        BugReporting.setShakingThreshold(threshold.intValue());
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.BUG_REPORTING, "[BR.setShakingThresholdForAndroid] phase=exit");
    }

    @Override
    public void setEnabledAttachmentTypes(@NonNull Boolean screenshot, @NonNull Boolean extraScreenshot, @NonNull Boolean galleryImage, @NonNull Boolean screenRecording) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.BUG_REPORTING,
                "[BR.setEnabledAttachmentTypes] phase=enter screenshot=" + screenshot
                        + " extraScreenshot=" + extraScreenshot
                        + " galleryImage=" + galleryImage
                        + " screenRecording=" + screenRecording);
        BugReporting.setAttachmentTypesEnabled(screenshot, extraScreenshot, galleryImage, screenRecording);
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.BUG_REPORTING, "[BR.setEnabledAttachmentTypes] phase=exit");
    }

    @Override
    public void bindOnInvokeCallback() {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.BUG_REPORTING, "[BR.bindOnInvokeCallback] phase=enter");
        BugReporting.setOnInvokeCallback(new OnInvokeCallback() {
            @Override
            public void onInvoke() {
                // The on invoke callback for Flutter needs to be run on the
                // main thread, otherwise, it won't work and will break the
                // Luciq.show API
                ThreadManager.runOnMainThread(new Runnable() {
                    @Override
                    public void run() {
                        String callId = LuciqFlutterLogger.nextCallId();
                        LuciqFlutterLogger.d(
                                LuciqFlutterDebugTags.BUG_REPORTING,
                                "[BR.onSdkInvoke] #" + callId + " phase=fire");
                        flutterApi.onSdkInvoke(callId, new BugReportingPigeon.BugReportingFlutterApi.Reply<Void>() {
                            @Override
                            public void reply(Void reply) {
                            }
                        });
                    }
                });
            }
        });
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.BUG_REPORTING, "[BR.bindOnInvokeCallback] phase=exit");
    }

    @Override
    public void bindOnDismissCallback() {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.BUG_REPORTING, "[BR.bindOnDismissCallback] phase=enter");
        BugReporting.setOnDismissCallback(new OnSdkDismissCallback() {
            @Override
            public void call(DismissType dismissType, ReportType reportType) {
                ThreadManager.runOnMainThread(new Runnable() {
                    @Override
                    public void run() {
                        String callId = LuciqFlutterLogger.nextCallId();
                        String dismissTypeString = dismissType.toString();
                        String reportTypeString = reportType.toString();
                        LuciqFlutterLogger.d(
                                LuciqFlutterDebugTags.BUG_REPORTING,
                                "[BR.onSdkDismiss] #" + callId + " phase=fire dismissType=" + dismissTypeString + " reportType=" + reportTypeString);
                        flutterApi.onSdkDismiss(callId, dismissTypeString, reportTypeString, new BugReportingPigeon.BugReportingFlutterApi.Reply<Void>() {
                            @Override
                            public void reply(Void reply) {
                            }
                        });
                    }
                });
            }
        });
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.BUG_REPORTING, "[BR.bindOnDismissCallback] phase=exit");
    }

    @Override
    public void setDisclaimerText(@NonNull String text) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.BUG_REPORTING,
                "[BR.setDisclaimerText] phase=enter length=" + text.length());
        BugReporting.setDisclaimerText(text);
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.BUG_REPORTING, "[BR.setDisclaimerText] phase=exit");
    }

    @SuppressLint("WrongConstant")
    @Override
    public void setCommentMinimumCharacterCount(@NonNull Long limit, @Nullable List<String> reportTypes) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.BUG_REPORTING,
                "[BR.setCommentMinimumCharacterCount] phase=enter limit=" + limit
                        + " reportTypesCount=" + (reportTypes != null ? reportTypes.size() : 0));
        int[] reportTypesArray = reportTypes == null ? new int[0] : new int[reportTypes.size()];
        if(reportTypes != null){
        for (int i = 0; i < reportTypes.size(); i++) {
            String key = reportTypes.get(i);
            reportTypesArray[i] = ArgsRegistry.reportTypes.get(key);
        }
    }
        BugReporting.setCommentMinimumCharacterCountForBugReportType(limit.intValue(), reportTypesArray);
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.BUG_REPORTING, "[BR.setCommentMinimumCharacterCount] phase=exit");
    }

    @Override
    public void addUserConsents(String key, String description, Boolean mandatory, Boolean checked, String actionType) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.BUG_REPORTING,
                "[BR.addUserConsents] phase=enter keyLength=" + (key == null ? -1 : key.length())
                        + " descriptionLength=" + (description == null ? -1 : description.length())
                        + " mandatory=" + mandatory
                        + " checked=" + checked
                        + " actionTypePresent=" + (actionType != null));
        ThreadManager.runOnMainThread(new Runnable() {
            @Override
            public void run() {
                String mappedActionType;
                try {
                    if (actionType == null) {
                        mappedActionType = null;
                    } else {
                        mappedActionType = ArgsRegistry.userConsentActionType.get(actionType);
                    }

                    BugReporting.addUserConsent(key, description, mandatory, checked, mappedActionType);
                    LuciqFlutterLogger.d(LuciqFlutterDebugTags.BUG_REPORTING, "[BR.addUserConsents] phase=exit");
                } catch (Exception e) {
                    LuciqFlutterLogger.e(
                            LuciqFlutterDebugTags.BUG_REPORTING,
                            "[BR.addUserConsents] phase=error errorType=" + e.getClass().getSimpleName(),
                            e);
                }
            }
        });
    }

    @Override
    public void setProactiveReportingConfigurations(@NonNull Boolean enabled, @NonNull Long gapBetweenModals, @NonNull Long modalDelayAfterDetection) {
        LuciqFlutterLogger.d(LuciqFlutterDebugTags.BUG_REPORTING,
                "[BR.setProactiveReportingConfigurations] phase=enter enabled=" + enabled
                        + " gapBetweenModals=" + gapBetweenModals
                        + " modalDelayAfterDetection=" + modalDelayAfterDetection);
        ThreadManager.runOnMainThread(new Runnable() {
            @Override
            public void run() {
                try {
                    ProactiveReportingConfigs configs = new ProactiveReportingConfigs.Builder()
                            .setGapBetweenModals(gapBetweenModals)
                            .setModalDelayAfterDetection(modalDelayAfterDetection)
                            .isEnabled(enabled)
                            .build();
                    BugReporting.setProactiveReportingConfigurations(configs);
                    LuciqFlutterLogger.d(LuciqFlutterDebugTags.BUG_REPORTING, "[BR.setProactiveReportingConfigurations] phase=exit");
                } catch (Exception e) {
                    LuciqFlutterLogger.e(
                            LuciqFlutterDebugTags.BUG_REPORTING,
                            "[BR.setProactiveReportingConfigurations] phase=error errorType=" + e.getClass().getSimpleName(),
                            e);
                }
            }
        });
    }
}
