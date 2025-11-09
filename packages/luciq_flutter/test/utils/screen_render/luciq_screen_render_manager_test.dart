import 'dart:ui' show FrameTiming;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luciq_flutter/luciq_flutter.dart';
import 'package:luciq_flutter/src/generated/apm.api.g.dart';
import 'package:luciq_flutter/src/generated/crash_reporting.api.g.dart';
import 'package:luciq_flutter/src/models/luciq_frame_data.dart';
import 'package:luciq_flutter/src/models/luciq_screen_render_data.dart';
import 'package:luciq_flutter/src/utils/luciq_logger.dart';
import 'package:luciq_flutter/src/utils/screen_rendering/luciq_screen_render_manager.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'luciq_screen_render_manager_test.mocks.dart';


@GenerateMocks([
  LuciqScreenRenderManager,
  WidgetsBinding,
  FrameTiming,
  CrashReportingHostApi,
  ApmHostApi,
  LuciqLogger,
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LuciqScreenRenderManager manager;
  late MockApmHostApi mApmHost;
  late MockWidgetsBinding mWidgetBinding;

  setUp(() async {
    mApmHost = MockApmHostApi();
    mWidgetBinding = MockWidgetsBinding();
    manager = LuciqScreenRenderManager.init(); // test-only constructor
    APM.$setHostApi(mApmHost);
    when(mApmHost.getDeviceRefreshRateAndTolerance())
        .thenAnswer((_) async => [60, 0]);
    manager.init(mWidgetBinding);
  });

  group('LuciqScreenRenderManager.init()', () {
    test('should initialize timings callback and add observer', () async {
      expect(manager, isA<LuciqScreenRenderManager>());

      verify(mWidgetBinding.addObserver(any)).called(1);

      verify(mWidgetBinding.addTimingsCallback(any)).called(1);
    });

    test('calling init more that one time should do nothing', () async {
      manager.init(mWidgetBinding);
      manager.init(
        mWidgetBinding,
      ); // second call should be ignored

      verify(mWidgetBinding.addObserver(any)).called(1);

      verify(mWidgetBinding.addTimingsCallback(any)).called(1);
    });
  });

  group('startScreenRenderCollectorForTraceId()', () {
    test('should not attach timing listener if it is attached', () async {
      manager.startScreenRenderCollectorForTraceId(1);
      manager.startScreenRenderCollectorForTraceId(2);
      manager.startScreenRenderCollectorForTraceId(3);

      verify(mWidgetBinding.addTimingsCallback(any)).called(
        1,
      ); // the one form initForTesting()
    });

    test('should attach timing listener if it is not attached', () async {
      manager.syncCollectedScreenRenderingData(); // this should detach listener safely

      manager.startScreenRenderCollectorForTraceId(1);

      verify(mWidgetBinding.addTimingsCallback(any)).called(
        1,
      );
    });

    test('should update the data for same trace type', () {
      const firstTraceId = 123;
      const secondTraceId = 456;

      expect(manager.screenRenderForAutoUiTrace.isActive, false);

      manager.startScreenRenderCollectorForTraceId(
        firstTraceId,
      );
      expect(manager.screenRenderForAutoUiTrace.isActive, true);
      expect(manager.screenRenderForAutoUiTrace.traceId, firstTraceId);

      manager.startScreenRenderCollectorForTraceId(
        secondTraceId,
      );
      expect(manager.screenRenderForAutoUiTrace.isActive, true);
      expect(manager.screenRenderForAutoUiTrace.traceId, secondTraceId);
    });

    test('should not update the data for same trace type', () {
      const firstTraceId = 123;
      const secondTraceId = 456;

      expect(manager.screenRenderForAutoUiTrace.isActive, false);
      expect(manager.screenRenderForCustomUiTrace.isActive, false);

      manager.startScreenRenderCollectorForTraceId(
        firstTraceId,
      );
      expect(manager.screenRenderForAutoUiTrace.isActive, true);
      expect(manager.screenRenderForAutoUiTrace.traceId, firstTraceId);

      manager.startScreenRenderCollectorForTraceId(
        secondTraceId,
        UiTraceType.custom,
      );
      expect(manager.screenRenderForAutoUiTrace.traceId, firstTraceId);
      expect(manager.screenRenderForCustomUiTrace.traceId, secondTraceId);
    });
  });

  group('stopScreenRenderCollector()', () {
    test('should not save data if no UI trace is started', () {
      final frameTestData = LuciqScreenRenderData(
        traceId: 123,
        frameData: [
          LuciqFrameData(10000, 200),
          LuciqFrameData(20000, 1000),
        ],
        frozenFramesTotalDurationMicro: 1000,
        slowFramesTotalDurationMicro: 200,
      );

      manager.setFrameData(frameTestData);

      manager.syncCollectedScreenRenderingData();

      expect(manager.screenRenderForAutoUiTrace.isActive, false);
      expect(manager.screenRenderForAutoUiTrace == frameTestData, false);

      expect(manager.screenRenderForCustomUiTrace.isActive, false);
      expect(manager.screenRenderForCustomUiTrace == frameTestData, false);
    });

    test(
        'for auto UITrace should report data to native using endScreenRenderForAutoUiTrace',
        () {
      final frameTestData = LuciqScreenRenderData(
        traceId: 123,
        frameData: [],
        frozenFramesTotalDurationMicro: 1000,
        slowFramesTotalDurationMicro: 1000,
        endTimeMicro: 30000,
      );

      manager.startScreenRenderCollectorForTraceId(
        frameTestData.traceId,
      );

      manager.startScreenRenderCollectorForTraceId(
        frameTestData.traceId + 1,
        UiTraceType.custom,
      );

      manager.setFrameData(frameTestData);

      manager.syncCollectedScreenRenderingData();

      verify(
        mApmHost.endScreenRenderForAutoUiTrace(any),
      ); // the content has been verified in the above assertion.

      expect(manager.screenRenderForAutoUiTrace.isActive, false);

      expect(manager.screenRenderForCustomUiTrace.isActive, false);

      expect(manager.screenRenderForAutoUiTrace.isEmpty, true);
    });

    test(
        'for custom UITrace should report data to native using endScreenRenderForCustomUiTrace',
        () {
      final frameTestData = LuciqScreenRenderData(
        traceId: 123,
        frameData: [
          LuciqFrameData(10000, 400),
          LuciqFrameData(10000, 600),
          LuciqFrameData(20000, 1000),
        ],
        frozenFramesTotalDurationMicro: 1000,
        slowFramesTotalDurationMicro: 1000,
        endTimeMicro: 30000,
      );

      manager.startScreenRenderCollectorForTraceId(
        frameTestData.traceId,
        UiTraceType.custom,
      );

      manager.setFrameData(frameTestData);

      manager.syncCollectedScreenRenderingData();

      expect(manager.screenRenderForCustomUiTrace.isActive, false);

      expect(manager.screenRenderForAutoUiTrace.isActive, false);

      expect(manager.screenRenderForCustomUiTrace.isEmpty, true);

      verify(
        mApmHost.endScreenRenderForCustomUiTrace(any),
      ); // the content has been verified in the above assertion.
    });

    test('should not remove timing callback listener', () {
      final frameTestData = LuciqScreenRenderData(
        traceId: 123,
        frameData: [
          LuciqFrameData(10000, 200),
          LuciqFrameData(20000, 1000),
        ],
        frozenFramesTotalDurationMicro: 1000,
        slowFramesTotalDurationMicro: 200,
      );

      manager.setFrameData(frameTestData);
      manager.syncCollectedScreenRenderingData();

      verifyNever(mWidgetBinding.removeTimingsCallback(any));
    });

    test('should report data to native side with the correct type', () async {
      final frameTestData = LuciqScreenRenderData(
        traceId: 123,
        frameData: [
          LuciqFrameData(10000, 200),
          LuciqFrameData(20000, 1000),
        ],
        frozenFramesTotalDurationMicro: 1000,
        slowFramesTotalDurationMicro: 200,
      );

      manager.startScreenRenderCollectorForTraceId(0, UiTraceType.custom);
      manager.setFrameData(frameTestData);
      manager.syncCollectedScreenRenderingData();
      verify(mApmHost.endScreenRenderForCustomUiTrace(any)).called(1);
      verifyNever(mApmHost.endScreenRenderForAutoUiTrace(any));
    });
  });

  group('endScreenRenderCollector()', () {
    setUp(() {
      manager.screenRenderForAutoUiTrace.clear();
      manager.screenRenderForCustomUiTrace.clear();
    });

    test('should not save data if no custom UI trace is started', () {
      final frameTestData = LuciqScreenRenderData(
        traceId: 123,
        frameData: [
          LuciqFrameData(10000, 200),
          LuciqFrameData(20000, 1000),
        ],
        frozenFramesTotalDurationMicro: 1000,
        slowFramesTotalDurationMicro: 200,
      );

      manager.setFrameData(frameTestData);

      manager.endScreenRenderCollector();

      expect(manager.screenRenderForCustomUiTrace.isActive, false);
      expect(manager.screenRenderForCustomUiTrace == frameTestData, false);
    });

    test(
        'should save data to  screenRenderForCustomUiTrace if custom UI trace is started',
        () {
      final frameTestData = LuciqScreenRenderData(
        traceId: 123,
        frameData: [
          LuciqFrameData(10000, 200),
          LuciqFrameData(20000, 1000),
        ],
        frozenFramesTotalDurationMicro: 1000,
        slowFramesTotalDurationMicro: 200,
      );

      manager.startScreenRenderCollectorForTraceId(
        frameTestData.traceId,
        UiTraceType.custom,
      );

      manager.setFrameData(frameTestData);

      manager.endScreenRenderCollector();
    });

    test('should not remove timing callback listener', () {
      manager.endScreenRenderCollector();

      verifyNever(mWidgetBinding.removeTimingsCallback(any));
    });

    test('should report data to native side', () async {
      final frameTestData = LuciqScreenRenderData(
        traceId: 123,
        frameData: [
          LuciqFrameData(10000, 200),
          LuciqFrameData(20000, 1000),
        ],
        frozenFramesTotalDurationMicro: 1000,
        slowFramesTotalDurationMicro: 200,
      );

      manager.startScreenRenderCollectorForTraceId(0, UiTraceType.custom);
      manager.setFrameData(frameTestData);
      manager.endScreenRenderCollector(UiTraceType.custom);
      verify(mApmHost.endScreenRenderForCustomUiTrace(any)).called(1);
    });
  });

  group('analyzeFrameTiming()', () {
    late MockFrameTiming mockFrameTiming;

    setUp(() {
      mockFrameTiming = MockFrameTiming();
      when(mockFrameTiming.buildDuration)
          .thenReturn(const Duration(milliseconds: 1));
      when(mockFrameTiming.rasterDuration)
          .thenReturn(const Duration(milliseconds: 1));
      when(mockFrameTiming.totalSpan)
          .thenReturn(const Duration(milliseconds: 2));
      when(mockFrameTiming.timestampInMicroseconds(any)).thenReturn(1000);
    });

    test('should detect slow frame on ui thread and record duration', () {
      const buildDuration = 20;
      when(mockFrameTiming.buildDuration)
          .thenReturn(const Duration(milliseconds: buildDuration));

      manager.startScreenRenderCollectorForTraceId(1); // start new collector
      manager.analyzeFrameTiming(mockFrameTiming); // mock frame timing
      manager.syncCollectedScreenRenderingData(); // should save data

      expect(
        manager.screenRenderForAutoUiTrace.frameData.isEmpty,
        true,
      ); // reset cached data after sync
    });

    test('should detect slow frame on raster thread and record duration', () {
      const rasterDuration = 20;
      when(mockFrameTiming.rasterDuration)
          .thenReturn(const Duration(milliseconds: rasterDuration));

      manager.startScreenRenderCollectorForTraceId(1); // start new collector
      manager.analyzeFrameTiming(mockFrameTiming); // mock frame timing
      manager.syncCollectedScreenRenderingData(); // should save data

      expect(
        manager.screenRenderForAutoUiTrace.frameData.isEmpty,
        true,
      ); // reset cached data after sync
    });

    test(
        'should detect frozen frame when durations are greater than or equal 700 ms',
        () {
      const totalTime = 700;
      when(mockFrameTiming.totalSpan)
          .thenReturn(const Duration(milliseconds: totalTime));
      manager.startScreenRenderCollectorForTraceId(1); // start new collector
      manager.analyzeFrameTiming(mockFrameTiming); // mock frame timing
      manager.syncCollectedScreenRenderingData(); // should save data

      expect(
        manager.screenRenderForAutoUiTrace.frameData.isEmpty,
        true,
      ); // reset cached data after sync
    });

    test('should detect no slow or frozen frame under thresholds', () {
      when(mockFrameTiming.buildDuration)
          .thenReturn(const Duration(milliseconds: 5));
      when(mockFrameTiming.rasterDuration)
          .thenReturn(const Duration(milliseconds: 5));
      when(mockFrameTiming.totalSpan)
          .thenReturn(const Duration(milliseconds: 10));
      manager.analyzeFrameTiming(mockFrameTiming);
      expect(manager.screenRenderForAutoUiTrace.frameData.isEmpty, true);
      expect(
        manager.screenRenderForAutoUiTrace.frozenFramesTotalDurationMicro,
        0,
      ); // * 1000 to convert from milliseconds to microseconds
      expect(
        manager.screenRenderForAutoUiTrace.slowFramesTotalDurationMicro,
        0,
      );
    });
  });

  group('LuciqScreenRenderManager.endScreenRenderCollector', () {
    test('should save and reset cached data if delayed frames exist', () {
      final frameTestData = LuciqScreenRenderData(
        traceId: 123,
        frameData: [
          LuciqFrameData(10000, 200),
          LuciqFrameData(20000, 1000),
        ],
        frozenFramesTotalDurationMicro: 1000,
        slowFramesTotalDurationMicro: 200,
      );
      manager.startScreenRenderCollectorForTraceId(1);
      manager.setFrameData(frameTestData);
      manager.endScreenRenderCollector();
      verify(mApmHost.endScreenRenderForAutoUiTrace(any)).called(1);
      expect(manager.screenRenderForAutoUiTrace.isEmpty, true);
      expect(manager.screenRenderForAutoUiTrace.isActive, false);
    });

    test('should report and clear custom trace if type is custom and active',
        () {
      final frameTestData = LuciqScreenRenderData(
        traceId: 123,
        frameData: [
          LuciqFrameData(10000, 200),
          LuciqFrameData(20000, 1000),
        ],
        frozenFramesTotalDurationMicro: 1000,
        slowFramesTotalDurationMicro: 200,
      );
      manager.startScreenRenderCollectorForTraceId(1, UiTraceType.custom);
      manager.setFrameData(frameTestData);
      manager.endScreenRenderCollector(UiTraceType.custom);
      verify(mApmHost.endScreenRenderForCustomUiTrace(any)).called(1);
      expect(manager.screenRenderForCustomUiTrace.isEmpty, true);
      expect(manager.screenRenderForCustomUiTrace.isActive, false);
    });

    test('should return early if not enabled or timings not attached', () {
      manager.screenRenderEnabled = false;
      manager.endScreenRenderCollector();
      verifyNever(mApmHost.endScreenRenderForAutoUiTrace(any));
      verifyNever(mApmHost.endScreenRenderForCustomUiTrace(any));
    });
  });

  group('LuciqScreenRenderManager() error handling', () {
    late LuciqScreenRenderManager realManager;
    late MockLuciqLogger mLuciqLogger;
    late MockApmHostApi mApmHostForErrorTest;
    late MockWidgetsBinding mWidgetBindingForErrorTest;
    late MockCrashReportingHostApi mCrashReportingHost;

    setUp(() {
      realManager = LuciqScreenRenderManager.init(); // Use real instance
      mLuciqLogger = MockLuciqLogger();
      mApmHostForErrorTest = MockApmHostApi();
      mWidgetBindingForErrorTest = MockWidgetsBinding();
      mCrashReportingHost = MockCrashReportingHostApi();

      LuciqScreenRenderManager.setInstance(realManager);
      LuciqLogger.setInstance(mLuciqLogger);
      APM.$setHostApi(mApmHostForErrorTest);

      // Mock CrashReporting host to prevent platform channel calls
      CrashReporting.$setHostApi(mCrashReportingHost);
    });

    test('should log error and stack trace when init() encounters an exception',
        () async {
      const error = 'Test error in getDeviceRefreshRateAndTolerance';
      final exception = Exception(error);

      when(mApmHostForErrorTest.getDeviceRefreshRateAndTolerance())
          .thenThrow(exception);

      await realManager.init(mWidgetBindingForErrorTest);

      final capturedLog = verify(
        mLuciqLogger.e(
          captureAny,
          tag: LuciqScreenRenderManager.tag,
        ),
      ).captured.single as String;

      expect(capturedLog, contains('[Error]:$exception'));
      expect(capturedLog, contains('[StackTrace]:'));

      // Verify that non-fatal crash reporting was called
      verify(
        mCrashReportingHost.sendNonFatalError(
          any, // jsonCrash
          any, // userAttributes
          any, // fingerprint
          any, // nonFatalExceptionLevel
        ),
      ).called(1);
    });

    test(
        'should log error and stack trace when _reportScreenRenderForAutoUiTrace() encounters an exception',
        () async {
      const error = 'Test error in endScreenRenderForAutoUiTrace';
      final exception = Exception(error);

      // First initialize the manager properly
      when(mApmHostForErrorTest.getDeviceRefreshRateAndTolerance())
          .thenAnswer((_) async => [60.0, 10000.0]);

      await realManager.init(mWidgetBindingForErrorTest);

      final frameTestData = LuciqScreenRenderData(
        traceId: 123,
        frameData: [
          LuciqFrameData(10000, 200),
          LuciqFrameData(20000, 1000),
        ],
        frozenFramesTotalDurationMicro: 1000,
        slowFramesTotalDurationMicro: 200,
      );

      when(mApmHostForErrorTest.endScreenRenderForAutoUiTrace(any))
          .thenThrow(exception);

      // Start the collector and add frame data
      realManager.startScreenRenderCollectorForTraceId(123);
      realManager.setFrameData(frameTestData);
      // End the collector which should trigger the error
      realManager.endScreenRenderCollector();

      final capturedLog = verify(
        mLuciqLogger.e(
          captureAny,
          tag: LuciqScreenRenderManager.tag,
        ),
      ).captured.single as String;

      expect(capturedLog, contains('[Error]:$exception'));
      expect(capturedLog, contains('[StackTrace]:'));

      // Verify that non-fatal crash reporting was called
      verify(
        mCrashReportingHost.sendNonFatalError(
          any, // jsonCrash
          any, // userAttributes
          any, // fingerprint
          any, // nonFatalExceptionLevel
        ),
      ).called(1);
    });

    test(
        'should log error and stack trace when _reportScreenRenderForCustomUiTrace() encounters an exception',
        () async {
      const error = 'Test error in endScreenRenderForCustomUiTrace';
      final exception = Exception(error);

      // First initialize the manager properly
      when(mApmHostForErrorTest.getDeviceRefreshRateAndTolerance())
          .thenAnswer((_) async => [60.0, 10000.0]);

      await realManager.init(mWidgetBindingForErrorTest);

      final frameTestData = LuciqScreenRenderData(
        traceId: 456,
        frameData: [
          LuciqFrameData(15000, 300),
          LuciqFrameData(25000, 1200),
        ],
        frozenFramesTotalDurationMicro: 1200,
        slowFramesTotalDurationMicro: 300,
      );

      when(mApmHostForErrorTest.endScreenRenderForCustomUiTrace(any))
          .thenThrow(exception);

      // Start the collector and add frame data
      realManager.startScreenRenderCollectorForTraceId(456, UiTraceType.custom);
      realManager.setFrameData(frameTestData);
      // End the collector which should trigger the error
      realManager.endScreenRenderCollector(UiTraceType.custom);

      final capturedLog = verify(
        mLuciqLogger.e(
          captureAny,
          tag: LuciqScreenRenderManager.tag,
        ),
      ).captured.single as String;

      expect(capturedLog, contains('[Error]:$exception'));
      expect(capturedLog, contains('[StackTrace]:'));

      // Verify that non-fatal crash reporting was called
      verify(
        mCrashReportingHost.sendNonFatalError(
          any, // jsonCrash
          any, // userAttributes
          any, // fingerprint
          any, // nonFatalExceptionLevel
        ),
      ).called(1);
    });
  });
}
