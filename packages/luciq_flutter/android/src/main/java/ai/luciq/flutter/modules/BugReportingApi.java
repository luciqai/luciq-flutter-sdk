package ai.luciq.flutter.modules;

import android.annotation.SuppressLint;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import ai.luciq.bug.BugReporting;
import ai.luciq.flutter.generated.BugReportingPigeon;
import ai.luciq.flutter.util.ArgsRegistry;
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
        if (isEnabled) {
            BugReporting.setState(Feature.State.ENABLED);
        } else {
            BugReporting.setState(Feature.State.DISABLED);
        }
    }

    @SuppressLint("WrongConstant")
    @Override
    public void show(@NonNull String reportType, @Nullable List<String> invocationOptions) {
        int[] options = new int[invocationOptions.size()];
        for (int i = 0; i < invocationOptions.size(); i++) {
            options[i] = ArgsRegistry.invocationOptions.get(invocationOptions.get(i));
        }
        int reportTypeInt = ArgsRegistry.reportTypes.get(reportType);
        BugReporting.show(reportTypeInt, options);
    }

    @Override
    public void setInvocationEvents(@NonNull List<String> events) {
        LuciqInvocationEvent[] invocationEventsArray = new LuciqInvocationEvent[events.size()];

        for (int i = 0; i < events.size(); i++) {
            String key = events.get(i);
            invocationEventsArray[i] = ArgsRegistry.invocationEvents.get(key);
        }

        BugReporting.setInvocationEvents(invocationEventsArray);
    }

    @SuppressLint("WrongConstant")
    @Override
    public void setReportTypes(@NonNull List<String> types) {
        int[] reportTypesArray = new int[types.size()];

        for (int i = 0; i < types.size(); i++) {
            String key = types.get(i);
            reportTypesArray[i] = ArgsRegistry.reportTypes.get(key);
        }

        BugReporting.setReportTypes(reportTypesArray);
    }

    @Override
    public void setExtendedBugReportMode(@NonNull String mode) {
        final ExtendedBugReport.State resolvedMode = ArgsRegistry.extendedBugReportStates.get(mode);
        BugReporting.setExtendedBugReportState(resolvedMode);
    }

    @SuppressLint("WrongConstant")
    @Override
    public void setInvocationOptions(@NonNull List<String> options) {
        int[] resolvedOptions = new int[options.size()];
        for (int i = 0; i < options.size(); i++) {
            resolvedOptions[i] = ArgsRegistry.invocationOptions.get(options.get(i));
        }
        BugReporting.setOptions(resolvedOptions);
    }

    @Override
    public void setFloatingButtonEdge(@NonNull String edge, @NonNull Long offset) {
        final LuciqFloatingButtonEdge resolvedEdge = ArgsRegistry.floatingButtonEdges.get(edge);
        BugReporting.setFloatingButtonEdge(resolvedEdge);
        BugReporting.setFloatingButtonOffset(offset.intValue());
    }

    @Override
    public void setVideoRecordingFloatingButtonPosition(@NonNull String position) {
        final LuciqVideoRecordingButtonPosition resolvedPosition = ArgsRegistry.recordButtonPositions.get(position);
        BugReporting.setVideoRecordingFloatingButtonPosition(resolvedPosition);
    }

    @Override
    public void setShakingThresholdForiPhone(@NonNull Double threshold) {
        // iOS Only
    }

    @Override
    public void setShakingThresholdForiPad(@NonNull Double threshold) {
        // iOS Only
    }

    @Override
    public void setShakingThresholdForAndroid(@NonNull Long threshold) {
        BugReporting.setShakingThreshold(threshold.intValue());
    }

    @Override
    public void setEnabledAttachmentTypes(@NonNull Boolean screenshot, @NonNull Boolean extraScreenshot, @NonNull Boolean galleryImage, @NonNull Boolean screenRecording) {
        BugReporting.setAttachmentTypesEnabled(screenshot, extraScreenshot, galleryImage, screenRecording);
    }

    @Override
    public void bindOnInvokeCallback() {
        BugReporting.setOnInvokeCallback(new OnInvokeCallback() {
            @Override
            public void onInvoke() {
                // The on invoke callback for Flutter needs to be run on the
                // main thread, otherwise, it won't work and will break the
                // Luciq.show API
                ThreadManager.runOnMainThread(new Runnable() {
                    @Override
                    public void run() {
                        flutterApi.onSdkInvoke(new BugReportingPigeon.BugReportingFlutterApi.Reply<Void>() {
                            @Override
                            public void reply(Void reply) {
                            }
                        });
                    }
                });
            }
        });
    }

    @Override
    public void bindOnDismissCallback() {
        BugReporting.setOnDismissCallback(new OnSdkDismissCallback() {
            @Override
            public void call(DismissType dismissType, ReportType reportType) {
                ThreadManager.runOnMainThread(new Runnable() {
                    @Override
                    public void run() {
                        flutterApi.onSdkDismiss(dismissType.toString(), reportType.toString(), new BugReportingPigeon.BugReportingFlutterApi.Reply<Void>() {
                            @Override
                            public void reply(Void reply) {
                            }
                        });
                    }
                });
            }
        });
    }

    @Override
    public void setDisclaimerText(@NonNull String text) {
        BugReporting.setDisclaimerText(text);
    }

    @SuppressLint("WrongConstant")
    @Override
    public void setCommentMinimumCharacterCount(@NonNull Long limit, @Nullable List<String> reportTypes) {
        int[] reportTypesArray = reportTypes == null ? new int[0] : new int[reportTypes.size()];
        if(reportTypes != null){
        for (int i = 0; i < reportTypes.size(); i++) {
            String key = reportTypes.get(i);
            reportTypesArray[i] = ArgsRegistry.reportTypes.get(key);
        }
    }
        BugReporting.setCommentMinimumCharacterCountForBugReportType(limit.intValue(), reportTypesArray);
    }

    @Override
   public void addHabibaUserConsents(@NonNull String key, @NonNull String description, @NonNull Boolean mandatory, @NonNull Boolean checked, @Nullable String actionType){
        BugReporting.addUserConsent(key, description, mandatory, checked, actionType);
    }
}
