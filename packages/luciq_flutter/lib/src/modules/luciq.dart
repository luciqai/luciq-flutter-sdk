// ignore_for_file: avoid_classes_with_only_static_members

import 'dart:async';

// to maintain supported versions prior to Flutter 3.3
// ignore: unnecessary_import
import 'dart:typed_data';

// to maintain supported versions prior to Flutter 3.3
// ignore: unnecessary_import
import 'dart:ui';

import 'package:flutter/material.dart';

// to maintain supported versions prior to Flutter 3.3
// ignore: unused_import
import 'package:flutter/services.dart';
import 'package:luciq_flutter/luciq_flutter.dart';
import 'package:luciq_flutter/src/constants/debug_tags.dart';
import 'package:luciq_flutter/src/generated/luciq.api.g.dart';
import 'package:luciq_flutter/src/utils/enum_converter.dart';
import 'package:luciq_flutter/src/utils/feature_flags_manager.dart';
import 'package:luciq_flutter/src/utils/host_call.dart';
import 'package:luciq_flutter/src/utils/lcq_build_info.dart';
import 'package:luciq_flutter/src/utils/luciq_logger.dart';
import 'package:luciq_flutter/src/utils/private_views/private_views_manager.dart';
import 'package:luciq_flutter/src/utils/screen_name_masker.dart';
import 'package:luciq_flutter/src/utils/screen_rendering/luciq_screen_render_manager.dart'
    show LuciqScreenRenderManager;
import 'package:luciq_flutter/src/utils/user_steps/user_step_details.dart';
import 'package:meta/meta.dart';

enum InvocationEvent {
  shake,
  screenshot,
  twoFingersSwipeLeft,
  floatingButton,
  none
}

enum WelcomeMessageMode { live, beta, disabled }

enum LCQLocale {
  arabic,
  azerbaijani,
  chineseSimplified,
  chineseTraditional,
  czech,
  danish,
  dutch,
  english,
  estonian,
  finnish,
  french,
  german,
  greek,
  hungarian,
  indonesian,
  italian,
  japanese,
  korean,
  latvian,
  lithuanian,
  norwegian,
  polish,
  portugueseBrazil,
  portuguesePortugal,
  romanian,
  russian,
  serbian,
  slovak,
  slovenian,
  spanish,
  swedish,
  turkish,
  ukrainian,
}

enum LogLevel {
  none,
  error,
  debug,
  verbose,
}

enum ColorTheme { dark, light }

enum CustomTextPlaceHolderKey {
  shakeHint,
  swipeHint,
  invalidEmailMessage,
  invocationHeader,
  reportQuestion,
  reportBug,
  reportFeedback,
  emailFieldHint,
  commentFieldHintForBugReport,
  commentFieldHintForFeedback,
  commentFieldHintForQuestion,
  addVoiceMessage,
  addImageFromGallery,
  addExtraScreenshot,
  conversationsListTitle,
  audioRecordingPermissionDenied,
  conversationTextFieldHint,
  voiceMessagePressAndHoldToRecord,
  voiceMessageReleaseToAttach,
  reportSuccessfullySent,
  successDialogHeader,
  addVideo,
  videoPressRecord,
  betaWelcomeMessageWelcomeStepTitle,
  betaWelcomeMessageWelcomeStepContent,
  betaWelcomeMessageHowToReportStepTitle,
  betaWelcomeMessageHowToReportStepContent,
  betaWelcomeMessageFinishStepTitle,
  betaWelcomeMessageFinishStepContent,
  liveWelcomeMessageTitle,
  liveWelcomeMessageContent,
  repliesNotificationTeamName,
  repliesNotificationReplyButton,
  repliesNotificationDismissButton,
  surveysStoreRatingThanksTitle,
  surveysStoreRatingThanksSubtitle,
  reportBugDescription,
  reportFeedbackDescription,
  reportQuestionDescription,
  requestFeatureDescription,
  discardAlertTitle,
  discardAlertMessage,
  discardAlertCancel,
  discardAlertAction,
  addAttachmentButtonTitleStringName,
  reportReproStepsDisclaimerBody,
  reportReproStepsDisclaimerLink,
  reproStepsProgressDialogBody,
  reproStepsListHeader,
  reproStepsListDescription,
  reproStepsListEmptyStateDescription,
  reproStepsListItemTitle,
  okButtonText,
  audio,
  image,
  screenRecording,
  messagesNotificationAndOthers,
  insufficientContentTitle,
  insufficientContentMessage,
}

