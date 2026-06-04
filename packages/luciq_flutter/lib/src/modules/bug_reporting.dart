// ignore_for_file: avoid_classes_with_only_static_members

import 'dart:async';

import 'package:luciq_flutter/luciq_flutter.dart';
import 'package:luciq_flutter/src/constants/debug_tags.dart';
import 'package:luciq_flutter/src/generated/bug_reporting.api.g.dart';
import 'package:luciq_flutter/src/utils/enum_converter.dart';
import 'package:luciq_flutter/src/utils/host_call.dart';
import 'package:luciq_flutter/src/utils/lcq_build_info.dart';
import 'package:meta/meta.dart';

enum InvocationOption {
  commentFieldRequired,
  disablePostSendingDialog,
  emailFieldHidden,
  emailFieldOptional
}

enum UserConsentActionType {
  dropAutoCapturedMedia,
  dropLogs,
  noChat,
  noAutomaticBugGrouping,
}

enum DismissType { cancel, submit, addAttachment }

enum ReportType { bug, feedback, question, other }

enum ExtendedBugReportMode {
  enabledWithRequiredFields,
  enabledWithOptionalFields,
  disabled
}

enum FloatingButtonEdge { left, right }

enum Position {
  topRight,
  topLeft,
  bottomRight,
  bottomLeft,
}

typedef OnSDKInvokeCallback = void Function();
typedef OnSDKDismissCallback = void Function(DismissType, ReportType);

class BugReporting implements BugReportingFlutterApi {
  static var _host = BugReportingHostApi();
  static final _instance = BugReporting();

  static OnSDKInvokeCallback? _onInvokeCallback;
  static OnSDKDismissCallback? _onDismissCallback;

  /// @nodoc
  @visibleForTesting
  // ignore: use_setters_to_change_properties
  static void $setHostApi(BugReportingHostApi host) {
    _host = host;
  }

  /// @nodoc
  @internal
  static void $setup() {
    BugReportingFlutterApi.setup(_instance);
  }

  /// @nodoc
  @internal
  @override
  void onSdkInvoke(String callId) {
    logCallbackFire(
      'BR.onSdkInvoke',
      tag: DebugTags.bugReporting,
      callId: callId,
      args: {'callbackPresent': _onInvokeCallback != null},
    );
    _onInvokeCallback?.call();
  }

  /// @nodoc
  @internal
  @override
  void onSdkDismiss(String callId, String dismissType, String reportType) {
    final dismissTypeKey = dismissType.toUpperCase();
    final reportTypeKey = reportType.toUpperCase();

    const dismissTypeMapper = {
      'CANCEL': DismissType.cancel,
      'SUBMIT': DismissType.submit,
      'ADD_ATTACHMENT': DismissType.addAttachment,
    };

    const reportTypeMapper = {
      'BUG': ReportType.bug,
      'FEEDBACK': ReportType.feedback,
      'OTHER': ReportType.other,
    };

    final mapped = dismissTypeMapper.containsKey(dismissTypeKey) &&
        reportTypeMapper.containsKey(reportTypeKey);
    logCallbackFire(
      'BR.onSdkDismiss',
      tag: DebugTags.bugReporting,
      callId: callId,
      args: {
        'dismissType': dismissTypeKey,
        'reportType': reportTypeKey,
        'mapped': mapped,
        'callbackPresent': _onDismissCallback != null,
      },
    );

    if (mapped) {
      _onDismissCallback?.call(
        dismissTypeMapper[dismissTypeKey]!,
        reportTypeMapper[reportTypeKey]!,
      );
    }
  }

  /// Enables and disables manual invocation and prompt options for bug and feedback.
  /// [boolean] isEnabled
  static Future<void> setEnabled(bool isEnabled) => hostCall(
        'BR.setEnabled',
        () => _host.setEnabled(isEnabled),
        tag: DebugTags.bugReporting,
        args: {'isEnabled': isEnabled},
      );

  /// Sets a block of code to be executed just before the SDK's UI is presented.
  /// This block is executed on the UI thread. Could be used for performing any
  /// UI changes before the SDK's UI is shown.
  /// [callback]  A callback that gets executed before invoking the SDK
  static Future<void> setOnInvokeCallback(
    OnSDKInvokeCallback callback,
  ) {
    _onInvokeCallback = callback;
    return hostCall(
      'BR.setOnInvokeCallback',
      () => _host.bindOnInvokeCallback(),
      tag: DebugTags.bugReporting,
    );
  }

  /// Sets a block of code to be executed just before the SDK's UI is presented.
  /// This block is executed on the UI thread. Could be used for performing any
  /// UI changes before the SDK's UI is shown.
  /// [callback]  A callback that gets executed before invoking the SDK
  static Future<void> setOnDismissCallback(
    OnSDKDismissCallback callback,
  ) {
    _onDismissCallback = callback;
    return hostCall(
      'BR.setOnDismissCallback',
      () => _host.bindOnDismissCallback(),
      tag: DebugTags.bugReporting,
    );
  }

