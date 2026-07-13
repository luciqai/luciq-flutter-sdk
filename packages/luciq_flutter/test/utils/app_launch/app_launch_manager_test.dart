import 'package:flutter_test/flutter_test.dart';
import 'package:luciq_flutter/luciq_flutter.dart';
import 'package:luciq_flutter/src/generated/apm.api.g.dart';
import 'package:luciq_flutter/src/utils/app_launch/app_launch_manager.dart';
import 'package:luciq_flutter/src/utils/lcq_date_time.dart';
import 'package:luciq_flutter/src/utils/luciq_logger.dart';
import 'package:luciq_flutter/src/utils/luciq_montonic_clock.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'app_launch_manager_test.mocks.dart';

@GenerateMocks([
  ApmHostApi,
  LCQDateTime,
  LuciqLogger,
  LuciqMonotonicClock,
])
void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  late MockApmHostApi mHost;
  late MockLCQDateTime mDateTime;
  late MockLuciqLogger mLuciqLogger;
  late MockLuciqMonotonicClock mMonotonicClock;
  late AppLaunchManager manager;

  // T1 epoch anchor.
  final dartEntryTime = DateTime(2026, 7, 8, 10);
  final dartEntryEpochMicros = dartEntryTime.microsecondsSinceEpoch;

  /// Stubs the monotonic clock to return [values] in order across calls.
  void stubMonotonic(List<int> values) {
    var index = 0;
    when(mMonotonicClock.now).thenAnswer((_) {
      final value = values[index < values.length ? index : values.length - 1];
      index++;
      return value;
    });
  }

  /// Fires the one-shot post-frame callback registered by [markDartEntry].
  void pumpFrame() {
    binding.handleBeginFrame(Duration.zero);
    binding.handleDrawFrame();
  }

  setUp(() {
    mHost = MockApmHostApi();
    mDateTime = MockLCQDateTime();
    mLuciqLogger = MockLuciqLogger();
    mMonotonicClock = MockLuciqMonotonicClock();

    AppLaunchManager.resetInstance();
    manager = AppLaunchManager.I;

    APM.$setHostApi(mHost);
    LCQDateTime.setInstance(mDateTime);
    LuciqLogger.setInstance(mLuciqLogger);
    LuciqMonotonicClock.setInstance(mMonotonicClock);

    when(mDateTime.now()).thenReturn(dartEntryTime);
    when(mLuciqLogger.isDebugEnabled()).thenReturn(false);
    when(mHost.reportAppLaunchStages(any, any, any)).thenAnswer((_) async {});
    when(mHost.endAppLaunch()).thenAnswer((_) async {});
  });

  tearDown(() {
    // Drain any post-frame callback a test registered but did not pump, so it
    // cannot leak into the next test's frame.
    pumpFrame();
    reset(mHost);
    reset(mLuciqLogger);
  });

  group('AppLaunchManager', () {
    test('reports exact stage durations on endAppLaunch', () async {
      // T1=1000, T2=3000, T3=8000 → stage2=2000, stage3=5000.
      stubMonotonic([1000, 3000, 8000]);

      manager.markDartEntry();
      pumpFrame();
      await manager.reportStagesOnEndAppLaunch();

      verify(
        mHost.reportAppLaunchStages(dartEntryEpochMicros, 2000, 5000),
      ).called(1);
      verify(mHost.endAppLaunch()).called(1);
    });

    test('skips staged report when endAppLaunch fires before first frame',
        () async {
      stubMonotonic([1000, 8000]);

      manager.markDartEntry();
      // No pumpFrame → T2 never captured.
      await manager.reportStagesOnEndAppLaunch();

      verifyNever(mHost.reportAppLaunchStages(any, any, any));
      verify(mHost.endAppLaunch()).called(1);
    });

    test('skips staged report when markDartEntry was never called', () async {
      stubMonotonic([8000]);

      await manager.reportStagesOnEndAppLaunch();

      verifyNever(mHost.reportAppLaunchStages(any, any, any));
      verify(mHost.endAppLaunch()).called(1);
    });

    test('tracks only the first launch window on repeated markDartEntry',
        () async {
      // First T1=1000. Second markDartEntry must be ignored (no clock read
      // consumed for a new T1). T2=3000, T3=8000.
      stubMonotonic([1000, 3000, 8000]);

      manager.markDartEntry();
      manager.markDartEntry();
      pumpFrame();
      await manager.reportStagesOnEndAppLaunch();

      verify(
        mHost.reportAppLaunchStages(dartEntryEpochMicros, 2000, 5000),
      ).called(1);
      verify(mDateTime.now()).called(1);
    });
  });
}
