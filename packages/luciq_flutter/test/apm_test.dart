import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luciq_flutter/luciq_flutter.dart';
import 'package:luciq_flutter/src/constants/strings.dart';
import 'package:luciq_flutter/src/generated/apm.api.g.dart';
import 'package:luciq_flutter/src/generated/luciq.api.g.dart';
import 'package:luciq_flutter/src/utils/lcq_build_info.dart';
import 'package:luciq_flutter/src/utils/lcq_date_time.dart';
import 'package:luciq_flutter/src/utils/luciq_logger.dart';
import 'package:luciq_flutter/src/utils/luciq_montonic_clock.dart';
import 'package:luciq_flutter/src/utils/screen_rendering/luciq_screen_render_manager.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'apm_test.mocks.dart';

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

  group('Custom Spans', () {
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
      APM.$clearActiveSpans();
    });

    group('startCustomSpan', () {
      test('creates span when enabled', () async {
        when(mLuciqHost.isBuilt()).thenAnswer((_) async => true);
        when(mHost.isEnabled()).thenAnswer((_) async => true);
        when(mHost.isCustomSpanEnabled()).thenAnswer((_) async => true);

        final span = await APM.startCustomSpan('Test Span');

        expect(span, isNotNull);
        expect(span!.name, 'Test Span');
      });

      test('returns null and logs error when SDK not initialized', () async {
        when(mLuciqHost.isBuilt()).thenAnswer((_) async => false);

        final span = await APM.startCustomSpan('Test Span');

        expect(span, isNull);
        verify(mLuciqLogger.e(
          LuciqStrings.customSpanSDKNotInitializedMessage,
          tag: APM.tag,
        )).called(1);
      });

      test('returns null and logs when APM disabled', () async {
        when(mLuciqHost.isBuilt()).thenAnswer((_) async => true);
        when(mHost.isEnabled()).thenAnswer((_) async => false);

        final span = await APM.startCustomSpan('Test Span');

        expect(span, isNull);
        verify(mLuciqLogger.d(
          LuciqStrings.customSpanAPMDisabledMessage,
          tag: APM.tag,
        )).called(1);
      });

      test('returns null and logs when custom span feature disabled', () async {
        when(mLuciqHost.isBuilt()).thenAnswer((_) async => true);
        when(mHost.isEnabled()).thenAnswer((_) async => true);
        when(mHost.isCustomSpanEnabled()).thenAnswer((_) async => false);

        final span = await APM.startCustomSpan('Test Span');

        expect(span, isNull);
        verify(mLuciqLogger.d(
          LuciqStrings.customSpanDisabled,
          tag: APM.tag,
        )).called(1);
      });

      test('returns null and logs error for empty name', () async {
        final span = await APM.startCustomSpan('');

        expect(span, isNull);
        verify(mLuciqLogger.e(
          LuciqStrings.customSpanNameEmpty,
          tag: APM.tag,
        )).called(1);
      });

      test('returns null and logs error for whitespace-only name', () async {
        final span = await APM.startCustomSpan('   ');

        expect(span, isNull);
        verify(mLuciqLogger.e(
          LuciqStrings.customSpanNameEmpty,
          tag: APM.tag,
        )).called(1);
      });

      test('trims whitespace from name', () async {
        when(mLuciqHost.isBuilt()).thenAnswer((_) async => true);
        when(mHost.isEnabled()).thenAnswer((_) async => true);
        when(mHost.isCustomSpanEnabled()).thenAnswer((_) async => true);

        final span = await APM.startCustomSpan('  Test Span  ');

        expect(span?.name, 'Test Span');
      });

      test('truncates long names and logs', () async {
        when(mLuciqHost.isBuilt()).thenAnswer((_) async => true);
        when(mHost.isEnabled()).thenAnswer((_) async => true);
        when(mHost.isCustomSpanEnabled()).thenAnswer((_) async => true);
        final longName = 'a' * 200;

        final span = await APM.startCustomSpan(longName);

        expect(span?.name.length, 150);
        verify(mLuciqLogger.d(
          LuciqStrings.customSpanNameTruncated,
          tag: APM.tag,
        )).called(1);
      });

      test('accepts name exactly 150 characters without logging truncation',
          () async {
        when(mLuciqHost.isBuilt()).thenAnswer((_) async => true);
        when(mHost.isEnabled()).thenAnswer((_) async => true);
        when(mHost.isCustomSpanEnabled()).thenAnswer((_) async => true);
        final exactName = 'a' * 150;

        final span = await APM.startCustomSpan(exactName);

        expect(span?.name.length, 150);
        verifyNever(mLuciqLogger.d(
          LuciqStrings.customSpanNameTruncated,
          tag: anyNamed('tag'),
        ));
      });

      test('accepts special characters in name', () async {
        when(mLuciqHost.isBuilt()).thenAnswer((_) async => true);
        when(mHost.isEnabled()).thenAnswer((_) async => true);
        when(mHost.isCustomSpanEnabled()).thenAnswer((_) async => true);

        final span = await APM.startCustomSpan(r'Test @#$%^&*() Span!');

        expect(span, isNotNull);
        expect(span!.name, r'Test @#$%^&*() Span!');
      });

      test('accepts unicode characters in name', () async {
        when(mLuciqHost.isBuilt()).thenAnswer((_) async => true);
        when(mHost.isEnabled()).thenAnswer((_) async => true);
        when(mHost.isCustomSpanEnabled()).thenAnswer((_) async => true);

        final span = await APM.startCustomSpan('Test 日本語 Span 🚀');

        expect(span, isNotNull);
        expect(span!.name, 'Test 日本語 Span 🚀');
      });

      test('registers span in active spans', () async {
        when(mLuciqHost.isBuilt()).thenAnswer((_) async => true);
        when(mHost.isEnabled()).thenAnswer((_) async => true);
        when(mHost.isCustomSpanEnabled()).thenAnswer((_) async => true);

        expect(APM.activeSpanCount, 0);

        final span = await APM.startCustomSpan('Test Span');

        expect(span, isNotNull);
        expect(APM.activeSpanCount, 1);
      });
    });

    group('Span Limit', () {
      test('returns null and logs when max span limit (100) reached', () async {
        when(mLuciqHost.isBuilt()).thenAnswer((_) async => true);
        when(mHost.isEnabled()).thenAnswer((_) async => true);
        when(mHost.isCustomSpanEnabled()).thenAnswer((_) async => true);

        // Create 100 spans
        for (var i = 0; i < 100; i++) {
          final span = await APM.startCustomSpan('Span $i');
          expect(span, isNotNull);
        }

        expect(APM.activeSpanCount, 100);

        // 101st span should fail
        final extraSpan = await APM.startCustomSpan('Extra Span');

        expect(extraSpan, isNull);
        verify(mLuciqLogger.e(
          LuciqStrings.customSpanLimitReached,
          tag: APM.tag,
        )).called(1);
      });

      test('allows new span after ending one when at limit', () async {
        when(mLuciqHost.isBuilt()).thenAnswer((_) async => true);
        when(mHost.isEnabled()).thenAnswer((_) async => true);
        when(mHost.isCustomSpanEnabled()).thenAnswer((_) async => true);

        var clockCallCount = 0;
        when(mMonotonicClock.now).thenAnswer((_) {
          clockCallCount++;
          return 1000000 + (clockCallCount * 1000);
        });

        // Create 100 spans
        final spans = <CustomSpan>[];
        for (var i = 0; i < 100; i++) {
          final span = await APM.startCustomSpan('Span $i');
          spans.add(span!);
        }

        expect(APM.activeSpanCount, 100);

        // End one span
        await spans.first.end();

        expect(APM.activeSpanCount, 99);

        // Now should be able to create a new span
        final newSpan = await APM.startCustomSpan('New Span');
        expect(newSpan, isNotNull);
        expect(APM.activeSpanCount, 100);
      });

      test('activeSpanCount reflects current active spans', () async {
        when(mLuciqHost.isBuilt()).thenAnswer((_) async => true);
        when(mHost.isEnabled()).thenAnswer((_) async => true);
        when(mHost.isCustomSpanEnabled()).thenAnswer((_) async => true);

        var clockCallCount = 0;
        when(mMonotonicClock.now).thenAnswer((_) {
          clockCallCount++;
          return 1000000 + (clockCallCount * 1000);
        });

        expect(APM.activeSpanCount, 0);

        final span1 = await APM.startCustomSpan('Span 1');
        expect(APM.activeSpanCount, 1);

        final span2 = await APM.startCustomSpan('Span 2');
        expect(APM.activeSpanCount, 2);

        await span1!.end();
        expect(APM.activeSpanCount, 1);

        await span2!.end();
        expect(APM.activeSpanCount, 0);
      });
    });

    group('addCompletedCustomSpan', () {
      test('sends to native when valid', () async {
        when(mLuciqHost.isBuilt()).thenAnswer((_) async => true);
        when(mHost.isEnabled()).thenAnswer((_) async => true);
        when(mHost.isCustomSpanEnabled()).thenAnswer((_) async => true);
        final start = DateTime(2025, 1, 1, 10, 0, 0);
        final end = DateTime(2025, 1, 1, 10, 0, 1);

        await APM.addCompletedCustomSpan('Test Span', start, end);

        verify(mHost.syncCustomSpan(
          'Test Span',
          start.microsecondsSinceEpoch,
          end.microsecondsSinceEpoch,
        )).called(1);
      });

      test('logs error when SDK not initialized', () async {
        when(mLuciqHost.isBuilt()).thenAnswer((_) async => false);
        final start = DateTime(2025, 1, 1, 10, 0, 0);
        final end = DateTime(2025, 1, 1, 10, 0, 1);

        await APM.addCompletedCustomSpan('Test Span', start, end);

        verify(mLuciqLogger.e(
          LuciqStrings.customSpanSDKNotInitializedMessage,
          tag: APM.tag,
        )).called(1);
      });

      test('logs when APM disabled', () async {
        when(mLuciqHost.isBuilt()).thenAnswer((_) async => true);
        when(mHost.isEnabled()).thenAnswer((_) async => false);
        final start = DateTime(2025, 1, 1, 10, 0, 0);
        final end = DateTime(2025, 1, 1, 10, 0, 1);

        await APM.addCompletedCustomSpan('Test Span', start, end);

        verify(mLuciqLogger.d(
          LuciqStrings.customSpanAPMDisabledMessage,
          tag: APM.tag,
        )).called(1);
      });

      test('logs when custom span feature disabled', () async {
        when(mLuciqHost.isBuilt()).thenAnswer((_) async => true);
        when(mHost.isEnabled()).thenAnswer((_) async => true);
        when(mHost.isCustomSpanEnabled()).thenAnswer((_) async => false);
        final start = DateTime(2025, 1, 1, 10, 0, 0);
        final end = DateTime(2025, 1, 1, 10, 0, 1);

        await APM.addCompletedCustomSpan('Test Span', start, end);

        verify(mLuciqLogger.d(
          LuciqStrings.customSpanDisabled,
          tag: APM.tag,
        )).called(1);
      });

      test('logs error for empty name', () async {
        final start = DateTime(2025, 1, 1, 10, 0, 0);
        final end = DateTime(2025, 1, 1, 10, 0, 1);

        await APM.addCompletedCustomSpan('', start, end);

        verify(mLuciqLogger.e(
          LuciqStrings.customSpanNameEmpty,
          tag: APM.tag,
        )).called(1);
      });

      test('logs error for whitespace-only name', () async {
        final start = DateTime(2025, 1, 1, 10, 0, 0);
        final end = DateTime(2025, 1, 1, 10, 0, 1);

        await APM.addCompletedCustomSpan('   ', start, end);

        verify(mLuciqLogger.e(
          LuciqStrings.customSpanNameEmpty,
          tag: APM.tag,
        )).called(1);
      });

      test('logs error when end time equals start time', () async {
        final sameTime = DateTime(2025, 1, 1, 10, 0, 0);

        await APM.addCompletedCustomSpan('Test Span', sameTime, sameTime);

        verify(mLuciqLogger.e(
          LuciqStrings.customSpanEndTimeBeforeStartTime,
          tag: APM.tag,
        )).called(1);
      });

      test('logs error when end time before start time', () async {
        final start = DateTime(2025, 1, 1, 10, 0, 1);
        final end = DateTime(2025, 1, 1, 10, 0, 0);

        await APM.addCompletedCustomSpan('Test Span', start, end);

        verify(mLuciqLogger.e(
          LuciqStrings.customSpanEndTimeBeforeStartTime,
          tag: APM.tag,
        )).called(1);
      });

      test('trims whitespace from name', () async {
        when(mLuciqHost.isBuilt()).thenAnswer((_) async => true);
        when(mHost.isEnabled()).thenAnswer((_) async => true);
        when(mHost.isCustomSpanEnabled()).thenAnswer((_) async => true);
        final start = DateTime(2025, 1, 1, 10, 0, 0);
        final end = DateTime(2025, 1, 1, 10, 0, 1);

        await APM.addCompletedCustomSpan('  Test Span  ', start, end);

        verify(mHost.syncCustomSpan(
          'Test Span',
          start.microsecondsSinceEpoch,
          end.microsecondsSinceEpoch,
        )).called(1);
      });
    });

    group('\$syncCustomSpan', () {
      test('logs error for empty name', () async {
        await APM.$syncCustomSpan('', 1000, 2000);

        verify(mLuciqLogger.e(
          LuciqStrings.customSpanNameEmpty,
          tag: APM.tag,
        )).called(1);
      });

      test('logs error when end timestamp equals start timestamp', () async {
        await APM.$syncCustomSpan('Test', 1000, 1000);

        verify(mLuciqLogger.e(
          LuciqStrings.customSpanEndTimeBeforeStartTime,
          tag: APM.tag,
        )).called(1);
      });

      test('logs error when end timestamp before start timestamp', () async {
        await APM.$syncCustomSpan('Test', 2000, 1000);

        verify(mLuciqLogger.e(
          LuciqStrings.customSpanEndTimeBeforeStartTime,
          tag: APM.tag,
        )).called(1);
      });

      test('logs when name is truncated', () async {
        final longName = 'b' * 200;

        await APM.$syncCustomSpan(longName, 1000, 2000);

        verify(mLuciqLogger.d(
          LuciqStrings.customSpanNameTruncated,
          tag: APM.tag,
        )).called(1);
        verify(mHost.syncCustomSpan(
          argThat(hasLength(150)),
          1000,
          2000,
        )).called(1);
      });

      test('sends valid inputs to native', () async {
        await APM.$syncCustomSpan('Test', 1000, 2000);

        verify(mHost.syncCustomSpan('Test', 1000, 2000)).called(1);
      });
    });
  });
}
