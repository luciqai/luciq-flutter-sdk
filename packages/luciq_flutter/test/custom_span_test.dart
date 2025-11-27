import 'package:flutter_test/flutter_test.dart';
import 'package:luciq_flutter/src/generated/apm.api.g.dart';
import 'package:luciq_flutter/src/models/custom_span.dart';
import 'package:luciq_flutter/src/modules/apm.dart';
import 'package:luciq_flutter/src/utils/lcq_date_time.dart';
import 'package:luciq_flutter/src/utils/luciq_montonic_clock.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'custom_span_test.mocks.dart';

@GenerateMocks([
  ApmHostApi,
  LCQDateTime,
  LuciqMonotonicClock,
])
void main() {
  late MockApmHostApi mockHost;
  late MockLCQDateTime mockDateTime;
  late MockLuciqMonotonicClock mockClock;

  setUp(() {
    mockHost = MockApmHostApi();
    mockDateTime = MockLCQDateTime();
    mockClock = MockLuciqMonotonicClock();

    APM.$setHostApi(mockHost);
    LCQDateTime.setInstance(mockDateTime);
    LuciqMonotonicClock.setInstance(mockClock);

    // Clear active spans before each test
    APM.$clearActiveSpans();
  });

  tearDown(() {
    // Reset to real instances would need to be done differently
    // since we don't have access to the private constructors
  });

  group('CustomSpan', () {
    group('Creation', () {
      test('creates span with current timestamps', () {
        const startTime = 1000000;
        const startMonotonic = 2000000;

        when(mockDateTime.now()).thenReturn(
          DateTime.fromMicrosecondsSinceEpoch(startTime),
        );
        when(mockClock.now).thenReturn(startMonotonic);

        final span = CustomSpan('Test Span');

        expect(span.name, 'Test Span');
        expect(span.toString(), contains('Test Span'));
        expect(span.toString(), contains('hasEnded: false'));
      });

      test('name property returns correct value', () {
        const startTime = 1000000;
        when(mockDateTime.now()).thenReturn(
          DateTime.fromMicrosecondsSinceEpoch(startTime),
        );
        when(mockClock.now).thenReturn(2000000);

        final span = CustomSpan('My Custom Span');

        expect(span.name, equals('My Custom Span'));
      });
    });

    group('end()', () {
      test('calculates duration and syncs to native', () async {
        const startTime = 1000000;
        const startMonotonic = 2000000;
        const endMonotonic = 2500000; // 500000 microseconds later

        when(mockDateTime.now()).thenReturn(
          DateTime.fromMicrosecondsSinceEpoch(startTime),
        );

        // Use thenAnswer with a counter to return different values on each call
        var clockCallCount = 0;
        when(mockClock.now).thenAnswer((_) {
          clockCallCount++;
          return clockCallCount == 1 ? startMonotonic : endMonotonic;
        });

        final span = CustomSpan('Test Span');
        await span.end();

        verify(mockHost.syncCustomSpan(
          'Test Span',
          startTime,
          1500000, // startTime + 500000 duration
        )).called(1);

        expect(span.toString(), contains('hasEnded: true'));
        expect(span.toString(), contains('duration: 500000'));
      });

      test('prevents double ending', () async {
        const startTime = 1000000;
        const startMonotonic = 2000000;
        const endMonotonic = 2500000;

        when(mockDateTime.now()).thenReturn(
          DateTime.fromMicrosecondsSinceEpoch(startTime),
        );

        var clockCallCount = 0;
        when(mockClock.now).thenAnswer((_) {
          clockCallCount++;
          return clockCallCount == 1 ? startMonotonic : endMonotonic;
        });

        final span = CustomSpan('Test Span');
        await span.end();
        await span.end(); // Second call should be ignored

        verify(mockHost.syncCustomSpan(any, any, any)).called(1);
      });

      test(
          'handles zero duration - does not sync because end must be after start',
          () async {
        const startTime = 1000000;
        const monotonicTime = 2000000;

        when(mockDateTime.now()).thenReturn(
          DateTime.fromMicrosecondsSinceEpoch(startTime),
        );
        // Return same monotonic time for both calls (instant duration)
        when(mockClock.now).thenReturn(monotonicTime);

        final span = CustomSpan('Quick Span');
        await span.end();

        // Duration is 0, which means endTime = startTime
        // $syncCustomSpan validates end > start, so this should NOT sync
        verifyNever(mockHost.syncCustomSpan(any, any, any));

        expect(span.toString(), contains('duration: 0'));
        expect(span.toString(), contains('hasEnded: true'));
      });

      test('handles very long duration correctly', () async {
        const startTime = 1000000;
        const startMonotonic = 0;
        const endMonotonic = 3600000000; // 1 hour in microseconds

        when(mockDateTime.now()).thenReturn(
          DateTime.fromMicrosecondsSinceEpoch(startTime),
        );

        var clockCallCount = 0;
        when(mockClock.now).thenAnswer((_) {
          clockCallCount++;
          return clockCallCount == 1 ? startMonotonic : endMonotonic;
        });

        final span = CustomSpan('Long Span');
        await span.end();

        verify(mockHost.syncCustomSpan(
          'Long Span',
          startTime,
          startTime + 3600000000,
        )).called(1);
      });

      test('unregisters span from APM active spans', () async {
        const startTime = 1000000;

        when(mockDateTime.now()).thenReturn(
          DateTime.fromMicrosecondsSinceEpoch(startTime),
        );

        var clockCallCount = 0;
        when(mockClock.now).thenAnswer((_) {
          clockCallCount++;
          return 2000000 + (clockCallCount * 1000);
        });

        // Manually register the span (simulating startCustomSpan behavior)
        final span = CustomSpan('Test Span');
        APM.$registerSpan(span);

        expect(APM.activeSpanCount, 1);

        await span.end();

        expect(APM.activeSpanCount, 0);
      });
    });

    group('Thread Safety', () {
      test('is thread-safe with concurrent calls to end()', () async {
        const startTime = 1000000;
        const startMonotonic = 2000000;
        const endMonotonic = 2500000;

        when(mockDateTime.now()).thenReturn(
          DateTime.fromMicrosecondsSinceEpoch(startTime),
        );

        var clockCallCount = 0;
        when(mockClock.now).thenAnswer((_) {
          clockCallCount++;
          return clockCallCount == 1 ? startMonotonic : endMonotonic;
        });

        final span = CustomSpan('Concurrent Span');

        // Call end() concurrently multiple times
        await Future.wait([
          span.end(),
          span.end(),
          span.end(),
          span.end(),
          span.end(),
        ]);

        // Should only sync once despite concurrent calls
        verify(mockHost.syncCustomSpan(any, any, any)).called(1);
      });

      test('handles rapid sequential calls correctly', () async {
        const startTime = 1000000;

        when(mockDateTime.now()).thenReturn(
          DateTime.fromMicrosecondsSinceEpoch(startTime),
        );

        var clockCallCount = 0;
        when(mockClock.now).thenAnswer((_) {
          clockCallCount++;
          return 2000000 + (clockCallCount * 1000);
        });

        final span = CustomSpan('Rapid Span');

        // Sequential rapid calls
        await span.end();
        await span.end();
        await span.end();

        verify(mockHost.syncCustomSpan(any, any, any)).called(1);
      });
    });

    group('Multiple Concurrent Spans', () {
      test('can be active and ended concurrently', () async {
        const baseTime = 1000000;

        var dateTimeCallCount = 0;
        when(mockDateTime.now()).thenAnswer((_) {
          dateTimeCallCount++;
          return DateTime.fromMicrosecondsSinceEpoch(
            baseTime + (dateTimeCallCount * 100000),
          );
        });

        var clockCallCount = 0;
        when(mockClock.now).thenAnswer((_) {
          clockCallCount++;
          return 2000000 + (clockCallCount * 50000);
        });

        final span1 = CustomSpan('Span 1');
        final span2 = CustomSpan('Span 2');
        final span3 = CustomSpan('Span 3');

        // End all spans concurrently
        await Future.wait([
          span1.end(),
          span2.end(),
          span3.end(),
        ]);

        verify(mockHost.syncCustomSpan('Span 1', any, any)).called(1);
        verify(mockHost.syncCustomSpan('Span 2', any, any)).called(1);
        verify(mockHost.syncCustomSpan('Span 3', any, any)).called(1);
      });

      test('each span tracks its own state independently', () async {
        const baseTime = 1000000;

        var dateTimeCallCount = 0;
        when(mockDateTime.now()).thenAnswer((_) {
          dateTimeCallCount++;
          return DateTime.fromMicrosecondsSinceEpoch(
            baseTime + (dateTimeCallCount * 100000),
          );
        });

        var clockCallCount = 0;
        when(mockClock.now).thenAnswer((_) {
          clockCallCount++;
          return 2000000 + (clockCallCount * 50000);
        });

        final span1 = CustomSpan('Span 1');
        final span2 = CustomSpan('Span 2');

        // End only span1
        await span1.end();

        // Verify span1 is ended but span2 is not
        expect(span1.toString(), contains('hasEnded: true'));
        expect(span2.toString(), contains('hasEnded: false'));

        // Now end span2
        await span2.end();

        expect(span2.toString(), contains('hasEnded: true'));

        // Both should have been synced exactly once
        verify(mockHost.syncCustomSpan('Span 1', any, any)).called(1);
        verify(mockHost.syncCustomSpan('Span 2', any, any)).called(1);
      });
    });

    group('toString()', () {
      test('shows correct state before end()', () {
        const startTime = 1000000;
        when(mockDateTime.now()).thenReturn(
          DateTime.fromMicrosecondsSinceEpoch(startTime),
        );
        when(mockClock.now).thenReturn(2000000);

        final span = CustomSpan('Debug Span');
        final str = span.toString();

        expect(str, contains('name: Debug Span'));
        expect(str, contains('hasEnded: false'));
        expect(str, contains('duration: null'));
      });

      test('shows correct state after end()', () async {
        const startTime = 1000000;

        when(mockDateTime.now()).thenReturn(
          DateTime.fromMicrosecondsSinceEpoch(startTime),
        );

        var clockCallCount = 0;
        when(mockClock.now).thenAnswer((_) {
          clockCallCount++;
          return clockCallCount == 1 ? 2000000 : 2500000;
        });

        final span = CustomSpan('Debug Span');
        await span.end();
        final str = span.toString();

        expect(str, contains('name: Debug Span'));
        expect(str, contains('hasEnded: true'));
        expect(str, contains('duration: 500000'));
      });
    });
  });
}
