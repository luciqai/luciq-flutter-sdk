import 'package:flutter/foundation.dart';
import 'package:luciq_flutter/luciq_flutter.dart';
import 'package:luciq_flutter_example/main.dart';
import 'package:patrol/patrol.dart';

Future<void> init(PatrolIntegrationTester $) async {
  Luciq.init(
    token: 'ed6f659591566da19b67857e1b9d40ab',
    invocationEvents: [InvocationEvent.floatingButton],
    debugLogsLevel: LogLevel.verbose,
  );

  Luciq.setWelcomeMessageMode(WelcomeMessageMode.disabled);

  await $.pumpWidgetAndSettle(const MyApp());
  await $.native2.initialize();

  await wait(second: 2);
}

Future<void> wait({int? second, int? miliSeconds}) {
  return Future.delayed(
      Duration(seconds: second ?? 0, milliseconds: miliSeconds ?? 0));
}

Future<GetNativeViewsResult> getNativeView(PatrolIntegrationTester $,
    {required String android,
    required String ios,
    bool waitUntilVisible = true}) async {
  final nativeView = NativeSelector(
      ios: IOSSelector(identifier: ios),
      android: AndroidSelector(
          resourceName: 'ai.luciq.flutter.example:id/${android}'));
  if (waitUntilVisible) {
    await $.native2
        .waitUntilVisible(nativeView, timeout: const Duration(seconds: 8));
  }

  return await $.native2.getNativeViews(nativeView);
}

Future<void> tapNativeView(PatrolIntegrationTester $,
    {required NativeSelector nativeView, bool waitUntilVisible = true}) async {
  if (waitUntilVisible) {
    await $.native2
        .waitUntilVisible(nativeView, timeout: const Duration(seconds: 8));
  }

  await $.native2.tap(nativeView);
}

Future<GetNativeViewsResult> getFAB(PatrolIntegrationTester $,
    {bool waitUntilVisible = true}) {
  return getNativeView($,
      android: 'instabug_floating_button',
      ios: 'IBGFloatingButtonAccessibilityIdentifier',
      waitUntilVisible: waitUntilVisible);
}

/// Taps "Show Manual Survey" and returns the native survey dialog once visible,
/// retrying the whole cycle.
///
/// `Surveys.showSurvey(token)` is a no-op until the survey is fetched from the
/// backend, so the first tap can silently do nothing. Retrying re-invokes it
/// after the fetch lands, which keeps the E2E from flaking on a slow fetch.
Future<GetNativeViewsResult> showManualSurveyUntilVisible(
  PatrolIntegrationTester $, {
  int maxAttempts = 5,
}) async {
  final surveyDialog = NativeSelector(
    ios: IOSSelector(identifier: 'SurveyNavigationVC'),
    android: AndroidSelector(
      resourceName:
          'ai.luciq.flutter.example:id/instabug_survey_dialog_container',
    ),
  );

  for (var attempt = 1; attempt <= maxAttempts; attempt++) {
    await $('Show Manual Survey').scrollTo().tap();
    try {
      await $.native2.waitUntilVisible(
        surveyDialog,
        timeout: const Duration(seconds: 8),
      );
      return await $.native2.getNativeViews(surveyDialog);
    } on PatrolActionException {
      if (attempt == maxAttempts) rethrow;
      await wait(second: 2);
    }
  }
  throw StateError('Survey dialog did not appear after $maxAttempts attempts');
}

bool get isAndroid {
  return defaultTargetPlatform == TargetPlatform.android;
}
