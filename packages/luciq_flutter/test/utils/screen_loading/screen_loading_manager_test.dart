import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luciq_flutter/luciq_flutter.dart';
import 'package:luciq_flutter/src/generated/apm.api.g.dart';
import 'package:luciq_flutter/src/generated/luciq.api.g.dart';
import 'package:luciq_flutter/src/utils/lcq_build_info.dart';
import 'package:luciq_flutter/src/utils/lcq_date_time.dart';
import 'package:luciq_flutter/src/utils/luciq_logger.dart';
import 'package:luciq_flutter/src/utils/luciq_montonic_clock.dart';
import 'package:luciq_flutter/src/utils/screen_loading/screen_loading_trace.dart';
import 'package:luciq_flutter/src/utils/screen_loading/ui_trace.dart';
import 'package:luciq_flutter/src/utils/ui_trace/flags_config.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'screen_loading_manager_test.mocks.dart';

class ScreenLoadingManagerNoResets extends ScreenLoadingManager {
  ScreenLoadingManagerNoResets.init() : super.init();

  @override
  void resetDidExtendScreenLoading() {}

  @override
  void resetDidReportScreenLoading() {}

  @override
  void resetDidStartScreenLoading() {}
}

@GenerateMocks([
  ApmHostApi,
  LuciqHostApi,
  LuciqLogger,
  LCQDateTime,
  LuciqMonotonicClock,
  LCQBuildInfo,
  RouteMatcher,
  BuildContext,
  Widget,
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();

  late ScreenLoadingManager mScreenLoadingManager;
  late MockApmHostApi mApmHost;
  late MockLuciqHostApi mLuciqHost;
  late MockLuciqLogger mLuciqLogger;
  late LCQDateTime mDateTime;
  late LCQBuildInfo mLCQBuildInfo;
  late MockRouteMatcher mRouteMatcher;
  late LuciqMonotonicClock mLuciqMonotonicClock;
  late MockWidget mockScreen;
  late MockBuildContext mockBuildContext;
  const screenName = 'screen1';

  setUp(() {
    mScreenLoadingManager = ScreenLoadingManager.init();
    mApmHost = MockApmHostApi();
    mLuciqHost = MockLuciqHostApi();
    mLuciqLogger = MockLuciqLogger();
    mDateTime = MockLCQDateTime();
    mLCQBuildInfo = MockLCQBuildInfo();
    mRouteMatcher = MockRouteMatcher();
    mLuciqMonotonicClock = MockLuciqMonotonicClock();
    when(mLuciqHost.isBuilt()).thenAnswer((_) async => true);

    ScreenLoadingManager.setInstance(mScreenLoadingManager);
    APM.$setHostApi(mApmHost);
    Luciq.$setHostApi(mLuciqHost);
    LuciqLogger.setInstance(mLuciqLogger);
    LCQDateTime.setInstance(mDateTime);
    LCQBuildInfo.setInstance(mLCQBuildInfo);
    RouteMatcher.setInstance(mRouteMatcher);
    LuciqMonotonicClock.setInstance(mLuciqMonotonicClock);
  });

  group('reset methods tests', () {
    test(
        '[resetDidStartScreenLoading] should set _currentUITrace?.didStartScreenLoading to false',
        () async {
      const expected = false;
      final uiTrace = UiTrace(screenName: 'screen1', traceId: 1);
      uiTrace.didStartScreenLoading = true;
      mScreenLoadingManager.currentUiTrace = uiTrace;

      ScreenLoadingManager.I.resetDidStartScreenLoading();

      final actual =
          ScreenLoadingManager.I.currentUiTrace?.didStartScreenLoading;

      expect(actual, expected);
      verify(
        mLuciqLogger.d(
          argThat(contains('Resetting didStartScreenLoading')),
          tag: APM.tag,
        ),
      ).called(1);
    });

    test(
        '[resetDidReportScreenLoading] should set _currentUITrace?.didReportScreenLoading to false',
        () async {
      const expected = false;
      final uiTrace = UiTrace(screenName: 'screen1', traceId: 1);
      uiTrace.didReportScreenLoading = true;
      mScreenLoadingManager.currentUiTrace = uiTrace;

      ScreenLoadingManager.I.resetDidReportScreenLoading();

      final actual =
          ScreenLoadingManager.I.currentUiTrace?.didReportScreenLoading;

      expect(actual, expected);
      verify(
        mLuciqLogger.d(
          argThat(contains('Resetting didExtendScreenLoading')),
          tag: APM.tag,
        ),
      ).called(1);
    });

    test(
        '[resetDidExtendScreenLoading] should set _currentUITrace?.didExtendScreenLoading to false',
        () async {
      const expected = false;
      final uiTrace = UiTrace(screenName: 'screen1', traceId: 1);
      mScreenLoadingManager.currentUiTrace = uiTrace;

      ScreenLoadingManager.I.resetDidExtendScreenLoading();

      final actualUiTrace = ScreenLoadingManager.I.currentUiTrace;

      expect(
        actualUiTrace?.didStartScreenLoading,
        false,
      );
      expect(
        actualUiTrace?.didReportScreenLoading,
        false,
      );
      expect(
        actualUiTrace?.didExtendScreenLoading,
        false,
      );
      expect(actualUiTrace?.didExtendScreenLoading, expected);
      verify(
        mLuciqLogger.d(
          argThat(contains('Resetting didReportScreenLoading')),
          tag: APM.tag,
        ),
      ).called(1);
    });
  });

  group('startScreenLoadingTrace tests', () {
    late DateTime time;
    late UiTrace uiTrace;
    late int traceId;
    late ScreenLoadingTrace screenLoadingTrace;
    setUp(() {
      mScreenLoadingManager = ScreenLoadingManagerNoResets.init();
      time = DateTime.now();
      traceId = time.millisecondsSinceEpoch;
      uiTrace = UiTrace(screenName: screenName, traceId: traceId);
      mScreenLoadingManager.currentUiTrace = uiTrace;
      when(mDateTime.now()).thenReturn(time);

      screenLoadingTrace = ScreenLoadingTrace(
        screenName,
        startTimeInMicroseconds: time.microsecondsSinceEpoch,
        startMonotonicTimeInMicroseconds: time.microsecondsSinceEpoch,
      );
      ScreenLoadingManager.setInstance(mScreenLoadingManager);
    });

    test('[startScreenLoadingTrace] with SDK not build should Log error',
        () async {
      when(mLuciqHost.isBuilt()).thenAnswer((_) async => false);

      await ScreenLoadingManager.I.startScreenLoadingTrace(screenLoadingTrace);

      final actualUiTrace = ScreenLoadingManager.I.currentUiTrace;
      final actualScreenLoadingTrace =
          ScreenLoadingManager.I.currentScreenLoadingTrace;

      expect(
        actualUiTrace?.didStartScreenLoading,
        false,
      );
      expect(
        actualScreenLoadingTrace,
        null,
      );
      verify(
        mLuciqLogger.e(
          'Luciq API {APM.LuciqCaptureScreenLoading} was called before the SDK is built. To build it, first by following the instructions at this link:\n'
          'https://docs.luciq.ai/reference#showing-and-manipulating-the-invocation',
          tag: APM.tag,
        ),
      ).called(1);
    });

    test(
        '[startScreenLoadingTrace] with screen loading disabled on iOS Platform should log error',
        () async {
      when(FlagsConfig.screenLoading.isEnabled())
          .thenAnswer((_) async => false);
      when(LCQBuildInfo.I.isIOS).thenReturn(true);

      await ScreenLoadingManager.I.startScreenLoadingTrace(screenLoadingTrace);

      final actualUiTrace = ScreenLoadingManager.I.currentUiTrace;
      final actualScreenLoadingTrace =
          ScreenLoadingManager.I.currentScreenLoadingTrace;

      expect(
        actualUiTrace?.didStartScreenLoading,
        false,
      );
      expect(
        actualScreenLoadingTrace,
        null,
      );
      verify(
        mLuciqLogger.e(
          'Screen loading monitoring is disabled, skipping starting screen loading monitoring for screen: $screenName.\n'
          'Please refer to the documentation for how to enable screen loading monitoring on your app: https://docs.luciq.ai/docs/flutter-apm-screen-loading#disablingenabling-screen-loading-tracking '
          "If Screen Loading is enabled but you're still seeing this message, please reach out to support.",
          tag: APM.tag,
        ),
      ).called(1);
    });

    test(
        '[startScreenLoadingTrace] with screen loading enabled on Android should do nothing',
        () async {
      ScreenLoadingManager.setInstance(mScreenLoadingManager);
      when(FlagsConfig.screenLoading.isEnabled())
          .thenAnswer((_) async => false);
      when(LCQBuildInfo.I.isIOS).thenReturn(false);

      await ScreenLoadingManager.I.startScreenLoadingTrace(screenLoadingTrace);

      final actualUiTrace = ScreenLoadingManager.I.currentUiTrace;
      final actualScreenLoadingTrace =
          ScreenLoadingManager.I.currentScreenLoadingTrace;

      expect(
        actualUiTrace?.didStartScreenLoading,
        false,
      );
      expect(
        actualScreenLoadingTrace,
        null,
      );
      verify(mApmHost.isScreenLoadingEnabled()).called(1);
    });

    test(
        '[startScreenLoadingTrace] with screen loading enabled with different screen should log error',
        () async {
      const isSameScreen = false;
      when(FlagsConfig.screenLoading.isEnabled()).thenAnswer((_) async => true);
      when(LCQBuildInfo.I.isIOS).thenReturn(false);
      when(
        RouteMatcher.I.match(
          routePath: screenName,
          actualPath: screenName,
        ),
      ).thenReturn(isSameScreen);

      await ScreenLoadingManager.I.startScreenLoadingTrace(screenLoadingTrace);

      final actualUiTrace = ScreenLoadingManager.I.currentUiTrace;
      final actualScreenLoadingTrace =
          ScreenLoadingManager.I.currentScreenLoadingTrace;

      expect(
        actualUiTrace?.didStartScreenLoading,
        false,
      );
      expect(
        actualScreenLoadingTrace,
        null,
      );
      verify(
        mLuciqLogger.d(
          argThat(contains('failed to start screen loading trace')),
          tag: APM.tag,
        ),
      ).called(1);
    });

    test(
        '[startScreenLoadingTrace] with screen loading enabled should start a new UI Trace',
        () async {
      const isSameScreen = true;
      mScreenLoadingManager = ScreenLoadingManagerNoResets.init();
      when(FlagsConfig.screenLoading.isEnabled()).thenAnswer((_) async => true);
      when(LCQBuildInfo.I.isIOS).thenReturn(false);
      when(mDateTime.now()).thenReturn(time);
      when(
        RouteMatcher.I.match(
          routePath: screenName,
          actualPath: screenName,
        ),
      ).thenReturn(isSameScreen);

      await ScreenLoadingManager.I.startScreenLoadingTrace(screenLoadingTrace);

      final actualUiTrace = ScreenLoadingManager.I.currentUiTrace;

      expect(
        actualUiTrace?.screenName,
        screenName,
      );
      expect(
        actualUiTrace?.traceId,
        traceId,
      );
      expect(
        actualUiTrace?.didStartScreenLoading,
        true,
      );
      verify(
        mLuciqLogger.d(
          argThat(contains('Starting screen loading trace')),
          tag: APM.tag,
        ),
      ).called(1);
    });

    test(
        '[startScreenLoadingTrace] should start screen loading trace when screen loading trace matches UI trace matching screen name',
        () async {
      const isSameScreen = true;
      const matchingScreenName = 'matching_screen_name';
      mScreenLoadingManager = ScreenLoadingManagerNoResets.init();
      when(FlagsConfig.screenLoading.isEnabled()).thenAnswer((_) async => true);
      when(LCQBuildInfo.I.isIOS).thenReturn(false);
      when(mDateTime.now()).thenReturn(time);

      // Match on matching screen name
      when(
        RouteMatcher.I.match(
          routePath: screenName,
          actualPath: matchingScreenName,
        ),
      ).thenReturn(isSameScreen);

      when(
        RouteMatcher.I.match(
          routePath: screenName,
          actualPath: screenName,
        ),
      ).thenReturn(!isSameScreen);

      ScreenLoadingManager.I.currentUiTrace = uiTrace.copyWith(
        matchingScreenName: matchingScreenName,
      );

      await ScreenLoadingManager.I.startScreenLoadingTrace(screenLoadingTrace);

      final actualUiTrace = ScreenLoadingManager.I.currentUiTrace!;

      expect(
        ScreenLoadingManager.I.currentScreenLoadingTrace,
        equals(screenLoadingTrace),
      );
      expect(
        actualUiTrace.didStartScreenLoading,
        isTrue,
      );
    });

    test(
        '[startScreenLoadingTrace] should not start screen loading trace when screen loading trace does not matches UI trace matching screen name',
        () async {
      const isSameScreen = false;
      const matchingScreenName = 'matching_screen_name';
      mScreenLoadingManager = ScreenLoadingManagerNoResets.init();
      when(FlagsConfig.screenLoading.isEnabled()).thenAnswer((_) async => true);
      when(LCQBuildInfo.I.isIOS).thenReturn(false);
      when(mDateTime.now()).thenReturn(time);

      // Don't match on matching screen name
      when(
        RouteMatcher.I.match(
          routePath: screenName,
          actualPath: matchingScreenName,
        ),
      ).thenReturn(isSameScreen);

      when(
        RouteMatcher.I.match(
          routePath: screenName,
          actualPath: screenName,
        ),
      ).thenReturn(!isSameScreen);

      ScreenLoadingManager.I.currentUiTrace = uiTrace.copyWith(
        matchingScreenName: matchingScreenName,
      );

      await ScreenLoadingManager.I.startScreenLoadingTrace(screenLoadingTrace);

      final actualUiTrace = ScreenLoadingManager.I.currentUiTrace!;

      expect(
        ScreenLoadingManager.I.currentScreenLoadingTrace,
        isNull,
      );
      expect(
        actualUiTrace.didStartScreenLoading,
        isFalse,
      );
    });
  });

  group('reportScreenLoading tests', () {
    late DateTime time;
    late UiTrace uiTrace;
    late int traceId;
    late ScreenLoadingTrace screenLoadingTrace;
    int? duration;

    setUp(() {
      time = DateTime.now();
      traceId = time.millisecondsSinceEpoch;
      uiTrace = UiTrace(screenName: screenName, traceId: traceId);
      uiTrace.validationCompleter.complete(true);
      mScreenLoadingManager.currentUiTrace = uiTrace;
      when(mDateTime.now()).thenReturn(time);
      screenLoadingTrace = ScreenLoadingTrace(
        screenName,
        startTimeInMicroseconds: time.microsecondsSinceEpoch,
        startMonotonicTimeInMicroseconds: time.microsecondsSinceEpoch,
      );
      mScreenLoadingManager.currentUiTrace?.didStartScreenLoading = true;
      mScreenLoadingManager.currentScreenLoadingTrace = screenLoadingTrace;
      mScreenLoadingManager.currentUiTrace = uiTrace;
    });

    test('[reportScreenLoading] with SDK not build should Log error', () async {
      when(mLuciqHost.isBuilt()).thenAnswer((_) async => false);

      await ScreenLoadingManager.I.reportScreenLoading(screenLoadingTrace);

      final actualUiTrace = ScreenLoadingManager.I.currentUiTrace;
      final actualScreenLoadingTrace =
          ScreenLoadingManager.I.currentScreenLoadingTrace;

      expect(
        actualUiTrace?.didReportScreenLoading,
        false,
      );
      expect(
        actualScreenLoadingTrace?.startTimeInMicroseconds,
        time.microsecondsSinceEpoch,
      );
      expect(
        actualScreenLoadingTrace?.endTimeInMicroseconds,
        null,
      );
      verify(
        mLuciqLogger.e(
          'Luciq API {APM.LuciqCaptureScreenLoading} was called before the SDK is built. To build it, first by following the instructions at this link:\n'
          'https://docs.luciq.ai/reference#showing-and-manipulating-the-invocation',
          tag: APM.tag,
        ),
      ).called(1);
      verifyNever(mApmHost.reportScreenLoadingCP(any, any, any));
    });

    test(
        '[reportScreenLoading] with screen loading disabled on iOS Platform should log error',
        () async {
      when(FlagsConfig.screenLoading.isEnabled())
          .thenAnswer((_) async => false);
      when(LCQBuildInfo.I.isIOS).thenReturn(true);

      await ScreenLoadingManager.I.reportScreenLoading(screenLoadingTrace);

      final actualUiTrace = ScreenLoadingManager.I.currentUiTrace;
      final actualScreenLoadingTrace =
          ScreenLoadingManager.I.currentScreenLoadingTrace;

      expect(
        actualUiTrace?.didReportScreenLoading,
        false,
      );
      expect(
        actualScreenLoadingTrace?.startTimeInMicroseconds,
        time.microsecondsSinceEpoch,
      );
      expect(
        actualScreenLoadingTrace?.endTimeInMicroseconds,
        null,
      );
      verify(
        mLuciqLogger.e(
          'Screen loading monitoring is disabled, skipping reporting screen loading time for screen: $screenName.\n'
          'Please refer to the documentation for how to enable screen loading monitoring on your app: https://docs.luciq.ai/docs/flutter-apm-screen-loading#disablingenabling-screen-loading-tracking '
          "If Screen Loading is enabled but you're still seeing this message, please reach out to support.",
          tag: APM.tag,
        ),
      ).called(1);
      verifyNever(mApmHost.reportScreenLoadingCP(any, any, any));
    });

    test(
        '[reportScreenLoading] with screen loading enabled on Android Platform should do nothing',
        () async {
      mScreenLoadingManager = ScreenLoadingManagerNoResets.init();
      when(FlagsConfig.screenLoading.isEnabled())
          .thenAnswer((_) async => false);
      when(LCQBuildInfo.I.isIOS).thenReturn(false);

      await ScreenLoadingManager.I.reportScreenLoading(
        screenLoadingTrace,
      );

      final actualUiTrace = ScreenLoadingManager.I.currentUiTrace;
      final actualScreenLoadingTrace =
          ScreenLoadingManager.I.currentScreenLoadingTrace;

      expect(
        actualUiTrace?.didReportScreenLoading,
        false,
      );
      expect(
        actualScreenLoadingTrace?.startTimeInMicroseconds,
        time.microsecondsSinceEpoch,
      );
      expect(
        actualScreenLoadingTrace?.endTimeInMicroseconds,
        null,
      );
      verifyNever(mApmHost.reportScreenLoadingCP(any, any, any));
    });

    test(
        '[reportScreenLoading] with screen loading enabled with different screen should log error',
        () async {
      const isSameScreen = false;
      when(FlagsConfig.screenLoading.isEnabled()).thenAnswer((_) async => true);
      when(LCQBuildInfo.I.isIOS).thenReturn(false);
      when(
        RouteMatcher.I.match(
          routePath: screenName,
          actualPath: screenName,
        ),
      ).thenReturn(isSameScreen);

      final differentTrace = ScreenLoadingTrace(
        'different screenName',
        startTimeInMicroseconds: 2500,
        startMonotonicTimeInMicroseconds: 2500,
      );

      await ScreenLoadingManager.I.reportScreenLoading(
        differentTrace,
      );

      final actualUiTrace = ScreenLoadingManager.I.currentUiTrace;
      final actualScreenLoadingTrace =
          ScreenLoadingManager.I.currentScreenLoadingTrace;

      expect(
        actualUiTrace?.didReportScreenLoading,
        false,
      );
      expect(
        actualScreenLoadingTrace?.startTimeInMicroseconds,
        time.microsecondsSinceEpoch,
      );
      expect(
        actualScreenLoadingTrace?.startTimeInMicroseconds,
        time.microsecondsSinceEpoch,
      );
      verifyNever(mApmHost.reportScreenLoadingCP(any, any, any));
      verify(
        mLuciqLogger.e(
          "Screen Loading trace dropped as the trace isn't from the current screen, or another trace was reported before the current one. — $differentTrace",
          tag: APM.tag,
        ),
      );
    });

    test(
        '[reportScreenLoading] with screen loading enabled and a previously reported screen loading trace should log error',
        () async {
      mScreenLoadingManager.currentUiTrace?.didReportScreenLoading = true;
      const isSameScreen = true;
      when(FlagsConfig.screenLoading.isEnabled()).thenAnswer((_) async => true);
      when(LCQBuildInfo.I.isIOS).thenReturn(false);
      when(
        RouteMatcher.I.match(
          routePath: screenName,
          actualPath: screenName,
        ),
      ).thenReturn(isSameScreen);

      await ScreenLoadingManager.I.reportScreenLoading(
        screenLoadingTrace,
      );

      final actualScreenLoadingTrace =
          ScreenLoadingManager.I.currentScreenLoadingTrace;

      expect(
        actualScreenLoadingTrace?.startTimeInMicroseconds,
        time.microsecondsSinceEpoch,
      );

      verifyNever(mApmHost.reportScreenLoadingCP(any, any, any));
      verify(
        mLuciqLogger.e(
          "Screen Loading trace dropped as the trace isn't from the current screen, or another trace was reported before the current one. — $screenLoadingTrace",
          tag: APM.tag,
        ),
      );
    });

    test(
        '[reportScreenLoading] with screen loading enabled and an invalid screenLoadingTrace should log error',
        () async {
      const isSameScreen = true;
      when(FlagsConfig.screenLoading.isEnabled()).thenAnswer((_) async => true);
      when(LCQBuildInfo.I.isIOS).thenReturn(false);
      when(
        mRouteMatcher.match(
          routePath: anyNamed('routePath'),
          actualPath: anyNamed('actualPath'),
        ),
      ).thenReturn(isSameScreen);
      const ScreenLoadingTrace? expectedScreenLoadingTrace = null;

      await ScreenLoadingManager.I.reportScreenLoading(
        expectedScreenLoadingTrace,
      );

      final actualUiTrace = ScreenLoadingManager.I.currentUiTrace;
      final actualScreenLoadingTrace =
          ScreenLoadingManager.I.currentScreenLoadingTrace;

      verifyNever(mApmHost.reportScreenLoadingCP(any, any, any));
      expect(
        actualUiTrace?.didReportScreenLoading,
        false,
      );
      expect(
        actualScreenLoadingTrace?.endTimeInMicroseconds,
        null,
      );
      verify(
        mLuciqLogger.e(
          "Screen Loading trace dropped as the trace isn't from the current screen, or another trace was reported before the current one. — $expectedScreenLoadingTrace",
          tag: APM.tag,
        ),
      );
    });

    test(
        '[reportScreenLoading] with screen loading enabled and a valid trace should report it',
        () async {
      duration = 1000;
      final endTime = time.add(Duration(microseconds: duration ?? 0));
      const isSameScreen = true;
      when(FlagsConfig.screenLoading.isEnabled()).thenAnswer((_) async => true);
      when(LCQBuildInfo.I.isIOS).thenReturn(false);
      when(
        RouteMatcher.I.match(
          routePath: screenName,
          actualPath: screenName,
        ),
      ).thenReturn(isSameScreen);
      screenLoadingTrace.endTimeInMicroseconds = endTime.microsecondsSinceEpoch;
      screenLoadingTrace.duration = duration;

      await ScreenLoadingManager.I.reportScreenLoading(
        screenLoadingTrace,
      );

      final actualUiTrace = ScreenLoadingManager.I.currentUiTrace;
      final actualScreenLoadingTrace =
          ScreenLoadingManager.I.currentScreenLoadingTrace;

      expect(
        actualUiTrace?.didReportScreenLoading,
        true,
      );
      expect(
        actualScreenLoadingTrace?.endTimeInMicroseconds,
        screenLoadingTrace.endTimeInMicroseconds,
      );
      expect(
        actualScreenLoadingTrace?.duration,
        screenLoadingTrace.duration,
      );
      verify(
        mApmHost.reportScreenLoadingCP(
          time.microsecondsSinceEpoch,
          duration,
          time.millisecondsSinceEpoch,
        ),
      ).called(1);
      verify(
        mLuciqLogger.d(
          argThat(contains('Reporting screen loading trace')),
          tag: APM.tag,
        ),
      );
    });
  });

  group('endScreenLoading tests', () {
    late DateTime time;
    late UiTrace uiTrace;
    late int traceId;
    late ScreenLoadingTrace screenLoadingTrace;
    late DateTime endTime;
    int? duration;
    late int extendedMonotonic;

    setUp(() {
      time = DateTime.now();
      traceId = time.millisecondsSinceEpoch;
      uiTrace = UiTrace(screenName: screenName, traceId: traceId);
      uiTrace.validationCompleter.complete(true);
      duration = 1000;
      extendedMonotonic = 500;
      endTime = time.add(Duration(microseconds: duration ?? 0));
      mScreenLoadingManager.currentUiTrace = uiTrace;
      when(mDateTime.now()).thenReturn(time);
      when(mLuciqMonotonicClock.now).thenReturn(extendedMonotonic);
      screenLoadingTrace = ScreenLoadingTrace(
        screenName,
        startTimeInMicroseconds: time.microsecondsSinceEpoch,
        startMonotonicTimeInMicroseconds: time.microsecondsSinceEpoch,
      );
      screenLoadingTrace.endTimeInMicroseconds = endTime.microsecondsSinceEpoch;
      screenLoadingTrace.duration = duration;
      mScreenLoadingManager.currentUiTrace?.didStartScreenLoading = true;
      mScreenLoadingManager.currentUiTrace?.didReportScreenLoading = true;
      mScreenLoadingManager.currentUiTrace = uiTrace;
      mScreenLoadingManager.currentScreenLoadingTrace = screenLoadingTrace;
    });

    test('[endScreenLoading] with SDK not build should Log error', () async {
      when(mLuciqHost.isBuilt()).thenAnswer((_) async => false);

      await ScreenLoadingManager.I.endScreenLoading();

      final actualUiTrace = ScreenLoadingManager.I.currentUiTrace;

      expect(
        actualUiTrace?.didExtendScreenLoading,
        false,
      );
      verify(
        mLuciqLogger.e(
          'Luciq API {endScreenLoading} was called before the SDK is built. To build it, first by following the instructions at this link:\n'
          'https://docs.luciq.ai/reference#showing-and-manipulating-the-invocation',
          tag: APM.tag,
        ),
      ).called(1);
      verifyNever(mApmHost.endScreenLoadingCP(any, any));
    });

    test(
        '[endScreenLoading] with screen loading disabled on iOS Platform should log error',
        () async {
      when(FlagsConfig.screenLoading.isEnabled())
          .thenAnswer((_) async => false);
      when(LCQBuildInfo.I.isIOS).thenReturn(true);

      await ScreenLoadingManager.I.endScreenLoading();

      final actualUiTrace = ScreenLoadingManager.I.currentUiTrace;

      expect(
        actualUiTrace?.didExtendScreenLoading,
        false,
      );
      verify(
        mLuciqLogger.e(
          'Screen loading monitoring is disabled, skipping ending screen loading monitoring with APM.endScreenLoading().\n'
          'Please refer to the documentation for how to enable screen loading monitoring in your app: https://docs.luciq.ai/docs/flutter-apm-screen-loading#disablingenabling-screen-loading-tracking '
          "If Screen Loading is enabled but you're still seeing this message, please reach out to support.",
          tag: APM.tag,
        ),
      ).called(1);
      verifyNever(mApmHost.endScreenLoadingCP(any, any));
    });

    test(
        '[endScreenLoading] with screen loading enabled on Android Platform should do nothing',
        () async {
      when(FlagsConfig.screenLoading.isEnabled())
          .thenAnswer((_) async => false);
      when(LCQBuildInfo.I.isIOS).thenReturn(false);

      await ScreenLoadingManager.I.endScreenLoading();

      final actualUiTrace = ScreenLoadingManager.I.currentUiTrace;

      expect(
        actualUiTrace?.didExtendScreenLoading,
        false,
      );
      verifyNever(mApmHost.endScreenLoadingCP(any, any));
    });

    test('[endScreenLoading] with a previously extended trace should log error',
        () async {
      uiTrace.didExtendScreenLoading = true;
      when(FlagsConfig.screenLoading.isEnabled()).thenAnswer((_) async => true);
      when(FlagsConfig.endScreenLoading.isEnabled())
          .thenAnswer((_) async => true);
      when(LCQBuildInfo.I.isIOS).thenReturn(false);

      await ScreenLoadingManager.I.endScreenLoading();

      verify(
        mLuciqLogger.e(
          'endScreenLoading has already been called for the current screen visit. Multiple calls to this API are not allowed during a single screen visit, only the first call will be considered.',
          tag: APM.tag,
        ),
      );
      verifyNever(mApmHost.endScreenLoadingCP(any, any));
    });

    test('[endScreenLoading] with no active screen loading should log error',
        () async {
      uiTrace.didStartScreenLoading = false;
      mScreenLoadingManager.currentScreenLoadingTrace = null;
      when(FlagsConfig.screenLoading.isEnabled()).thenAnswer((_) async => true);
      when(FlagsConfig.endScreenLoading.isEnabled())
          .thenAnswer((_) async => true);
      when(LCQBuildInfo.I.isIOS).thenReturn(false);

      await ScreenLoadingManager.I.endScreenLoading();

      final actualUiTrace = ScreenLoadingManager.I.currentUiTrace;
      expect(
        actualUiTrace?.didExtendScreenLoading,
        false,
      );
      verify(
        mLuciqLogger.e(
          argThat(contains("endScreenLoading wasn")),
          tag: APM.tag,
        ),
      );
      verifyNever(mApmHost.endScreenLoadingCP(any, any));
    });

    test(
        '[endScreenLoading] with prematurely ended screen loading should log error and End screen loading',
        () async {
      screenLoadingTrace = ScreenLoadingTrace(
        screenName,
        startTimeInMicroseconds: time.microsecondsSinceEpoch,
        startMonotonicTimeInMicroseconds: time.microsecondsSinceEpoch,
      );
      const prematureDuration = 0;
      mScreenLoadingManager.currentScreenLoadingTrace = screenLoadingTrace;
      when(FlagsConfig.screenLoading.isEnabled()).thenAnswer((_) async => true);
      when(FlagsConfig.endScreenLoading.isEnabled())
          .thenAnswer((_) async => true);
      when(LCQBuildInfo.I.isIOS).thenReturn(false);

      await ScreenLoadingManager.I.endScreenLoading();

      final actualUiTrace = ScreenLoadingManager.I.currentUiTrace;

      expect(
        actualUiTrace?.didExtendScreenLoading,
        true,
      );
      verify(
        mLuciqLogger.e(
          'endScreenLoading was called too early in the Screen Loading cycle. Please make sure to call the API after the screen is done loading.',
          tag: APM.tag,
        ),
      );
      verify(mApmHost.endScreenLoadingCP(prematureDuration, uiTrace.traceId))
          .called(1);
    });

    test('[endScreenLoading] should End screen loading', () async {
      when(FlagsConfig.screenLoading.isEnabled()).thenAnswer((_) async => true);
      when(FlagsConfig.endScreenLoading.isEnabled())
          .thenAnswer((_) async => true);
      when(LCQBuildInfo.I.isIOS).thenReturn(false);
      when(mDateTime.now()).thenReturn(time);
      const startMonotonicTime = 250;
      mScreenLoadingManager.currentScreenLoadingTrace
          ?.startMonotonicTimeInMicroseconds = startMonotonicTime;

      await ScreenLoadingManager.I.endScreenLoading();

      final actualUiTrace = ScreenLoadingManager.I.currentUiTrace;

      final extendedDuration = extendedMonotonic - startMonotonicTime;
      final extendedEndTimeInMicroseconds =
          time.microsecondsSinceEpoch + extendedDuration;

      expect(
        actualUiTrace?.didStartScreenLoading,
        true,
      );
      expect(
        actualUiTrace?.didReportScreenLoading,
        true,
      );
      expect(
        actualUiTrace?.didExtendScreenLoading,
        true,
      );
      verify(mApmHost.isScreenLoadingEnabled()).called(1);
      verify(
        mApmHost.endScreenLoadingCP(
          extendedEndTimeInMicroseconds,
          uiTrace.traceId,
        ),
      ).called(1);
    });
  });

  group('sanitize screen name tests', () {
    test('screen name equals to [/] should be replaced bu [ROOT_PAGE]', () {
      const screenName = '/';
      final sanitizedScreenName =
          ScreenLoadingManager.I.sanitizeScreenName(screenName);
      expect(sanitizedScreenName, "ROOT_PAGE");
    });

    test('screen name prefixed with [/] should omit [/] char', () {
      const screenName = '/Home';
      final sanitizedScreenName =
          ScreenLoadingManager.I.sanitizeScreenName(screenName);
      expect(sanitizedScreenName, "Home");
    });

    test('screen name suffixed with [/] should omit [/] char', () {
      const screenName = '/Home';
      final sanitizedScreenName =
          ScreenLoadingManager.I.sanitizeScreenName(screenName);
      expect(sanitizedScreenName, "Home");
    });

    test('screen name without [/] on edges should return the same ', () {
      const screenName = 'Home';
      final sanitizedScreenName =
          ScreenLoadingManager.I.sanitizeScreenName(screenName);
      expect(sanitizedScreenName, "Home");
    });
    test(
        'screen name prefixed with [//] and suffixed with [/] should omit first and last[/] char',
        () {
      const screenName = '//Home/';
      final sanitizedScreenName =
          ScreenLoadingManager.I.sanitizeScreenName(screenName);
      expect(sanitizedScreenName, "/Home");
    });
  });

  group('wrapRoutes', () {
    setUp(() {
      mockBuildContext = MockBuildContext();
      mockScreen = MockWidget();
    });
    test('wraps routes with LuciqCaptureScreenLoading widgets', () {
      // Create a map of routes
      final routes = {
        '/home': (context) => mockScreen,
        '/settings': (context) => mockScreen,
      };

      // Wrap the routes
      final wrappedRoutes = ScreenLoadingManager.wrapRoutes(routes);

      // Verify that the routes are wrapped correctly
      expect(wrappedRoutes, isA<Map<String, WidgetBuilder>>());
      expect(wrappedRoutes.length, equals(routes.length));
      for (final route in wrappedRoutes.entries) {
        expect(
          route.value(mockBuildContext),
          isA<LuciqCaptureScreenLoading>(),
        );
      }
    });

    test('does not wrap excluded routes', () {
      // Create a map of routes
      final routes = {
        '/home': (context) => mockScreen,
        '/settings': (context) => mockScreen,
      };

      // Exclude the '/home' route
      final wrappedRoutes =
          ScreenLoadingManager.wrapRoutes(routes, exclude: ['/home']);

      // Verify that the '/home' route is not wrapped
      expect(wrappedRoutes['/home'], equals(routes['/home']));

      // Verify that the '/settings' route is wrapped
      expect(
        wrappedRoutes['/settings']?.call(mockBuildContext),
        isA<LuciqCaptureScreenLoading>(),
      );
    });

    test('handles empty routes map', () {
      // Create an empty map of routes
      final routes = <String, WidgetBuilder>{};

      // Wrap the routes
      final wrappedRoutes = ScreenLoadingManager.wrapRoutes(routes);

      // Verify that the returned map is empty
      expect(wrappedRoutes, isEmpty);
    });

    test('handles null routes map', () {
      // Create a null map of routes
      Map<String, WidgetBuilder>? routes;

      // Wrap the routes
      final wrappedRoutes = ScreenLoadingManager.wrapRoutes(routes ?? {});

      // Verify that the returned map is empty
      expect(wrappedRoutes, isEmpty);
    });
  });

  group('prepareUiTrace tests', () {
    late DateTime time;
    setUp(() {
      time = DateTime(2024, 1, 1, 12);
      when(mDateTime.now()).thenReturn(time);
      when(mLuciqHost.isBuilt()).thenAnswer((_) async => true);
      when(mApmHost.isAutoUiTraceEnabled()).thenAnswer((_) async => true);
      when(mApmHost.startCpUiTrace(any, any, any))
          .thenAnswer((_) async => {});
    });

    test(
        '[prepareUiTrace] should create a UiTrace with correct screenName and traceId',
        () async {
      mScreenLoadingManager.prepareUiTrace(screenName);

      final uiTrace = mScreenLoadingManager.currentUiTrace;
      expect(uiTrace, isNotNull);
      expect(uiTrace?.screenName, screenName);
      expect(uiTrace?.traceId, time.millisecondsSinceEpoch);

      await uiTrace?.whenValidated;

      verify(mApmHost.startCpUiTrace(
        screenName,
        time.microsecondsSinceEpoch,
        time.millisecondsSinceEpoch,
      ),).called(1);
    });

    test(
        '[prepareUiTrace] should sanitize screen name with leading slash',
        () async {
      mScreenLoadingManager.prepareUiTrace('/Home');

      final uiTrace = mScreenLoadingManager.currentUiTrace;
      expect(uiTrace, isNotNull);
      expect(uiTrace?.screenName, 'Home');
    });

    test(
        '[prepareUiTrace] should use matchingScreenName when provided',
        () async {
      const matchingName = 'matchingScreen';
      when(RouteMatcher.I.match(
        routePath: anyNamed('routePath'),
        actualPath: anyNamed('actualPath'),
      ),).thenReturn(true);

      mScreenLoadingManager.prepareUiTrace(screenName, matchingName);

      final uiTrace = mScreenLoadingManager.currentUiTrace;
      expect(uiTrace, isNotNull);
      expect(uiTrace?.screenName, screenName);
      expect(uiTrace?.matches(screenName), isTrue);
    });

    test(
        '[prepareUiTrace] should discard UiTrace when SDK is not built',
        () async {
      when(mLuciqHost.isBuilt()).thenAnswer((_) async => false);

      mScreenLoadingManager.prepareUiTrace(screenName);

      final uiTrace = mScreenLoadingManager.currentUiTrace;
      expect(uiTrace, isNotNull);

      final isValid = await uiTrace?.whenValidated;
      expect(isValid, isFalse);

      expect(mScreenLoadingManager.currentUiTrace, isNull);

      verifyNever(mApmHost.startCpUiTrace(any, any, any));
    });

    test(
        '[prepareUiTrace] should discard UiTrace when auto UI trace is disabled',
        () async {
      when(mApmHost.isAutoUiTraceEnabled()).thenAnswer((_) async => false);

      mScreenLoadingManager.prepareUiTrace(screenName);

      final uiTrace = mScreenLoadingManager.currentUiTrace;
      expect(uiTrace, isNotNull);

      final isValid = await uiTrace?.whenValidated;
      expect(isValid, isFalse);

      expect(mScreenLoadingManager.currentUiTrace, isNull);

      verifyNever(mApmHost.startCpUiTrace(any, any, any));
      verify(mLuciqLogger.e(
        argThat(contains('Auto UI trace is disabled')),
        tag: APM.tag,
      ),).called(1);
    });

    test(
        '[prepareUiTrace] should reset didStartScreenLoading on the previous UiTrace',
        () async {
      final oldUiTrace = UiTrace(screenName: 'oldScreen', traceId: 1);
      oldUiTrace.didStartScreenLoading = true;
      mScreenLoadingManager.currentUiTrace = oldUiTrace;

      mScreenLoadingManager.prepareUiTrace(screenName);

      expect(oldUiTrace.didStartScreenLoading, isFalse);
    });

    test(
        '[prepareUiTrace] should handle exception gracefully and log error',
        () async {
      when(mDateTime.now()).thenThrow(Exception('test exception'));

      mScreenLoadingManager.prepareUiTrace(screenName);

      verify(mLuciqLogger.e(
        argThat(contains('test exception')),
        tag: APM.tag,
      ),).called(1);
    });
  });

  group('reportManualScreenLoading tests', () {
    const testScreenName = 'manualScreen';
    const startTime = 1000;
    const testDuration = 500;

    setUp(() {
      when(mLuciqHost.isBuilt()).thenAnswer((_) async => true);
    });

    test(
        '[reportManualScreenLoading] with SDK not built should log error',
        () async {
      when(mLuciqHost.isBuilt()).thenAnswer((_) async => false);

      await ScreenLoadingManager.I.reportManualScreenLoading(
        testScreenName,
        startTime,
        testDuration,
      );

      verify(mLuciqLogger.e(
        argThat(contains(
            'Luciq SDK is not built, skipping reporting manual screen loading',),),
        tag: APM.tag,
      ),).called(1);
      verifyNever(mApmHost.reportManualScreenLoadingCP(any, any, any));
    });

    test(
        '[reportManualScreenLoading] with screen loading disabled should log error',
        () async {
      when(FlagsConfig.screenLoading.isEnabled())
          .thenAnswer((_) async => false);

      await ScreenLoadingManager.I.reportManualScreenLoading(
        testScreenName,
        startTime,
        testDuration,
      );

      verify(mLuciqLogger.e(
        argThat(contains(
            'Screen loading monitoring is disabled, skipping reporting manual screen loading',),),
        tag: APM.tag,
      ),).called(1);
      verifyNever(mApmHost.reportManualScreenLoadingCP(any, any, any));
    });

    test(
        '[reportManualScreenLoading] should report to native when everything is enabled',
        () async {
      when(FlagsConfig.screenLoading.isEnabled())
          .thenAnswer((_) async => true);
      when(mApmHost.reportManualScreenLoadingCP(any, any, any))
          .thenAnswer((_) async => {});

      await ScreenLoadingManager.I.reportManualScreenLoading(
        testScreenName,
        startTime,
        testDuration,
      );

      verify(mApmHost.reportManualScreenLoadingCP(
        testScreenName,
        startTime,
        testDuration,
      ),).called(1);
    });
  });

  group('reportScreenLoading - UI trace validation tests', () {
    late DateTime time;
    late UiTrace uiTrace;
    late int traceId;
    late ScreenLoadingTrace screenLoadingTrace;

    setUp(() {
      time = DateTime.now();
      traceId = time.millisecondsSinceEpoch;
      uiTrace = UiTrace(screenName: screenName, traceId: traceId);
      mScreenLoadingManager.currentUiTrace = uiTrace;
      when(mDateTime.now()).thenReturn(time);
      screenLoadingTrace = ScreenLoadingTrace(
        screenName,
        startTimeInMicroseconds: time.microsecondsSinceEpoch,
        startMonotonicTimeInMicroseconds: time.microsecondsSinceEpoch,
      );
      screenLoadingTrace.duration = 1000;
      screenLoadingTrace.endTimeInMicroseconds =
          time.microsecondsSinceEpoch + 1000;
      mScreenLoadingManager.currentScreenLoadingTrace = screenLoadingTrace;
      when(mLuciqHost.isBuilt()).thenAnswer((_) async => true);
      when(FlagsConfig.screenLoading.isEnabled())
          .thenAnswer((_) async => true);
    });

    test(
        '[reportScreenLoading] should drop trace when UI trace validation completes with false',
        () async {
      uiTrace.validationCompleter.complete(false);

      await ScreenLoadingManager.I.reportScreenLoading(screenLoadingTrace);

      expect(mScreenLoadingManager.currentUiTrace?.didReportScreenLoading,
          isFalse,);
      expect(mScreenLoadingManager.currentScreenLoadingTrace, isNull);
      verifyNever(mApmHost.reportScreenLoadingCP(any, any, any));
      verify(mLuciqLogger.d(
        argThat(contains(
            'Dropping screen loading trace — UI trace validation failed',),),
        tag: APM.tag,
      ),).called(1);
    });

    test(
        '[reportScreenLoading] should drop trace when UI trace validation times out',
        () async {
      // Never complete the validation completer — triggers timeout
      await ScreenLoadingManager.I.reportScreenLoading(screenLoadingTrace);

      expect(mScreenLoadingManager.currentUiTrace?.didReportScreenLoading,
          isFalse,);
      expect(mScreenLoadingManager.currentScreenLoadingTrace, isNull);
      verifyNever(mApmHost.reportScreenLoadingCP(any, any, any));
      verify(mLuciqLogger.e(
        argThat(contains('UI trace validation timed out')),
        tag: APM.tag,
      ),).called(1);
    });
  });

  group('endScreenLoading - additional edge cases', () {
    late DateTime time;
    late UiTrace uiTrace;
    late int traceId;
    late ScreenLoadingTrace screenLoadingTrace;

    setUp(() {
      time = DateTime.now();
      traceId = time.millisecondsSinceEpoch;
      uiTrace = UiTrace(screenName: screenName, traceId: traceId);
      uiTrace.validationCompleter.complete(true);
      mScreenLoadingManager.currentUiTrace = uiTrace;
      when(mDateTime.now()).thenReturn(time);
      when(mLuciqMonotonicClock.now).thenReturn(500);
      screenLoadingTrace = ScreenLoadingTrace(
        screenName,
        startTimeInMicroseconds: time.microsecondsSinceEpoch,
        startMonotonicTimeInMicroseconds: time.microsecondsSinceEpoch,
      );
      screenLoadingTrace.endTimeInMicroseconds =
          time.microsecondsSinceEpoch + 1000;
      screenLoadingTrace.duration = 1000;
      mScreenLoadingManager.currentScreenLoadingTrace = screenLoadingTrace;
      when(mLuciqHost.isBuilt()).thenAnswer((_) async => true);
    });

    test(
        '[endScreenLoading] with endScreenLoading feature flag disabled should log error',
        () async {
      when(FlagsConfig.screenLoading.isEnabled())
          .thenAnswer((_) async => true);
      when(FlagsConfig.endScreenLoading.isEnabled())
          .thenAnswer((_) async => false);

      await ScreenLoadingManager.I.endScreenLoading();

      verify(mLuciqLogger.e(
        argThat(contains('End Screen loading API is disabled')),
        tag: APM.tag,
      ),).called(1);
      verifyNever(mApmHost.endScreenLoadingCP(any, any));
    });

    test(
        '[endScreenLoading] should drop when UI trace validation completes with false',
        () async {
      final invalidUiTrace =
          UiTrace(screenName: screenName, traceId: traceId);
      invalidUiTrace.validationCompleter.complete(false);
      mScreenLoadingManager.currentUiTrace = invalidUiTrace;

      when(FlagsConfig.screenLoading.isEnabled())
          .thenAnswer((_) async => true);
      when(FlagsConfig.endScreenLoading.isEnabled())
          .thenAnswer((_) async => true);

      await ScreenLoadingManager.I.endScreenLoading();

      expect(invalidUiTrace.didExtendScreenLoading, isFalse);
      verifyNever(mApmHost.endScreenLoadingCP(any, any));
      verify(mLuciqLogger.d(
        argThat(contains(
            'Dropping endScreenLoading — UI trace validation failed',),),
        tag: APM.tag,
      ),).called(1);
    });

    test(
        '[endScreenLoading] should drop when UI trace validation times out',
        () async {
      final pendingUiTrace =
          UiTrace(screenName: screenName, traceId: traceId);
      // Never complete the validation completer
      mScreenLoadingManager.currentUiTrace = pendingUiTrace;

      when(FlagsConfig.screenLoading.isEnabled())
          .thenAnswer((_) async => true);
      when(FlagsConfig.endScreenLoading.isEnabled())
          .thenAnswer((_) async => true);

      await ScreenLoadingManager.I.endScreenLoading();

      expect(pendingUiTrace.didExtendScreenLoading, isFalse);
      verifyNever(mApmHost.endScreenLoadingCP(any, any));
      verify(mLuciqLogger.e(
        argThat(
            contains('UI trace validation timed out'),),
        tag: APM.tag,
      ),).called(1);
    });
  });
}