enum ReproStepsMode { enabled, disabled, enabledWithNoScreenshots }

/// Disposal manager for handling Android lifecycle events
class _LuciqDisposalManager implements LuciqFlutterApi {
  _LuciqDisposalManager._();

  static final _LuciqDisposalManager _instance = _LuciqDisposalManager._();

  static _LuciqDisposalManager get instance => _instance;

  @override
  void dispose() {
    // Call the LuciqScreenRenderManager [syncCollectedScreenRenderingData] method when Android onPause is triggered
    // to overcome calling onActivityDestroy() from android side before sending the data to it.

    //Save the screen rendering data for the active traces Auto|Custom.
    LuciqScreenRenderManager.I.syncCollectedScreenRenderingData();
  }
}

class Luciq {
  static var _host = LuciqHostApi();

  static const tag = 'Luciq';

  /// @nodoc
  @visibleForTesting
  // ignore: use_setters_to_change_properties
  static void $setHostApi(LuciqHostApi host) {
    _host = host;
  }

  /// @nodoc
  @internal
  static void $setup() {
    BugReporting.$setup();
    Replies.$setup();
    Surveys.$setup();
    // Set up LuciqFlutterApi for Android onDestroy disposal
    LuciqFlutterApi.setup(_LuciqDisposalManager.instance);
  }

  /// @nodoc
  @internal
  static Future<bool?> isEnabled() => hostCall(
        'Luciq.isEnabled',
        () => _host.isEnabled(),
        tag: DebugTags.core,
      );

  /// @nodoc
  @internal
  static Future<bool?> isBuilt() => hostCall(
        'Luciq.isBuilt',
        () => _host.isBuilt(),
        tag: DebugTags.core,
      );

  /// Enables or disables Luciq functionality.
  /// [boolean] isEnabled
  static Future<void> setEnabled(bool isEnabled) => hostCall(
        'Luciq.setEnabled',
        () => _host.setEnabled(isEnabled),
        tag: DebugTags.core,
        args: {'isEnabled': isEnabled},
      );

  /// Starts the SDK.
  /// This is the main SDK method that does all the magic. This is the only
  /// method that SHOULD be called.
  /// The [token] that identifies the app, you can find it on your dashboard.
  /// The [invocationEvents] are the events that invoke the SDK's UI.
  /// The [debugLogsLevel] used to debug Luciq's SDK.
  /// The [appVariant] used to set current App variant name.
  static Future<void> init({
    required String token,
    required List<InvocationEvent> invocationEvents,
    LogLevel debugLogsLevel = LogLevel.error,
    String? appVariant,
  }) {
    $setup();
    LuciqLogger.I.logLevel = debugLogsLevel;
    return hostCall<void>(
      'Luciq.init',
      () async {
        await _host.init(
          token,
          invocationEvents.mapToString(),
          debugLogsLevel.toString(),
          appVariant,
        );
        return FeatureFlagsManager().registerFeatureFlagsListener();
      },
      tag: DebugTags.core,
      args: {
        'tokenPresent': token.isNotEmpty,
        'invocationEventsCount': invocationEvents.length,
        'debugLogsLevel': debugLogsLevel,
        'appVariantPresent': appVariant != null,
      },
    );
  }

  /// Changes the Dart-side debug log verbosity at runtime.
  ///
  /// Use this to capture a debug trace mid-session (e.g. a support flow
  /// where the user reproduces an issue) without re-initializing the SDK.
  /// Affects only the Dart [LuciqLogger]; the native SDK log level is set
  /// at [init] time and is not changed by this call.
  static void setDebugLogsLevel(LogLevel level) {
    final previous = LuciqLogger.I.logLevel;
    // Emit BEFORE mutating so the transition is visible even when lowering to none.
    LuciqLogger.I.d(
      '[Luciq.setDebugLogsLevel] phase=enter previous=$previous level=$level',
      tag: DebugTags.core,
    );
    LuciqLogger.I.logLevel = level;
  }

