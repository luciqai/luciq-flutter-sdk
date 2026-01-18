import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luciq_flutter/luciq_flutter.dart';
import 'package:luciq_flutter/src/constants/strings.dart';
import 'package:luciq_flutter/src/generated/apm.api.g.dart';
import 'package:luciq_flutter/src/generated/luciq.api.g.dart';
import 'package:luciq_flutter/src/utils/custom_span/custom_span_manager.dart';
import 'package:luciq_flutter/src/utils/lcq_date_time.dart';
import 'package:luciq_flutter/src/utils/luciq_logger.dart';
import 'package:luciq_flutter/src/utils/luciq_montonic_clock.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'custom_span_manager_test.mocks.dart';

@GenerateMocks([
  ApmHostApi,
  LuciqHostApi,
  LCQDateTime,
  LuciqLogger,
  LuciqMonotonicClock,
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();

  late MockApmHostApi mHost;
  late MockLuciqHostApi mLuciqHost;
  late MockLCQDateTime mDateTime;
  late MockLuciqLogger mLuciqLogger;
  late MockLuciqMonotonicClock mMonotonicClock;
  late CustomSpanManager manager;

  setUp(() {
    mHost = MockApmHostApi();
    mLuciqHost = MockLuciqHostApi();
    mDateTime = MockLCQDateTime();
    mLuciqLogger = MockLuciqLogger();
    mMonotonicClock = MockLuciqMonotonicClock();

    // Reset and set up manager
    CustomSpanManager.resetInstance();
    manager = CustomSpanManager.I;

    // Set up APM host which also sets CustomSpanManager host
    // This is important because FlagsConfig.apm.isEnabled() calls APM.isEnabled()
    APM.$setHostApi(mHost);

    // Set up other dependencies
    Luciq.$setHostApi(mLuciqHost);
    LCQDateTime.setInstance(mDateTime);
    LuciqLogger.setInstance(mLuciqLogger);
    LuciqMonotonicClock.setInstance(mMonotonicClock);

    // Default mock setup
    final time = DateTime.now();
    when(mDateTime.now()).thenReturn(time);
    when(mMonotonicClock.now).thenReturn(1000000);
  });

  tearDown(() {
    manager.$clearActiveSpans();
    reset(mHost);
    reset(mLuciqHost);
    reset(mLuciqLogger);
  });

  group('CustomSpanManager', () {
    group('startCustomSpan', () {
      test('creates span when enabled', () async {
        when(mLuciqHost.isBuilt()).thenAnswer((_) async => true);
        when(mHost.isEnabled()).thenAnswer((_) async => true);
        when(mHost.isCustomSpanEnabled()).thenAnswer((_) async => true);

        final span = await manager.startCustomSpan('Test Span');

        expect(span, isNotNull);
        expect(span!.name, 'Test Span');
      });

      test('returns null and logs error when SDK not initialized', () async {
        when(mLuciqHost.isBuilt()).thenAnswer((_) async => false);

        final span = await manager.startCustomSpan('Test Span');

        expect(span, isNull);
        verify(mLuciqLogger.e(
          LuciqStrings.customSpanSDKNotInitializedMessage,
          tag: CustomSpanManager.tag,
        ),).called(1);
      });

      test('returns null and logs when APM disabled', () async {
        when(mLuciqHost.isBuilt()).thenAnswer((_) async => true);
        when(mHost.isEnabled()).thenAnswer((_) async => false);

        final span = await manager.startCustomSpan('Test Span');

        expect(span, isNull);
        verify(mLuciqLogger.d(
          LuciqStrings.customSpanAPMDisabledMessage,
          tag: CustomSpanManager.tag,
        ),).called(1);
      });

      test('returns null and logs when custom span feature disabled', () async {
        when(mLuciqHost.isBuilt()).thenAnswer((_) async => true);
        when(mHost.isEnabled()).thenAnswer((_) async => true);
        when(mHost.isCustomSpanEnabled()).thenAnswer((_) async => false);

        final span = await manager.startCustomSpan('Test Span');

        expect(span, isNull);
        verify(mLuciqLogger.d(
          LuciqStrings.customSpanDisabled,
          tag: CustomSpanManager.tag,
        ),).called(1);
      });

      test('returns null and logs error for empty name', () async {
        final span = await manager.startCustomSpan('');

        expect(span, isNull);
        verify(mLuciqLogger.e(
          LuciqStrings.customSpanNameEmpty,
          tag: CustomSpanManager.tag,
        ),).called(1);
      });

      test('returns null and logs error for whitespace-only name', () async {
        final span = await manager.startCustomSpan('   ');

        expect(span, isNull);
        verify(mLuciqLogger.e(
          LuciqStrings.customSpanNameEmpty,
          tag: CustomSpanManager.tag,
        ),).called(1);
      });

      test('trims whitespace from name', () async {
        when(mLuciqHost.isBuilt()).thenAnswer((_) async => true);
        when(mHost.isEnabled()).thenAnswer((_) async => true);
        when(mHost.isCustomSpanEnabled()).thenAnswer((_) async => true);

        final span = await manager.startCustomSpan('  Test Span  ');

        expect(span?.name, 'Test Span');
      });

      test('truncates long names and logs', () async {
        when(mLuciqHost.isBuilt()).thenAnswer((_) async => true);
        when(mHost.isEnabled()).thenAnswer((_) async => true);
        when(mHost.isCustomSpanEnabled()).thenAnswer((_) async => true);
        final longName = 'a' * 200;

        final span = await manager.startCustomSpan(longName);

        expect(span?.name.length, 150);
        verify(mLuciqLogger.d(
          LuciqStrings.customSpanNameTruncated,
          tag: CustomSpanManager.tag,
        ),).called(1);
      });

      test('accepts name exactly 150 characters without logging truncation',
          () async {
        when(mLuciqHost.isBuilt()).thenAnswer((_) async => true);
        when(mHost.isEnabled()).thenAnswer((_) async => true);
        when(mHost.isCustomSpanEnabled()).thenAnswer((_) async => true);
        final exactName = 'a' * 150;

        final span = await manager.startCustomSpan(exactName);

        expect(span?.name.length, 150);
        verifyNever(mLuciqLogger.d(
          LuciqStrings.customSpanNameTruncated,
          tag: anyNamed('tag'),
        ),);
      });

      test('accepts special characters in name', () async {
        when(mLuciqHost.isBuilt()).thenAnswer((_) async => true);
        when(mHost.isEnabled()).thenAnswer((_) async => true);
        when(mHost.isCustomSpanEnabled()).thenAnswer((_) async => true);

        final span = await manager.startCustomSpan(r'Test @#$%^&*() Span!');

        expect(span, isNotNull);
        expect(span!.name, r'Test @#$%^&*() Span!');
      });

      test('accepts unicode characters in name', () async {
        when(mLuciqHost.isBuilt()).thenAnswer((_) async => true);
        when(mHost.isEnabled()).thenAnswer((_) async => true);
        when(mHost.isCustomSpanEnabled()).thenAnswer((_) async => true);

        final span = await manager.startCustomSpan('Test 日本語 Span 🚀');

        expect(span, isNotNull);
        expect(span!.name, 'Test 日本語 Span 🚀');
      });

      test('registers span in active spans', () async {
        when(mLuciqHost.isBuilt()).thenAnswer((_) async => true);
        when(mHost.isEnabled()).thenAnswer((_) async => true);
        when(mHost.isCustomSpanEnabled()).thenAnswer((_) async => true);

        expect(manager.activeSpanCount, 0);

        final span = await manager.startCustomSpan('Test Span');

        expect(span, isNotNull);
        expect(manager.activeSpanCount, 1);
      });
    });

    group('Span Limit', () {
      test('returns null and logs when max span limit (100) reached', () async {
        when(mLuciqHost.isBuilt()).thenAnswer((_) async => true);
        when(mHost.isEnabled()).thenAnswer((_) async => true);
        when(mHost.isCustomSpanEnabled()).thenAnswer((_) async => true);

        // Create 100 spans
        for (var i = 0; i < 100; i++) {
          final span = await manager.startCustomSpan('Span $i');
          expect(span, isNotNull);
        }

        expect(manager.activeSpanCount, 100);

        // 101st span should fail
        final extraSpan = await manager.startCustomSpan('Extra Span');

        expect(extraSpan, isNull);
        verify(mLuciqLogger.e(
          LuciqStrings.customSpanLimitReached,
          tag: CustomSpanManager.tag,
        ),).called(1);
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
          final span = await manager.startCustomSpan('Span $i');
          spans.add(span!);
        }

        expect(manager.activeSpanCount, 100);

        // End one span
        await spans.first.end();

        expect(manager.activeSpanCount, 99);

        // Now should be able to create a new span
        final newSpan = await manager.startCustomSpan('New Span');
        expect(newSpan, isNotNull);
        expect(manager.activeSpanCount, 100);
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

        expect(manager.activeSpanCount, 0);

        final span1 = await manager.startCustomSpan('Span 1');
        expect(manager.activeSpanCount, 1);

        final span2 = await manager.startCustomSpan('Span 2');
        expect(manager.activeSpanCount, 2);

        await span1!.end();
        expect(manager.activeSpanCount, 1);

        await span2!.end();
        expect(manager.activeSpanCount, 0);
      });
    });

    group('addCompletedCustomSpan', () {
      test('sends to native when valid', () async {
        when(mLuciqHost.isBuilt()).thenAnswer((_) async => true);
        when(mHost.isEnabled()).thenAnswer((_) async => true);
        when(mHost.isCustomSpanEnabled()).thenAnswer((_) async => true);
        final start = DateTime(2025, 1, 1, 10);
        final end = DateTime(2025, 1, 1, 10, 0, 1);

        await manager.addCompletedCustomSpan('Test Span', start, end);

        verify(mHost.syncCustomSpan(
          'Test Span',
          start.microsecondsSinceEpoch,
          end.microsecondsSinceEpoch,
        ),).called(1);
      });

      test('logs error when SDK not initialized', () async {
        when(mLuciqHost.isBuilt()).thenAnswer((_) async => false);
        final start = DateTime(2025, 1, 1, 10);
        final end = DateTime(2025, 1, 1, 10, 0, 1);

        await manager.addCompletedCustomSpan('Test Span', start, end);

        verify(mLuciqLogger.e(
          LuciqStrings.customSpanSDKNotInitializedMessage,
          tag: CustomSpanManager.tag,
        ),).called(1);
      });

      test('logs when APM disabled', () async {
        when(mLuciqHost.isBuilt()).thenAnswer((_) async => true);
        when(mHost.isEnabled()).thenAnswer((_) async => false);
        final start = DateTime(2025, 1, 1, 10);
        final end = DateTime(2025, 1, 1, 10, 0, 1);

        await manager.addCompletedCustomSpan('Test Span', start, end);

        verify(mLuciqLogger.d(
          LuciqStrings.customSpanAPMDisabledMessage,
          tag: CustomSpanManager.tag,
        ),).called(1);
      });

      test('logs when custom span feature disabled', () async {
        when(mLuciqHost.isBuilt()).thenAnswer((_) async => true);
        when(mHost.isEnabled()).thenAnswer((_) async => true);
        when(mHost.isCustomSpanEnabled()).thenAnswer((_) async => false);
        final start = DateTime(2025, 1, 1, 10);
        final end = DateTime(2025, 1, 1, 10, 0, 1);

        await manager.addCompletedCustomSpan('Test Span', start, end);

        verify(mLuciqLogger.d(
          LuciqStrings.customSpanDisabled,
          tag: CustomSpanManager.tag,
        ),).called(1);
      });

      test('logs error for empty name', () async {
        final start = DateTime(2025, 1, 1, 10);
        final end = DateTime(2025, 1, 1, 10, 0, 1);

        await manager.addCompletedCustomSpan('', start, end);

        verify(mLuciqLogger.e(
          LuciqStrings.customSpanNameEmpty,
          tag: CustomSpanManager.tag,
        ),).called(1);
      });

      test('logs error for whitespace-only name', () async {
        final start = DateTime(2025, 1, 1, 10);
        final end = DateTime(2025, 1, 1, 10, 0, 1);

        await manager.addCompletedCustomSpan('   ', start, end);

        verify(mLuciqLogger.e(
          LuciqStrings.customSpanNameEmpty,
          tag: CustomSpanManager.tag,
        ),).called(1);
      });

      test('logs error when end time equals start time', () async {
        final sameTime = DateTime(2025, 1, 1, 10);

        await manager.addCompletedCustomSpan('Test Span', sameTime, sameTime);

        verify(mLuciqLogger.e(
          LuciqStrings.customSpanEndTimeBeforeStartTime,
          tag: CustomSpanManager.tag,
        ),).called(1);
      });

      test('logs error when end time before start time', () async {
        final start = DateTime(2025, 1, 1, 10, 0, 1);
        final end = DateTime(2025, 1, 1, 10);

        await manager.addCompletedCustomSpan('Test Span', start, end);

        verify(mLuciqLogger.e(
          LuciqStrings.customSpanEndTimeBeforeStartTime,
          tag: CustomSpanManager.tag,
        ),).called(1);
      });

      test('trims whitespace from name', () async {
        when(mLuciqHost.isBuilt()).thenAnswer((_) async => true);
        when(mHost.isEnabled()).thenAnswer((_) async => true);
        when(mHost.isCustomSpanEnabled()).thenAnswer((_) async => true);
        final start = DateTime(2025, 1, 1, 10);
        final end = DateTime(2025, 1, 1, 10, 0, 1);

        await manager.addCompletedCustomSpan('  Test Span  ', start, end);

        verify(mHost.syncCustomSpan(
          'Test Span',
          start.microsecondsSinceEpoch,
          end.microsecondsSinceEpoch,
        ),).called(1);
      });
    });

    group('syncCustomSpan', () {
      test('logs error for empty name', () async {
        await manager.syncCustomSpan('', 1000, 2000);

        verify(mLuciqLogger.e(
          LuciqStrings.customSpanNameEmpty,
          tag: CustomSpanManager.tag,
        ),).called(1);
      });

      test('logs error when end timestamp equals start timestamp', () async {
        await manager.syncCustomSpan('Test', 1000, 1000);

        verify(mLuciqLogger.e(
          LuciqStrings.customSpanEndTimeBeforeStartTime,
          tag: CustomSpanManager.tag,
        ),).called(1);
      });

      test('logs error when end timestamp before start timestamp', () async {
        await manager.syncCustomSpan('Test', 2000, 1000);

        verify(mLuciqLogger.e(
          LuciqStrings.customSpanEndTimeBeforeStartTime,
          tag: CustomSpanManager.tag,
        ),).called(1);
      });

      test('logs when name is truncated', () async {
        final longName = 'b' * 200;

        await manager.syncCustomSpan(longName, 1000, 2000);

        verify(mLuciqLogger.d(
          LuciqStrings.customSpanNameTruncated,
          tag: CustomSpanManager.tag,
        ),).called(1);
        verify(mHost.syncCustomSpan(
          argThat(hasLength(150)),
          1000,
          2000,
        ),).called(1);
      });

      test('sends valid inputs to native', () async {
        await manager.syncCustomSpan('Test', 1000, 2000);

        verify(mHost.syncCustomSpan('Test', 1000, 2000)).called(1);
      });
    });

    group('registerSpan and unregisterSpan', () {
      test('registerSpan adds span to active spans', () {
        final span = CustomSpan('Test');
        expect(manager.activeSpanCount, 0);

        final result = manager.registerSpan(span);

        expect(result, isTrue);
        expect(manager.activeSpanCount, 1);
      });

      test('registerSpan returns false when at limit', () {
        // Fill up to limit
        for (var i = 0; i < CustomSpanManager.maxConcurrentSpans; i++) {
          manager.registerSpan(CustomSpan('Span $i'));
        }

        final extraSpan = CustomSpan('Extra');
        final result = manager.registerSpan(extraSpan);

        expect(result, isFalse);
        expect(manager.activeSpanCount, CustomSpanManager.maxConcurrentSpans);
      });

      test('unregisterSpan removes span from active spans', () {
        final span = CustomSpan('Test');
        manager.registerSpan(span);
        expect(manager.activeSpanCount, 1);

        manager.unregisterSpan(span);

        expect(manager.activeSpanCount, 0);
      });

      test('unregisterSpan handles non-existent span gracefully', () {
        final span = CustomSpan('Test');

        // Should not throw
        manager.unregisterSpan(span);

        expect(manager.activeSpanCount, 0);
      });
    });
  });
}