  /// Sets the events that invoke the feedback form.
  /// Default is set by [Luciq.init].
  /// [invocationEvents] invocationEvent List of events that invokes the
  static Future<void> setInvocationEvents(
    List<InvocationEvent>? invocationEvents,
  ) =>
      hostCall(
        'BR.setInvocationEvents',
        () => _host.setInvocationEvents(invocationEvents.mapToString()),
        tag: DebugTags.bugReporting,
        args: {'count': invocationEvents?.length ?? 0},
      );

  /// Sets whether attachments in bug reporting and in-app messaging are enabled or not.
  /// [screenshot] A boolean to enable or disable screenshot attachments.
  /// [extraScreenshot] A boolean to enable or disable extra screenshot attachments.
  /// [galleryImage] A boolean to enable or disable gallery image
  /// attachments. In iOS 10+,NSPhotoLibraryUsageDescription should be set in
  /// info.plist to enable gallery image attachments.
  /// [screenRecording] A boolean to enable or disable screen recording attachments.
  static Future<void> setEnabledAttachmentTypes(
    bool screenshot,
    bool extraScreenshot,
    bool galleryImage,
    bool screenRecording,
  ) =>
      hostCall(
        'BR.setEnabledAttachmentTypes',
        () => _host.setEnabledAttachmentTypes(
          screenshot,
          extraScreenshot,
          galleryImage,
          screenRecording,
        ),
        tag: DebugTags.bugReporting,
        args: {
          'screenshot': screenshot,
          'extraScreenshot': extraScreenshot,
          'galleryImage': galleryImage,
          'screenRecording': screenRecording,
        },
      );

  /// Sets what type of reports, bug or feedback, should be invoked.
  /// [reportTypes] - List of reportTypes
  static Future<void> setReportTypes(List<ReportType>? reportTypes) {
    final filtered = reportTypes == null
        ? null
        : (List.of(reportTypes)..remove(ReportType.other));
    return hostCall(
      'BR.setReportTypes',
      () => _host.setReportTypes(filtered.mapToString()),
      tag: DebugTags.bugReporting,
      args: {
        'inputCount': reportTypes?.length ?? 0,
        'filteredCount': filtered?.length ?? 0,
      },
    );
  }

  /// Sets whether the extended bug report mode should be disabled, enabled with
  /// required fields or enabled with optional fields.
  /// [extendedBugReportMode] ExtendedBugReportMode enum
  static Future<void> setExtendedBugReportMode(
    ExtendedBugReportMode extendedBugReportMode,
  ) =>
      hostCall(
        'BR.setExtendedBugReportMode',
        () => _host.setExtendedBugReportMode(extendedBugReportMode.toString()),
        tag: DebugTags.bugReporting,
        args: {'mode': extendedBugReportMode},
      );

  /// Sets the invocation options.
  /// Default is set by [Luciq.init].
  /// [invocationOptions] List of invocation options
  static Future<void> setInvocationOptions(
    List<InvocationOption>? invocationOptions,
  ) =>
      hostCall(
        'BR.setInvocationOptions',
        () => _host.setInvocationOptions(invocationOptions.mapToString()),
        tag: DebugTags.bugReporting,
        args: {'count': invocationOptions?.length ?? 0},
      );

  /// Sets the floating button position.
  /// [floatingButtonEdge] FloatingButtonEdge enum - left or right edge of the screen.
  /// [offsetFromTop] integer offset for the position on the y-axis.
  static Future<void> setFloatingButtonEdge(
    FloatingButtonEdge floatingButtonEdge,
    int offsetFromTop,
  ) =>
      hostCall(
        'BR.setFloatingButtonEdge',
        () => _host.setFloatingButtonEdge(
          floatingButtonEdge.toString(),
          offsetFromTop,
        ),
        tag: DebugTags.bugReporting,
        args: {'edge': floatingButtonEdge, 'offsetFromTop': offsetFromTop},
      );

  /// Sets the position of the video recording button when using the screen recording attachment functionality.
  /// [position] Position of the video recording floating button on the screen.
  static Future<void> setVideoRecordingFloatingButtonPosition(
    Position position,
  ) =>
      hostCall(
        'BR.setVideoRecordingFloatingButtonPosition',
        () =>
            _host.setVideoRecordingFloatingButtonPosition(position.toString()),
        tag: DebugTags.bugReporting,
        args: {'position': position},
      );