  /// Sets a [callback] to be called wehenever a screen name is captured to mask
  /// sensitive information in the screen name.
  static void setScreenNameMaskingCallback(
    ScreenNameMaskingCallback? callback,
  ) {
    LuciqLogger.I.d(
      '[Luciq.setScreenNameMaskingCallback] phase=enter callbackPresent=${callback != null}',
      tag: DebugTags.core,
    );
    ScreenNameMasker.I.setMaskingCallback(callback);
  }

  /// Shows the welcome message in a specific mode.
  /// [welcomeMessageMode] is an enum to set the welcome message mode to live, or beta.
  static Future<void> showWelcomeMessageWithMode(
    WelcomeMessageMode welcomeMessageMode,
  ) =>
      hostCall(
        'Luciq.showWelcomeMessageWithMode',
        () => _host.showWelcomeMessageWithMode(welcomeMessageMode.toString()),
        tag: DebugTags.core,
        args: {'mode': welcomeMessageMode},
      );

  /// Sets the default value of the user's [email] and hides the email field from the reporting UI
  /// and set the user's [name] and [id] to be included with all reports.
  /// It also reset the chats on device to that email and removes user attributes,
  /// user data and completed surveys.
  static Future<void> identifyUser(
    String? email, [
    String? name,
    String? id,
  ]) =>
      hostCall(
        'Luciq.identifyUser',
        () => _host.identifyUser(email, name, id),
        tag: DebugTags.core,
        args: {
          'emailPresent': email != null,
          'namePresent': name != null,
          'idPresent': id != null,
        },
      );

  /// Sets the default value of the user's email to nil and show email field and remove user name
  /// from all reports
  /// It also reset the chats on device and removes user attributes, user data and completed surveys.
  static Future<void> logOut() => hostCall(
        'Luciq.logOut',
        () => _host.logOut(),
        tag: DebugTags.core,
      );

  /// Sets the SDK's [locale].
  /// Use to change the SDK's UI to different language.
  /// Defaults to the device's current locale.
  static Future<void> setLocale(LCQLocale locale) => hostCall(
        'Luciq.setLocale',
        () => _host.setLocale(locale.toString()),
        tag: DebugTags.core,
        args: {'locale': locale},
      );

  /// Sets the color theme of the SDK's whole UI to the [colorTheme] given.
  /// It should be of type [ColorTheme].
  static Future<void> setColorTheme(ColorTheme colorTheme) => hostCall(
        'Luciq.setColorTheme',
        () => _host.setColorTheme(colorTheme.toString()),
        tag: DebugTags.core,
        args: {'colorTheme': colorTheme},
      );

  /// Appends a set of [tags] to previously added tags of reported feedback, bug or crash.
  static Future<void> appendTags(List<String> tags) => hostCall(
        'Luciq.appendTags',
        () => _host.appendTags(tags),
        tag: DebugTags.core,
        args: {'count': tags.length},
      );

  /// Manually removes all tags of reported feedback, bug or crash.
  static Future<void> resetTags() => hostCall(
        'Luciq.resetTags',
        () => _host.resetTags(),
        tag: DebugTags.core,
      );

  /// Gets all tags of reported feedback, bug or crash. Returns the list of tags.
  static Future<List<String>?> getTags() => hostCall<List<String>?>(
        'Luciq.getTags',
        () async {
          final tags = await _host.getTags();
          return tags?.cast<String>();
        },
        tag: DebugTags.core,
      );

  /// Adds feature flags to the next report.
  static Future<void> addFeatureFlags(List<FeatureFlag> featureFlags) =>
      hostCall(
        'Luciq.addFeatureFlags',
        () {
          final map = <String, String>{};
          for (final value in featureFlags) {
            map[value.name] = value.variant ?? '';
          }
          return _host.addFeatureFlags(map);
        },
        tag: DebugTags.featureFlags,
        args: {'count': featureFlags.length},
      );

