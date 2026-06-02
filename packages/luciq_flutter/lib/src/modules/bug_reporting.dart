// ignore_for_file: avoid_classes_with_only_static_members

import 'dart:async';

import 'package:luciq_flutter/luciq_flutter.dart';
import 'package:luciq_flutter/src/constants/debug_tags.dart';
import 'package:luciq_flutter/src/generated/bug_reporting.api.g.dart';
import 'package:luciq_flutter/src/utils/enum_converter.dart';
import 'package:luciq_flutter/src/utils/lcq_build_info.dart';
import 'package:luciq_flutter/src/utils/luciq_logger.dart';
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
  void onSdkInvoke() {
    _onInvokeCallback?.call();
  }

  /// @nodoc
  @internal
  @override
  void onSdkDismiss(String dismissType, String reportType) {
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

    if (dismissTypeMapper.containsKey(dismissTypeKey) &&
        reportTypeMapper.containsKey(reportTypeKey)) {
      _onDismissCallback?.call(
        dismissTypeMapper[dismissTypeKey]!,
        reportTypeMapper[reportTypeKey]!,
      );
    }
  }

  /// Enables and disables manual invocation and prompt options for bug and feedback.
  /// [boolean] isEnabled
  static Future<void> setEnabled(bool isEnabled) async {
    LuciqLogger.I.d(
      'setEnabled isEnabled=$isEnabled',
      tag: DebugTags.bugReporting,
    );
    return _host.setEnabled(isEnabled);
  }

  /// Sets a block of code to be executed just before the SDK's UI is presented.
  /// This block is executed on the UI thread. Could be used for performing any
  /// UI changes before the SDK's UI is shown.
  /// [callback]  A callback that gets executed before invoking the SDK
  static Future<void> setOnInvokeCallback(
    OnSDKInvokeCallback callback,
  ) async {
    LuciqLogger.I.d(
      'setOnInvokeCallback callback registered',
      tag: DebugTags.bugReporting,
    );
    _onInvokeCallback = callback;
    return _host.bindOnInvokeCallback();
  }

  /// Sets a block of code to be executed just before the SDK's UI is presented.
  /// This block is executed on the UI thread. Could be used for performing any
  /// UI changes before the SDK's UI is shown.
  /// [callback]  A callback that gets executed before invoking the SDK
  static Future<void> setOnDismissCallback(
    OnSDKDismissCallback callback,
  ) async {
    LuciqLogger.I.d(
      'setOnDismissCallback callback registered',
      tag: DebugTags.bugReporting,
    );
    _onDismissCallback = callback;
    return _host.bindOnDismissCallback();
  }

  /// Sets the events that invoke the feedback form.
  /// Default is set by [Luciq.init].
  /// [invocationEvents] invocationEvent List of events that invokes the
  static Future<void> setInvocationEvents(
    List<InvocationEvent>? invocationEvents,
  ) async {
    LuciqLogger.I.d(
      'setInvocationEvents count=${invocationEvents?.length ?? 0}',
      tag: DebugTags.bugReporting,
    );
    return _host.setInvocationEvents(invocationEvents.mapToString());
  }

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
  ) async {
    LuciqLogger.I.d(
      'setEnabledAttachmentTypes screenshot=$screenshot extraScreenshot=$extraScreenshot galleryImage=$galleryImage screenRecording=$screenRecording',
      tag: DebugTags.bugReporting,
    );
    return _host.setEnabledAttachmentTypes(
      screenshot,
      extraScreenshot,
      galleryImage,
      screenRecording,
    );
  }

  /// Sets what type of reports, bug or feedback, should be invoked.
  /// [reportTypes] - List of reportTypes
  static Future<void> setReportTypes(List<ReportType>? reportTypes) async {
    LuciqLogger.I.d(
      'setReportTypes count=${reportTypes?.length ?? 0}',
      tag: DebugTags.bugReporting,
    );
    if (reportTypes != null) {
      final types = List.of(reportTypes);
      types.remove(ReportType.other); //removed from report types
      return _host.setReportTypes(types.mapToString());
    }
    return _host.setReportTypes(reportTypes.mapToString());
  }

  /// Sets whether the extended bug report mode should be disabled, enabled with
  /// required fields or enabled with optional fields.
  /// [extendedBugReportMode] ExtendedBugReportMode enum
  static Future<void> setExtendedBugReportMode(
    ExtendedBugReportMode extendedBugReportMode,
  ) async {
    LuciqLogger.I.d(
      'setExtendedBugReportMode mode=$extendedBugReportMode',
      tag: DebugTags.bugReporting,
    );
    return _host.setExtendedBugReportMode(extendedBugReportMode.toString());
  }

  /// Sets the invocation options.
  /// Default is set by [Luciq.init].
  /// [invocationOptions] List of invocation options
  static Future<void> setInvocationOptions(
    List<InvocationOption>? invocationOptions,
  ) async {
    LuciqLogger.I.d(
      'setInvocationOptions count=${invocationOptions?.length ?? 0}',
      tag: DebugTags.bugReporting,
    );
    return _host.setInvocationOptions(invocationOptions.mapToString());
  }

  /// Sets the floating button position.
  /// [floatingButtonEdge] FloatingButtonEdge enum - left or right edge of the screen.
  /// [offsetFromTop] integer offset for the position on the y-axis.
  static Future<void> setFloatingButtonEdge(
    FloatingButtonEdge floatingButtonEdge,
    int offsetFromTop,
  ) async {
    LuciqLogger.I.d(
      'setFloatingButtonEdge edge=$floatingButtonEdge offsetFromTop=$offsetFromTop',
      tag: DebugTags.bugReporting,
    );
    return _host.setFloatingButtonEdge(
      floatingButtonEdge.toString(),
      offsetFromTop,
    );
  }

  /// Sets the position of the video recording button when using the screen recording attachment functionality.
  /// [position] Position of the video recording floating button on the screen.
  static Future<void> setVideoRecordingFloatingButtonPosition(
    Position position,
  ) async {
    LuciqLogger.I.d(
      'setVideoRecordingFloatingButtonPosition position=$position',
      tag: DebugTags.bugReporting,
    );
    return _host.setVideoRecordingFloatingButtonPosition(position.toString());
  }

  /// Invoke bug reporting with report type and options.
  /// [reportType] type
  /// [invocationOptions]  List of invocation options
  static Future<void> show(
    ReportType reportType,
    List<InvocationOption>? invocationOptions,
  ) async {
    LuciqLogger.I.d(
      'show reportType=$reportType invocationOptionsCount=${invocationOptions?.length ?? 0}',
      tag: DebugTags.bugReporting,
    );
    return _host.show(reportType.toString(), invocationOptions.mapToString());
  }

  /// Sets the threshold value of the shake gesture for iPhone/iPod Touch
  /// Default for iPhone is 2.5.
  /// [threshold] iPhoneShakingThreshold double
  static Future<void> setShakingThresholdForiPhone(double threshold) async {
    LuciqLogger.I.d(
      'setShakingThresholdForiPhone threshold=$threshold',
      tag: DebugTags.bugReporting,
    );
    if (LCQBuildInfo.instance.isIOS) {
      return _host.setShakingThresholdForiPhone(threshold);
    }
  }

  /// Sets the threshold value of the shake gesture for iPad
  /// Default for iPhone is 0.6.
  /// [threshold] iPhoneShakingThreshold double
  static Future<void> setShakingThresholdForiPad(double threshold) async {
    LuciqLogger.I.d(
      'setShakingThresholdForiPad threshold=$threshold',
      tag: DebugTags.bugReporting,
    );
    if (LCQBuildInfo.instance.isIOS) {
      return _host.setShakingThresholdForiPad(threshold);
    }
  }

  /// Sets the threshold value of the shake gesture for android devices.
  /// Default for android is an integer value equals 350.
  /// you could increase the shaking difficulty level by
  /// increasing the `350` value and vice versa
  /// [threshold] iPhoneShakingThreshold int
  static Future<void> setShakingThresholdForAndroid(int threshold) async {
    LuciqLogger.I.d(
      'setShakingThresholdForAndroid threshold=$threshold',
      tag: DebugTags.bugReporting,
    );
    if (LCQBuildInfo.instance.isAndroid) {
      return _host.setShakingThresholdForAndroid(threshold);
    }
  }

  /// Adds a disclaimer text within the bug reporting form,
  /// which can include hyperlinked text.
  /// [text] String text
  static Future<void> setDisclaimerText(String text) async {
    LuciqLogger.I.d(
      'setDisclaimerText textLength=${text.length}',
      tag: DebugTags.bugReporting,
    );
    return _host.setDisclaimerText(text);
  }

  /// Sets a minimum number of characters as a requirement for
  /// the comments field in the different report types.
  /// [limit] int number of characters
  /// [reportTypes] Optional list of ReportType. If it's not passed,
  /// the limit will apply to all report types.
  static Future<void> setCommentMinimumCharacterCount(
    int limit, [
    List<ReportType>? reportTypes,
  ]) async {
    LuciqLogger.I.d(
      'setCommentMinimumCharacterCount limit=$limit reportTypesCount=${reportTypes?.length ?? 0}',
      tag: DebugTags.bugReporting,
    );
    return _host.setCommentMinimumCharacterCount(
      limit,
      reportTypes.mapToString(),
    );
  }

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
  }) async {
    LuciqLogger.I.d(
      'addUserConsents keyLength=${key.length} descriptionLength=${description.length} mandatory=$mandatory checked=$checked actionType=$actionType',
      tag: DebugTags.bugReporting,
    );
    return _host.addUserConsents(
      key,
      description,
      mandatory,
      checked,
      actionType?.toString(),
    );
  }

  /// prompts end users to submit their feedback after our SDK automatically detects a frustrating experience.
  /// [config] configuration of proActive  bug report.
  static Future<void> setProactiveReportingConfigurations(
    ProactiveReportingConfigs config,
  ) async {
    LuciqLogger.I.d(
      'setProactiveReportingConfigurations enabled=${config.enabled} gapBetweenModals=${config.gapBetweenModals} modalDelayAfterDetection=${config.modalDelayAfterDetection}',
      tag: DebugTags.bugReporting,
    );
    _host.setProactiveReportingConfigurations(
      config.enabled,
      config.gapBetweenModals,
      config.modalDelayAfterDetection,
    );
  }
}
