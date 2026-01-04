import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luciq_flutter/luciq_flutter.dart';
import 'package:luciq_flutter/src/generated/apm.api.g.dart';
import 'package:luciq_flutter/src/generated/luciq.api.g.dart';
import 'package:luciq_flutter/src/utils/custom_span/custom_span_manager.dart';
import 'package:luciq_flutter/src/utils/lcq_build_info.dart';
import 'package:luciq_flutter/src/utils/lcq_date_time.dart';
import 'package:luciq_flutter/src/utils/luciq_logger.dart';
import 'package:luciq_flutter/src/utils/luciq_montonic_clock.dart';
import 'package:luciq_flutter/src/utils/screen_rendering/luciq_screen_render_manager.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'apm_test.mocks.dart';

// Note: Detailed custom span tests are in custom_span_manager_test.dart
// APM tests here only verify the public API delegation

@GenerateMocks([
  ApmHostApi,
  LuciqHostApi,
  LCQDateTime,
  LCQBuildInfo,
  LuciqScreenRenderManager,
  LuciqLogger,
  LuciqMonotonicClock,
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();

  final mHost = MockApmHostApi();
  final mLuciqHost = MockLuciqHostApi();
  final mDateTime = MockLCQDateTime();
  final mBuildInfo = MockLCQBuildInfo();
  final mScreenRenderManager = MockLuciqScreenRenderManager();
  final mLuciqLogger = MockLuciqLogger();
  final mMonotonicClock = MockLuciqMonotonicClock();

  setUpAll(() {
    APM.$setHostApi(mHost);
    Luciq.$setHostApi(mLuciqHost);
    LCQDateTime.setInstance(mDateTime);
    LCQBuildInfo.setInstance(mBuildInfo);
    LuciqLogger.setInstance(mLuciqLogger);
    LuciqMonotonicClock.setInstance(mMonotonicClock);
  });

  test('[setEnabled] should call host method', () async {
    const enabled = true;

    await APM.setEnabled(enabled);

    verify(
      mHost.setEnabled(enabled),
    ).called(1);
  });

  test('[isEnabled] should call host method', () async {
    when(mHost.isEnabled()).thenAnswer((_) async => true);
    await APM.isEnabled();

    verify(
      mHost.isEnabled(),
    ).called(1);
  });

  test('[setScreenLoadingMonitoringEnabled] should call host method', () async {
    const enabled = true;

    await APM.setScreenLoadingEnabled(enabled);

    verify(
      mHost.setScreenLoadingEnabled(enabled),
    ).called(1);
  });

  test('[isScreenLoadingMonitoringEnabled] should call host method', () async {
    when(mHost.isScreenLoadingEnabled()).thenAnswer((_) async => true);
    await APM.isScreenLoadingEnabled();

    verify(
      mHost.isScreenLoadingEnabled(),
    ).called(1);
  });

  test('[setColdAppLaunchEnabled] should call host method', () async {
    const enabled = true;

    await APM.setColdAppLaunchEnabled(enabled);

    verify(
      mHost.setColdAppLaunchEnabled(enabled),
    ).called(1);
  });

  test('[setAutoUITraceEnabled] should call host method', () async {
    const enabled = true;

    await APM.setAutoUITraceEnabled(enabled);

    verify(
      mHost.setAutoUITraceEnabled(enabled),
    ).called(1);
  });

  test("[isAutoUiTraceEnabled] should call host method", () async {
    when(mHost.isAutoUiTraceEnabled()).thenAnswer((_) async => true);
    await APM.isAutoUiTraceEnabled();
    verify(mHost.isAutoUiTraceEnabled());
  });

  test('[startFlow] should call host method', () async {
    const flowName = "flow-name";
    await APM.startFlow(flowName);

    verify(
      mHost.startFlow(flowName),
    ).called(1);
    verifyNoMoreInteractions(mHost);
  });

  test('[setFlowAttribute] should call host method', () async {
    const flowName = "flow-name";
    const flowAttributeKey = 'attribute-key';
    const flowAttributeValue = 'attribute-value';

    await APM.setFlowAttribute(flowName, flowAttributeKey, flowAttributeValue);

    verify(
      mHost.setFlowAttribute(flowName, flowAttributeKey, flowAttributeValue),
    ).called(1);
    verifyNoMoreInteractions(mHost);
  });

  test('[endFlow] should call host method', () async {
    const flowName = "flow-name";

    await APM.endFlow(flowName);

    verify(
      mHost.endFlow(flowName),
    ).called(1);
    verifyNoMoreInteractions(mHost);
  });

  test('[startUITrace] should call host method', () async {
    const name = 'UI-trace';

    //disable the feature flag for screen render feature in order to skip its checking.
    when(mHost.isScreenRenderEnabled()).thenAnswer((_) async => false);

    await APM.startUITrace(name);

    verify(
      mHost.startUITrace(name),
    ).called(1);
  });

  test('[endUITrace] should call host method', () async {
    await APM.endUITrace();

    verify(
      mHost.endUITrace(),
    ).called(1);
  });

  test('[endAppLaunch] should call host method', () async {
    await APM.endAppLaunch();

    verify(
      mHost.endAppLaunch(),
    ).called(1);
  });

  test('[networkLogAndroid] should call host method', () async {
    final data = NetworkData(
      url: "https://httpbin.org/get",
      method: "GET",
      startTime: DateTime.now(),
    );

    when(mBuildInfo.isAndroid).thenReturn(true);

    await APM.networkLogAndroid(data);

    verify(
      mHost.networkLogAndroid(data.toJson()),
    ).called(1);
  });

  test('[startCpUiTrace] should call host method', () async {
    const screenName = 'screen-name';
    final microTimeStamp = DateTime.now().microsecondsSinceEpoch;
    final traceId = DateTime.now().millisecondsSinceEpoch;

    await APM.startCpUiTrace(screenName, microTimeStamp, traceId);

    verify(
      mHost.startCpUiTrace(screenName, microTimeStamp, traceId),
    ).called(1);
  });

  test('[reportScreenLoading] should call host method', () async {
    final startTimeStampMicro = DateTime.now().microsecondsSinceEpoch;
    final durationMicro = DateTime.now().microsecondsSinceEpoch;
    final uiTraceId = DateTime.now().millisecondsSinceEpoch;

    await APM.reportScreenLoadingCP(
      startTimeStampMicro,
      durationMicro,
      uiTraceId,
    );

    verify(
      mHost.reportScreenLoadingCP(
        startTimeStampMicro,
        durationMicro,
        uiTraceId,
      ),
    ).called(1);
  });

  test('[endScreenLoading] should call host method', () async {
    final timeStampMicro = DateTime.now().microsecondsSinceEpoch;
    final uiTraceId = DateTime.now().millisecondsSinceEpoch;

    await APM.endScreenLoadingCP(timeStampMicro, uiTraceId);

    verify(
      mHost.endScreenLoadingCP(timeStampMicro, uiTraceId),
    ).called(1);
  });

  test('[isSEndScreenLoadingEnabled] should call host method', () async {
    when(mHost.isEndScreenLoadingEnabled()).thenAnswer((_) async => true);
    await APM.isEndScreenLoadingEnabled();

    verify(
      mHost.isEndScreenLoadingEnabled(),
    ).called(1);
  });

  group("ScreenRender", () {
    setUp(() {
      LuciqScreenRenderManager.setInstance(mScreenRenderManager);
    });
    tearDown(() {
      reset(mScreenRenderManager);
      reset(mHost);
    });
    test("[isScreenRenderEnabled] should call host method", () async {
      when(mHost.isScreenRenderEnabled()).thenAnswer((_) async => true);
      await APM.isScreenRenderEnabled();
      verify(mHost.isScreenRenderEnabled());
    });

    test("[getDeviceRefreshRateAndTolerance] should call host method",
        () async {
      when(mHost.getDeviceRefreshRateAndTolerance()).thenAnswer(
        (_) async => [60.0, 10.0],
      );
      await APM.getDeviceRefreshRateAndTolerance();
      verify(mHost.getDeviceRefreshRateAndTolerance()).called(1);
    });

    test("[setScreenRenderingEnabled] should call host method", () async {
      const isEnabled = false;
      when(mScreenRenderManager.screenRenderEnabled).thenReturn(false);
      await APM.setScreenRenderingEnabled(isEnabled);
      verify(mHost.setScreenRenderEnabled(isEnabled)).called(1);
    });

    test("[setScreenRenderEnabled] should call host method when enabled",
        () async {
      const isEnabled = true;
      await APM.setScreenRenderingEnabled(isEnabled);
      verify(mHost.setScreenRenderEnabled(isEnabled)).called(1);
    });

    test("[setScreenRenderEnabled] should call host method when disabled",
        () async {
      const isEnabled = false;
      await APM.setScreenRenderingEnabled(isEnabled);
      verify(mHost.setScreenRenderEnabled(isEnabled)).called(1);
    });

    test(
        "[startUITrace] should start screen render collector with right params, if screen render feature is enabled",
        () async {
      when(mHost.isScreenRenderEnabled()).thenAnswer((_) async => true);

      const traceName = "traceNameTest";
      await APM.startUITrace(traceName);

      verify(mHost.startUITrace(traceName)).called(1);
      verify(mHost.isScreenRenderEnabled()).called(1);
      verify(
        mScreenRenderManager.startScreenRenderCollectorForTraceId(
          0,
          UiTraceType.custom,
        ),
      ).called(1);
    });

    test(
        "[startUITrace] should not start screen render collector, if screen render feature is disabled",
        () async {
      when(mHost.isScreenRenderEnabled()).thenAnswer((_) async => false);

      const traceName = "traceNameTest";
      await APM.startUITrace(traceName);

      verify(mHost.startUITrace(traceName)).called(1);
      verify(mHost.isScreenRenderEnabled()).called(1);
      verifyNever(
        mScreenRenderManager.startScreenRenderCollectorForTraceId(
          any,
          any,
        ),
      );
    });

    test(
        "[endUITrace] should stop screen render collector with, if screen render feature is enabled",
        () async {
      when(mHost.isScreenRenderEnabled()).thenAnswer((_) async => true);
      when(mHost.isAutoUiTraceEnabled()).thenAnswer((_) async => true);
      when(mScreenRenderManager.screenRenderEnabled).thenReturn(true);
      await APM.endUITrace();

      verify(
        mScreenRenderManager.endScreenRenderCollector(UiTraceType.custom),
      ).called(1);
      verifyNever(mHost.endUITrace());
    });

    test(
        "[endUITrace] should acts as normal and do nothing related to screen render, if screen render feature is disabled",
        () async {
      when(mHost.isScreenRenderEnabled()).thenAnswer((_) async => false);
      when(mScreenRenderManager.screenRenderEnabled).thenReturn(false);
      const traceName = "traceNameTest";
      await APM.startUITrace(traceName);
      await APM.endUITrace();

      verify(mHost.startUITrace(traceName)).called(1);
      verify(
        mHost.endUITrace(),
      ).called(1);
      verifyNever(
        mScreenRenderManager.endScreenRenderCollector(),
      );
    });
  });

  group('Custom Spans - APM Public API', () {
    late DateTime time;

    setUp(() {
      time = DateTime.now();
      when(mDateTime.now()).thenReturn(time);
      when(mMonotonicClock.now).thenReturn(1000000);
      // Reset mocks for Custom Spans tests
      reset(mLuciqHost);
      reset(mHost);
      reset(mLuciqLogger);
      // Clear active spans before each test
      CustomSpanManager.I.$clearActiveSpans();
    });

    test('startCustomSpan delegates to CustomSpanManager', () async {
      when(mLuciqHost.isBuilt()).thenAnswer((_) async => true);
      when(mHost.isEnabled()).thenAnswer((_) async => true);
      when(mHost.isCustomSpanEnabled()).thenAnswer((_) async => true);

      final span = await APM.startCustomSpan('Test Span');

      expect(span, isNotNull);
      expect(span!.name, 'Test Span');
      expect(CustomSpanManager.I.activeSpanCount, 1);
    });

    test('addCompletedCustomSpan delegates to CustomSpanManager', () async {
      when(mLuciqHost.isBuilt()).thenAnswer((_) async => true);
      when(mHost.isEnabled()).thenAnswer((_) async => true);
      when(mHost.isCustomSpanEnabled()).thenAnswer((_) async => true);
      final start = DateTime(2025, 1, 1, 10);
      final end = DateTime(2025, 1, 1, 10, 0, 1);

      await APM.addCompletedCustomSpan('Test Span', start, end);

      verify(mHost.syncCustomSpan(
        'Test Span',
        start.microsecondsSinceEpoch,
        end.microsecondsSinceEpoch,
      ),).called(1);
    });
  });
}