  /// Removes certain feature flags from the next report.
  static Future<void> removeFeatureFlags(List<String> featureFlags) => hostCall(
        'Luciq.removeFeatureFlags',
        () => _host.removeFeatureFlags(featureFlags),
        tag: DebugTags.featureFlags,
        args: {'count': featureFlags.length},
      );

  /// Clears all feature flags from the next report.
  static Future<void> clearAllFeatureFlags() => hostCall(
        'Luciq.clearAllFeatureFlags',
        () => _host.removeAllFeatureFlags(),
        tag: DebugTags.featureFlags,
      );

  /// Add custom user attribute [value] with a [key] that is going to be sent with each feedback, bug or crash.
  static Future<void> setUserAttribute(String value, String key) => hostCall(
        'Luciq.setUserAttribute',
        () => _host.setUserAttribute(value, key),
        tag: DebugTags.core,
        args: {'keyLength': key.length, 'valueLength': value.length},
      );

  /// Removes a given [key] and its associated value from user attributes.
  /// Does nothing if a [key] does not exist.
  static Future<void> removeUserAttribute(String key) => hostCall(
        'Luciq.removeUserAttribute',
        () => _host.removeUserAttribute(key),
        tag: DebugTags.core,
        args: {'keyLength': key.length},
      );

  /// Returns the user attribute associated with a given [key].
  static Future<String?> getUserAttributeForKey(String key) =>
      hostCall<String?>(
        'Luciq.getUserAttributeForKey',
        () => _host.getUserAttributeForKey(key),
        tag: DebugTags.core,
        args: {'keyLength': key.length},
      );

  /// A new Map containing all the currently set user attributes, or an empty Map if no user attributes have been set.
  static Future<Map<String, String>?> getUserAttributes() => hostCall(
        'Luciq.getUserAttributes',
        () async {
          final attributes = await _host.getUserAttributes();
          return attributes != null
              ? Map<String, String>.from(attributes)
              : <String, String>{};
        },
        tag: DebugTags.core,
      );

  /// invoke sdk manually
  static Future<void> show() => hostCall(
        'Luciq.show',
        () => _host.show(),
        tag: DebugTags.core,
      );

  /// Logs a user event with [name] that happens through the lifecycle of the application.
  /// Logged user events are going to be sent with each report, as well as at the end of a session.
  static Future<void> logUserEvent(String name) => hostCall(
        'Luciq.logUserEvent',
        () => _host.logUserEvent(name),
        tag: DebugTags.core,
        args: {'nameLength': name.length},
      );

  /// Overrides any of the strings shown in the SDK with custom ones.
  /// Allows you to customize a [value] shown to users in the SDK using a predefined [key].
  static Future<void> setValueForStringWithKey(
    String value,
    CustomTextPlaceHolderKey key,
  ) =>
      hostCall(
        'Luciq.setValueForStringWithKey',
        () => _host.setValueForStringWithKey(value, key.toString()),
        tag: DebugTags.core,
        args: {'key': key, 'valueLength': value.length},
      );

  /// Enable/disable session profiler
  /// [sessionProfilerEnabled] desired state of the session profiler feature.
  static Future<void> setSessionProfilerEnabled(
    bool sessionProfilerEnabled,
  ) =>
      hostCall(
        'Luciq.setSessionProfilerEnabled',
        () => _host.setSessionProfilerEnabled(sessionProfilerEnabled),
        tag: DebugTags.core,
        args: {'sessionProfilerEnabled': sessionProfilerEnabled},
      );

  /// Sets the primary color of the SDK's UI.
  /// Sets the color of UI elements indicating interactivity or call to action.
  /// [color] primaryColor A color to set the UI elements of the SDK to.
  ///
  /// Note: This API is deprecated. Please use `Luciq.setTheme` instead.
  @Deprecated(
    'This API is deprecated. Please use Luciq.setTheme instead.',
  )
  static Future<void> setPrimaryColor(Color color) async {
    LuciqLogger.I.d(
      '[Luciq.setPrimaryColor] phase=enter',
      tag: DebugTags.core,
    );
    await setTheme(ThemeConfig(primaryColor: color.toString()));
  }

