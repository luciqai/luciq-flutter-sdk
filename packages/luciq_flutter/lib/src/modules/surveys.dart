// ignore_for_file: avoid_classes_with_only_static_members

import 'dart:async';

import 'package:luciq_flutter/src/constants/debug_tags.dart';
import 'package:luciq_flutter/src/generated/surveys.api.g.dart';
import 'package:luciq_flutter/src/utils/lcq_build_info.dart';
import 'package:luciq_flutter/src/utils/luciq_logger.dart';
import 'package:luciq_flutter/src/utils/luciq_utils.dart';
import 'package:meta/meta.dart';

typedef OnShowSurveyCallback = void Function();
typedef OnDismissSurveyCallback = void Function();

class Surveys implements SurveysFlutterApi {
  static var _host = SurveysHostApi();
  static final _instance = Surveys();

  static OnShowSurveyCallback? _onShowCallback;
  static OnDismissSurveyCallback? _onDismissCallback;

  /// @nodoc
  @visibleForTesting
  // ignore: use_setters_to_change_properties
  static void $setHostApi(SurveysHostApi host) {
    _host = host;
  }

  /// @nodoc
  @internal
  static void $setup() {
    SurveysFlutterApi.setup(_instance);
  }

  /// @nodoc
  @internal
  @override
  void onShowSurvey() {
    _onShowCallback?.call();
  }

  /// @nodoc
  @internal
  @override
  void onDismissSurvey() {
    _onDismissCallback?.call();
  }

  /// @summary Sets whether surveys are enabled or not.
  /// If you disable surveys on the SDK but still have active surveys on your Luciq dashboard,
  /// those surveys are still going to be sent to the device, but are not going to be
  /// shown automatically.
  /// To manually display any available surveys, call `Luciq.showSurveyIfAvailable()`.
  /// Defaults to `true`.
  /// [isEnabled] A boolean to set whether Luciq Surveys is enabled or disabled.
  static Future<void> setEnabled(bool isEnabled) async {
    LuciqLogger.I.d(
      'setEnabled isEnabled=$isEnabled',
      tag: DebugTags.surveys,
    );
    return _host.setEnabled(isEnabled);
  }

  ///Sets whether auto surveys showing are enabled or not.
  /// [isEnabled] A boolean to indicate whether the
  /// surveys auto showing are enabled or not.
  static Future<void> setAutoShowingEnabled(bool isEnabled) async {
    LuciqLogger.I.d(
      'setAutoShowingEnabled isEnabled=$isEnabled',
      tag: DebugTags.surveys,
    );
    return _host.setAutoShowingEnabled(isEnabled);
  }

  /// Returns an array containing the available surveys.
  /// [callback] availableSurveysCallback callback with
  /// argument available surveys
  static Future<List<String>> getAvailableSurveys() async {
    LuciqLogger.I.d('getAvailableSurveys invoked', tag: DebugTags.surveys);
    final titles = await _host.getAvailableSurveys();

    return titles.cast<String>();
  }

  /// Sets a block of code to be executed just before the SDK's UI is presented.
  /// This block is executed on the UI thread. Could be used for performing any
  /// UI changes before the survey's UI is shown.
  /// [callback]  A callback that gets executed before presenting the survey's UI.
  static Future<void> setOnShowCallback(
    OnShowSurveyCallback callback,
  ) async {
    LuciqLogger.I.d(
      'setOnShowCallback callback registered',
      tag: DebugTags.surveys,
    );
    _onShowCallback = callback;
    return _host.bindOnShowSurveyCallback();
  }

  /// Sets a block of code to be executed just before the SDK's UI is presented.
  /// This block is executed on the UI thread. Could be used for performing any
  /// UI changes  after the survey's UI is dismissed.
  /// [callback]  A callback that gets executed after the survey's UI is dismissed.
  static Future<void> setOnDismissCallback(
    OnDismissSurveyCallback callback,
  ) async {
    LuciqLogger.I.d(
      'setOnDismissCallback callback registered',
      tag: DebugTags.surveys,
    );
    _onDismissCallback = callback;
    return _host.bindOnDismissSurveyCallback();
  }

  /// Setting an option for all the surveys to show a welcome screen before
  /// [shouldShowWelcomeScreen] A boolean for setting whether the  welcome screen should show.
  static Future<void> setShouldShowWelcomeScreen(
    bool shouldShowWelcomeScreen,
  ) async {
    LuciqLogger.I.d(
      'setShouldShowWelcomeScreen shouldShowWelcomeScreen=$shouldShowWelcomeScreen',
      tag: DebugTags.surveys,
    );
    return _host.setShouldShowWelcomeScreen(shouldShowWelcomeScreen);
  }

  ///  Shows one of the surveys that were not shown before, that also have conditions
  /// that match the current device/user.
  /// Does nothing if there are no available surveys or if a survey has already been shown
  /// in the current session.
  static Future<void> showSurveyIfAvailable() async {
    LuciqLogger.I.d('showSurveyIfAvailable invoked', tag: DebugTags.surveys);
    return _host.showSurveyIfAvailable();
  }

  /// Shows survey with a specific token.
  /// Does nothing if there are no available surveys with that specific token.
  /// Answered and cancelled surveys won't show up again.
  /// [surveyToken] - A String with a survey token.
  static Future<void> showSurvey(String surveyToken) async {
    LuciqLogger.I.d(
      'showSurvey surveyTokenLength=${surveyToken.length}',
      tag: DebugTags.surveys,
    );
    return _host.showSurvey(surveyToken);
  }

  /// Sets a block of code to be executed just before the SDK's UI is presented.
  /// This block is executed on the UI thread. Could be used for performing any
  /// UI changes  after the survey's UI is dismissed.
  /// [callback]  A callback that gets executed after the survey's UI is dismissed.
  static Future<bool> hasRespondedToSurvey(String surveyToken) async {
    LuciqLogger.I.d(
      'hasRespondedToSurvey surveyTokenLength=${surveyToken.length}',
      tag: DebugTags.surveys,
    );
    final hasResponded = await _host.hasRespondedToSurvey(surveyToken);

    return hasResponded;
  }

  /// iOS Only
  /// Sets url for the published iOS app on AppStore, You can redirect
  /// NPS Surveys or AppRating Surveys to AppStore to let users rate your app on AppStore itself.
  /// [appStoreURL] A String url for the published iOS app on AppStore
  static Future<void> setAppStoreURL(String appStoreURL) async {
    LuciqLogger.I.d(
      'setAppStoreURL url=${redactUrlForLog(appStoreURL)}',
      tag: DebugTags.surveys,
    );
    if (LCQBuildInfo.instance.isIOS) {
      return _host.setAppStoreURL(appStoreURL);
    }
  }
}