  /// Invoke bug reporting with report type and options.
  /// [reportType] type
  /// [invocationOptions]  List of invocation options
  static Future<void> show(
    ReportType reportType,
    List<InvocationOption>? invocationOptions,
  ) =>
      hostCall(
        'BR.show',
        () => _host.show(reportType.toString(), invocationOptions.mapToString()),
        tag: DebugTags.bugReporting,
        args: {
          'reportType': reportType,
          'invocationOptionsCount': invocationOptions?.length ?? 0,
        },
      );

  /// Sets the threshold value of the shake gesture for iPhone/iPod Touch
  /// Default for iPhone is 2.5.
  /// [threshold] iPhoneShakingThreshold double
  static Future<void> setShakingThresholdForiPhone(double threshold) => hostCall(
        'BR.setShakingThresholdForiPhone',
        () async {
          if (LCQBuildInfo.instance.isIOS) {
            return _host.setShakingThresholdForiPhone(threshold);
          }
        },
        tag: DebugTags.bugReporting,
        args: {'threshold': threshold, 'isIOS': LCQBuildInfo.instance.isIOS},
      );

  /// Sets the threshold value of the shake gesture for iPad
  /// Default for iPhone is 0.6.
  /// [threshold] iPhoneShakingThreshold double
  static Future<void> setShakingThresholdForiPad(double threshold) => hostCall(
        'BR.setShakingThresholdForiPad',
        () async {
          if (LCQBuildInfo.instance.isIOS) {
            return _host.setShakingThresholdForiPad(threshold);
          }
        },
        tag: DebugTags.bugReporting,
        args: {'threshold': threshold, 'isIOS': LCQBuildInfo.instance.isIOS},
      );

  /// Sets the threshold value of the shake gesture for android devices.
  /// Default for android is an integer value equals 350.
  /// you could increase the shaking difficulty level by
  /// increasing the `350` value and vice versa
  /// [threshold] iPhoneShakingThreshold int
  static Future<void> setShakingThresholdForAndroid(int threshold) => hostCall(
        'BR.setShakingThresholdForAndroid',
        () async {
          if (LCQBuildInfo.instance.isAndroid) {
            return _host.setShakingThresholdForAndroid(threshold);
          }
        },
        tag: DebugTags.bugReporting,
        args: {
          'threshold': threshold,
          'isAndroid': LCQBuildInfo.instance.isAndroid,
        },
      );

  /// Adds a disclaimer text within the bug reporting form,
  /// which can include hyperlinked text.
  /// [text] String text
  static Future<void> setDisclaimerText(String text) => hostCall(
        'BR.setDisclaimerText',
        () => _host.setDisclaimerText(text),
        tag: DebugTags.bugReporting,
        args: {'textLength': text.length},
      );

  /// Sets a minimum number of characters as a requirement for
  /// the comments field in the different report types.
  /// [limit] int number of characters
  /// [reportTypes] Optional list of ReportType. If it's not passed,
  /// the limit will apply to all report types.
  static Future<void> setCommentMinimumCharacterCount(
    int limit, [
    List<ReportType>? reportTypes,
  ]) =>
      hostCall(
        'BR.setCommentMinimumCharacterCount',
        () => _host.setCommentMinimumCharacterCount(
          limit,
          reportTypes.mapToString(),
        ),
        tag: DebugTags.bugReporting,
        args: {
          'limit': limit,
          'reportTypesCount': reportTypes?.length ?? 0,
        },
      );

  /// Adds a user consent item to the bug reporting form.
  /// [key] A unique identifier string for the consent item.
  /// [description] The text shown to the user describing the consent item.
  /// [mandatory] Whether the user must agree to this item before submitting a report.
  ///  [checked] Whether the consent checkbox is pre-selected.
  ///  [actionType] A string representing the action type to map to SDK behavior.
  static Future<void> addUserConsents({
    required String key,
    required String description,
    required bool mandatory,
    required bool checked,
    UserConsentActionType? actionType,
  }) =>
      hostCall(
        'BR.addUserConsents',
        () => _host.addUserConsents(
          key,
          description,
          mandatory,
          checked,
          actionType?.toString(),
        ),
        tag: DebugTags.bugReporting,
        args: {
          'keyLength': key.length,
          'descriptionLength': description.length,
          'mandatory': mandatory,
          'checked': checked,
          'actionType': actionType,
        },
      );

  /// prompts end users to submit their feedback after our SDK automatically detects a frustrating experience.
  /// [config] configuration of proActive  bug report.
  static Future<void> setProactiveReportingConfigurations(
    ProactiveReportingConfigs config,
  ) =>
      hostCall(
        'BR.setProactiveReportingConfigurations',
        () async => _host.setProactiveReportingConfigurations(
          config.enabled,
          config.gapBetweenModals,
          config.modalDelayAfterDetection,
        ),
        tag: DebugTags.bugReporting,
        args: {
          'enabled': config.enabled,
          'gapBetweenModals': config.gapBetweenModals,
          'modalDelayAfterDetection': config.modalDelayAfterDetection,
        },
      );
}