  /// Adds specific user data that you need to be added to the reports
  /// [userData] data to be added
  static Future<void> setUserData(String userData) => hostCall(
        'Luciq.setUserData',
        () => _host.setUserData(userData),
        tag: DebugTags.core,
        args: {'length': userData.length},
      );

  /// Add file to be attached to the bug report.
  /// [filePath] of the file
  /// [fileName] of the file
  static Future<void> addFileAttachmentWithURL(
    String filePath,
    String fileName,
  ) =>
      hostCall(
        'Luciq.addFileAttachmentWithURL',
        () => _host.addFileAttachmentWithURL(filePath, fileName),
        tag: DebugTags.core,
        args: {
          'filePathLength': filePath.length,
          'fileNameLength': fileName.length,
        },
      );

  /// Add file to be attached to the bug report.
  /// [data] of the file
  /// [fileName] of the file
  static Future<void> addFileAttachmentWithData(
    Uint8List data,
    String fileName,
  ) =>
      hostCall(
        'Luciq.addFileAttachmentWithData',
        () => _host.addFileAttachmentWithData(data, fileName),
        tag: DebugTags.core,
        args: {
          'dataLength': data.length,
          'fileNameLength': fileName.length,
        },
      );

  /// Clears all Uris of the attached files.
  /// The URIs which added via {@link Luciq#addFileAttachment} API not the physical files.
  static Future<void> clearFileAttachments() => hostCall(
        'Luciq.clearFileAttachments',
        () => _host.clearFileAttachments(),
        tag: DebugTags.core,
      );

  /// Sets the welcome message mode to live, beta or disabled.
  /// [welcomeMessageMode] An enum to set the welcome message mode to live, beta or disabled.
  static Future<void> setWelcomeMessageMode(
    WelcomeMessageMode welcomeMessageMode,
  ) =>
      hostCall(
        'Luciq.setWelcomeMessageMode',
        () => _host.setWelcomeMessageMode(welcomeMessageMode.toString()),
        tag: DebugTags.core,
        args: {'mode': welcomeMessageMode},
      );

  /// Reports that the screen has been changed (repro steps)
  /// [screenName] String containing the screen name
  static Future<void> reportScreenChange(String screenName) => hostCall(
        'Luciq.reportScreenChange',
        () => _host.reportScreenChange(screenName),
        tag: DebugTags.screenTracking,
        args: {'screenNameLength': screenName.length},
      );

  /// Changes the font of Luciq's UI.
  /// [font] The asset path to the font file (e.g. "fonts/Poppins.ttf").
  static Future<void> setFont(String font) => hostCall(
        'Luciq.setFont',
        () async {
          if (LCQBuildInfo.I.isIOS) {
            return _host.setFont(font);
          }
        },
        tag: DebugTags.core,
        args: {'fontLength': font.length, 'isIOS': LCQBuildInfo.I.isIOS},
      );

  /// Sets the repro steps mode for Bug Reporting, Crash Reporting and Session Replay.
  ///
  /// [bug] repro steps mode for bug reports.
  /// [crash] repro steps mode for crash reports.
  /// [sessionReplay] repro steps mode for session replay.
  /// [all] repro steps mode for bug reports, crash reports and session replay.
  /// If [all] is set, it will override the other modes.
  ///
  /// Example:
  /// ```dart
  /// Luciq.setReproStepsConfig(
  ///   bug: ReproStepsMode.enabled,
  ///   crash: ReproStepsMode.disabled,
  ///   sessionReplay: ReproStepsMode.enabled,
  /// );
  ///  ```
  static Future<void> setReproStepsConfig({
    ReproStepsMode? bug,
    ReproStepsMode? crash,
    ReproStepsMode? sessionReplay,
    ReproStepsMode? all,
  }) {
    var bugMode = bug;
    var crashMode = crash;
    var sessionReplayMode = sessionReplay;

    if (all != null) {
      bugMode = all;
      crashMode = all;
      sessionReplayMode = all;
    }

    return hostCall(
      'Luciq.setReproStepsConfig',
      () => _host.setReproStepsConfig(
        bugMode?.toString(),
        crashMode?.toString(),
        sessionReplayMode?.toString(),
      ),
      tag: DebugTags.core,
      args: {
        'bug': bugMode,
        'crash': crashMode,
        'sessionReplay': sessionReplayMode,
        'allPresent': all != null,
      },
    );
  }

  /// Sets a custom branding image logo with [light] and [dark] images for different color modes.
  ///
  /// If no [context] is passed, [asset variants](https://docs.flutter.dev/development/ui/assets-and-images#asset-variants) won't work as expected;
  /// if you have different variants of the [light] or [dark] image assets make sure to pass the [context] in order for the right variant to be picked up.
  static Future<void> setCustomBrandingImage({
    required AssetImage light,
    required AssetImage dark,
    BuildContext? context,
  }) =>
      hostCall(
        'Luciq.setCustomBrandingImage',
        () async {
          var configuration = ImageConfiguration.empty;
          if (context != null) {
            configuration = createLocalImageConfiguration(context);
          }

          final lightKey = await light.obtainKey(configuration);
          final darkKey = await dark.obtainKey(configuration);
          return _host.setCustomBrandingImage(lightKey.name, darkKey.name);
        },
        tag: DebugTags.core,
        args: {'contextPresent': context != null},
      );

  /// Allows detection of app review sessions which are submitted through custom prompts.
  ///
  /// Use this when utilizing a custom app rating prompt. It should be called
  /// once the user clicks on the Call to Action (CTA) that redirects them to the app store.
  /// Helps track session data for insights on user interactions during review submission.
  static Future<void> willRedirectToStore() => hostCall(
        'Luciq.willRedirectToStore',
        () => _host.willRedirectToStore(),
        tag: DebugTags.core,
      );

  /// Sets the fullscreen mode for Luciq UI.
  ///
  /// [isFullscreen] - Whether to enable fullscreen mode or not.
  ///
  /// Example:
  /// ```dart
  /// Luciq.setFullscreen(true);
  /// ```
  static Future<void> setFullscreen(bool isEnabled) => hostCall(
        'Luciq.setFullscreen',
        () => _host.setFullscreen(isEnabled),
        tag: DebugTags.core,
        args: {'isEnabled': isEnabled},
      );

  /// This property sets the `appVariant` string to be included in all network requests.
  ///  It should be set before calling [init] method.
  /// [appVariant] used to set current App variant name
  static Future<void> setAppVariant(String appVariant) => hostCall(
        'Luciq.setAppVariant',
        () => _host.setAppVariant(appVariant),
        tag: DebugTags.core,
        args: {'appVariantLength': appVariant.length},
      );

  /// Sets a custom theme for Luciq UI elements.
  ///
  /// @param theme - Configuration object containing theme properties
  ///
  /// Example:
  /// ```dart
  ///
  /// Luciq.setTheme(ThemeConfig(
  ///   primaryColor: '#FF6B6B',
  ///   secondaryTextColor: '#666666',
  ///   primaryTextColor: '#333333',
  ///   titleTextColor: '#000000',
  ///   backgroundColor: '#FFFFFF',
  ///   primaryTextStyle: 'bold',
  ///   secondaryTextStyle: 'normal',
  ///   titleTextStyle: 'bold',
  ///   ctaTextStyle: 'bold',
  ///   primaryFontPath: '/data/user/0/com.yourapp/files/fonts/YourFont.ttf',
  ///   secondaryFontPath: '/data/user/0/com.yourapp/files/fonts/YourFont.ttf',
  ///   ctaFontPath: '/data/user/0/com.yourapp/files/fonts/YourFont.ttf',
  ///   primaryFontAsset: 'fonts/YourFont.ttf',
  ///   secondaryFontAsset: 'fonts/YourFont.ttf'
  /// ));
  /// ```
  static Future<void> setTheme(ThemeConfig themeConfig) => hostCall(
        'Luciq.setTheme',
        () => _host.setTheme(themeConfig.toMap()),
        tag: DebugTags.core,
      );

  /// Enables and disables user interaction steps.
  /// [boolean] isEnabled
  static Future<void> enableUserSteps(bool isEnabled) => hostCall(
        'Luciq.enableUserSteps',
        () => _host.setEnableUserSteps(isEnabled),
        tag: DebugTags.core,
        args: {'isEnabled': isEnabled},
      );

  /// Master switch that controls all WebView tracking data collection,
  /// including user interactions, network logs and WebView screen loading
  /// in APM.
  ///
  /// The master switch is enabled by default on the native SDK. When set
  /// to `false`, all other WebView APIs have no effect.
  ///
  /// Only `WKWebView` (iOS) and Android's native `WebView` are supported.
  ///
  /// Note: On Android, you must also enable WebView tracking at build time
  /// by adding `luciq { webViewsTrackingEnabled = true }` to your app's
  /// `build.gradle`. Without this, no WebView tracking code is compiled
  /// into your app.
  static Future<void> setWebViewMonitoringEnabled(bool isEnabled) => hostCall(
        'Luciq.setWebViewMonitoringEnabled',
        () => _host.setWebViewMonitoringEnabled(isEnabled),
        tag: DebugTags.core,
        args: {'isEnabled': isEnabled},
      );

  /// Enables capturing user interactions inside WebViews (tap, scroll,
  /// navigation, swipe). These are reported in the logs section and
  /// in Repro Steps.
  ///
  /// Disabled by default. Requires the master switch
  /// [setWebViewMonitoringEnabled] to be enabled.
  static Future<void> setWebViewUserInteractionsTrackingEnabled(
    bool isEnabled,
  ) =>
      hostCall(
        'Luciq.setWebViewUserInteractionsTrackingEnabled',
        () => _host.setWebViewUserInteractionsTrackingEnabled(isEnabled),
        tag: DebugTags.core,
        args: {'isEnabled': isEnabled},
      );

  /// Enables capturing network logs (Fetch/XHR) triggered from inside
  /// WebViews. Captured requests appear in the logs section of bug,
  /// crash and session replay reports.
  ///
  /// Disabled by default. Requires the master switch
  /// [setWebViewMonitoringEnabled] to be enabled.
  static Future<void> setWebViewNetworkTrackingEnabled(bool isEnabled) =>
      hostCall(
        'Luciq.setWebViewNetworkTrackingEnabled',
        () => _host.setWebViewNetworkTrackingEnabled(isEnabled),
        tag: DebugTags.core,
        args: {'isEnabled': isEnabled},
      );

  /// Sets the screenshot auto-masking types to apply before screenshots
  /// are sent with reports.
  ///
  /// Pass a single-element list of [AutoMasking.none] to disable masking
  /// entirely, or any combination of the other values to opt-in to
  /// masking those categories:
  /// - [AutoMasking.labels]: mask all Flutter `Text` widgets.
  /// - [AutoMasking.textInputs]: mask all text input widgets.
  /// - [AutoMasking.media]: mask images and videos.
  /// - [AutoMasking.webViews]: mask native `WKWebView` / Android `WebView`
  ///   content (default when WebView tracking is enabled).
  ///
  /// Example:
  /// ```dart
  /// Luciq.setAutoMaskScreenshotTypes([AutoMasking.webViews, AutoMasking.labels]);
  /// ```
  static Future<void> setAutoMaskScreenshotTypes(
    List<AutoMasking> types,
  ) async {
    LuciqLogger.I.d(
      '[Luciq.setAutoMaskScreenshotTypes] phase=enter count=${types.length}',
      tag: DebugTags.privateView,
    );
    PrivateViewsManager.I.addAutoMasking(types);
  }

  /// Enables and disables manual invocation and prompt options for bug and feedback.
  /// [boolean] isEnabled
  static Future<void> logUserSteps(
    GestureType gestureType,
    String message,
    String? viewName,
  ) =>
      hostCall(
        'Luciq.logUserSteps',
        () => _host.logUserSteps(gestureType.toString(), message, viewName),
        tag: DebugTags.core,
        args: {
          'gestureType': gestureType,
          'messageLength': message.length,
          'viewNamePresent': viewName != null,
        },
      );
}
