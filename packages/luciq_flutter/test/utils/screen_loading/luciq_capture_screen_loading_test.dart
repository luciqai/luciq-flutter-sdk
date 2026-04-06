import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luciq_flutter/luciq_flutter.dart';
import 'package:luciq_flutter/src/utils/screen_loading/screen_loading_trace.dart';
import 'package:mockito/mockito.dart';

import '../luciq_navigator_observer_test.mocks.dart';

void main() {
  late MockScreenLoadingManager mockScreenLoadingManager;

  setUp(() {
    mockScreenLoadingManager = MockScreenLoadingManager();
    ScreenLoadingManager.setInstance(mockScreenLoadingManager);
  });

  /// Stubs [startScreenLoadingTrace] to capture the first trace as the
  /// "winning" trace, and makes [currentScreenLoadingTrace] return it.
  /// This mirrors the real [ScreenLoadingManager] behavior where only
  /// the first call sets [currentScreenLoadingTrace] and returns `true`.
  void stubStartAndCaptureTrace() {
    ScreenLoadingTrace? capturedTrace;

    when(mockScreenLoadingManager.startScreenLoadingTrace(any))
        .thenAnswer((invocation) async {
      if (capturedTrace != null) return false;
      capturedTrace = invocation.positionalArguments[0] as ScreenLoadingTrace;
      return true;
    });

    when(mockScreenLoadingManager.currentScreenLoadingTrace)
        .thenAnswer((_) => capturedTrace);
  }

  /// Stubs [claimManualScreenLoadingTrace] to capture the first trace as the
  /// "winning" manual trace — only the first call returns `true`.
  void stubClaimManualTrace() {
    var claimed = false;

    when(mockScreenLoadingManager.claimManualScreenLoadingTrace(any))
        .thenAnswer((invocation) {
      if (claimed) return false;
      claimed = true;
      return true;
    });
  }

  testWidgets(
      'default constructor with matching UI trace reports via automatic path',
      (WidgetTester tester) async {
    const screenName = "/TestScreen";

    when(mockScreenLoadingManager.sanitizeScreenName(screenName))
        .thenReturn(screenName);
    stubStartAndCaptureTrace();
    // claimManualScreenLoadingTrace returns false because auto trace started
    when(mockScreenLoadingManager.claimManualScreenLoadingTrace(any))
        .thenReturn(false);
    when(mockScreenLoadingManager.reportScreenLoading(any))
        .thenAnswer((_) async {});

    await tester.pumpWidget(
      MaterialApp(
        home: LuciqCaptureScreenLoading(
          screenName: screenName,
          child: Container(),
        ),
      ),
    );

    verify(mockScreenLoadingManager.startScreenLoadingTrace(any)).called(1);
    await tester.pumpAndSettle();
    verify(mockScreenLoadingManager.reportScreenLoading(any)).called(1);
    verifyNever(
        mockScreenLoadingManager.reportManualScreenLoading(any, any, any),);
  });

  testWidgets(
      'default constructor without matching UI trace reports via manual path',
      (WidgetTester tester) async {
    const screenName = "/TestScreen";

    when(mockScreenLoadingManager.sanitizeScreenName(screenName))
        .thenReturn(screenName);
    // No UI trace → startScreenLoadingTrace always returns false
    when(mockScreenLoadingManager.startScreenLoadingTrace(any))
        .thenAnswer((_) async => false);
    stubClaimManualTrace();
    when(mockScreenLoadingManager.reportManualScreenLoading(any, any, any))
        .thenAnswer((_) async {});

    await tester.pumpWidget(
      MaterialApp(
        home: LuciqCaptureScreenLoading(
          screenName: screenName,
          child: Container(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    verify(mockScreenLoadingManager.reportManualScreenLoading(
      screenName,
      any,
      any,
    ),).called(1);
    verifyNever(mockScreenLoadingManager.reportScreenLoading(any));
  });

  testWidgets(
      'LuciqCaptureScreenLoading.withConfig (isManual=false) starts trace and reports automatic screen loading',
      (WidgetTester tester) async {
    const screenName = "/TestScreen";

    when(mockScreenLoadingManager.sanitizeScreenName(screenName))
        .thenReturn(screenName);
    stubStartAndCaptureTrace();
    when(mockScreenLoadingManager.reportScreenLoading(any))
        .thenAnswer((_) async {});

    await tester.pumpWidget(
      MaterialApp(
        home: LuciqCaptureScreenLoading.withConfig(
          screenName: screenName,
          isManual: false,
          child: Container(),
        ),
      ),
    );

    verify(mockScreenLoadingManager.startScreenLoadingTrace(any)).called(1);
    await tester.pumpAndSettle();
    verify(mockScreenLoadingManager.reportScreenLoading(any)).called(1);
    verifyNever(
        mockScreenLoadingManager.reportManualScreenLoading(any, any, any),);
  });

  testWidgets(
      'Manual mode: trace has endTimeInMicroseconds and duration set after build (endScreenLoading prerequisite)',
      (WidgetTester tester) async {
    const screenName = "/TestScreen";

    when(mockScreenLoadingManager.sanitizeScreenName(screenName))
        .thenReturn(screenName);
    stubStartAndCaptureTrace();
    // claimManualScreenLoadingTrace returns false because auto trace started
    when(mockScreenLoadingManager.claimManualScreenLoadingTrace(any))
        .thenReturn(false);
    when(mockScreenLoadingManager.reportScreenLoading(any))
        .thenAnswer((_) async {});

    await tester.pumpWidget(
      MaterialApp(
        home: LuciqCaptureScreenLoading(
          screenName: screenName,
          child: Container(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final trace = mockScreenLoadingManager.currentScreenLoadingTrace;
    expect(trace, isNotNull);
    expect(trace!.endTimeInMicroseconds, isNotNull,
        reason: 'endTimeInMicroseconds must be set for endScreenLoading',);
    expect(trace.duration, isNotNull,
        reason: 'duration must be set for endScreenLoading',);
    expect(trace.duration, greaterThanOrEqualTo(0));
    expect(trace.endTimeInMicroseconds,
        equals(trace.startTimeInMicroseconds + trace.duration!),);
  });

  testWidgets(
      'Automatic mode: trace has endTimeInMicroseconds and duration set after build (endScreenLoading prerequisite)',
      (WidgetTester tester) async {
    const screenName = "/TestScreen";

    when(mockScreenLoadingManager.sanitizeScreenName(screenName))
        .thenReturn(screenName);
    stubStartAndCaptureTrace();
    when(mockScreenLoadingManager.reportScreenLoading(any))
        .thenAnswer((_) async {});

    await tester.pumpWidget(
      MaterialApp(
        home: LuciqCaptureScreenLoading.withConfig(
          screenName: screenName,
          isManual: false,
          child: Container(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final trace = mockScreenLoadingManager.currentScreenLoadingTrace;
    expect(trace, isNotNull);
    expect(trace!.endTimeInMicroseconds, isNotNull,
        reason: 'endTimeInMicroseconds must be set for endScreenLoading',);
    expect(trace.duration, isNotNull,
        reason: 'duration must be set for endScreenLoading',);
    expect(trace.duration, greaterThanOrEqualTo(0));
    expect(trace.endTimeInMicroseconds,
        equals(trace.startTimeInMicroseconds + trace.duration!),);
  });

  testWidgets(
      'Nested LuciqCaptureScreenLoading (isManual=true) with matching UI trace only reports automatic once',
      (WidgetTester tester) async {
    const screenName = "/TestScreen";

    when(mockScreenLoadingManager.sanitizeScreenName(screenName))
        .thenReturn(screenName);
    stubStartAndCaptureTrace();
    // claimManualScreenLoadingTrace returns false because auto trace started
    when(mockScreenLoadingManager.claimManualScreenLoadingTrace(any))
        .thenReturn(false);
    when(mockScreenLoadingManager.reportScreenLoading(any))
        .thenAnswer((_) async {});

    await tester.pumpWidget(
      MaterialApp(
        home: LuciqCaptureScreenLoading(
          screenName: screenName,
          child: LuciqCaptureScreenLoading(
            screenName: screenName,
            child: LuciqCaptureScreenLoading(
              screenName: screenName,
              child: Container(),
            ),
          ),
        ),
      ),
    );

    verify(mockScreenLoadingManager.startScreenLoadingTrace(any)).called(3);
    await tester.pumpAndSettle();

    // Only the parent (whose trace matches currentScreenLoadingTrace) reports via auto path
    verify(mockScreenLoadingManager.reportScreenLoading(any)).called(1);
    verifyNever(
        mockScreenLoadingManager.reportManualScreenLoading(any, any, any),);
  });

  testWidgets(
      'Nested manual widgets without UI trace — only parent reports manual',
      (WidgetTester tester) async {
    const screenName = "/TestScreen";

    when(mockScreenLoadingManager.sanitizeScreenName(screenName))
        .thenReturn(screenName);
    // No UI trace → startScreenLoadingTrace always returns false
    when(mockScreenLoadingManager.startScreenLoadingTrace(any))
        .thenAnswer((_) async => false);
    stubClaimManualTrace();
    when(mockScreenLoadingManager.reportManualScreenLoading(any, any, any))
        .thenAnswer((_) async {});

    await tester.pumpWidget(
      MaterialApp(
        home: LuciqCaptureScreenLoading(
          screenName: screenName,
          child: LuciqCaptureScreenLoading(
            screenName: screenName,
            child: LuciqCaptureScreenLoading(
              screenName: screenName,
              child: Container(),
            ),
          ),
        ),
      ),
    );

    verify(mockScreenLoadingManager.startScreenLoadingTrace(any)).called(3);
    await tester.pumpAndSettle();

    // Only the parent (who claimed manual) reports
    verify(mockScreenLoadingManager.reportManualScreenLoading(
      screenName,
      any,
      any,
    ),).called(1);
    verifyNever(mockScreenLoadingManager.reportScreenLoading(any));
  });

  testWidgets(
      'Nested LuciqCaptureScreenLoading.withConfig (isManual=false) only reports once for the parent',
      (WidgetTester tester) async {
    const screenName = "/TestScreen";

    when(mockScreenLoadingManager.sanitizeScreenName(screenName))
        .thenReturn(screenName);
    stubStartAndCaptureTrace();
    when(mockScreenLoadingManager.reportScreenLoading(any))
        .thenAnswer((_) async {});

    await tester.pumpWidget(
      MaterialApp(
        home: LuciqCaptureScreenLoading.withConfig(
          screenName: screenName,
          isManual: false,
          child: LuciqCaptureScreenLoading.withConfig(
            screenName: screenName,
            isManual: false,
            child: LuciqCaptureScreenLoading.withConfig(
              screenName: screenName,
              isManual: false,
              child: Container(),
            ),
          ),
        ),
      ),
    );

    verify(mockScreenLoadingManager.startScreenLoadingTrace(any)).called(3);
    await tester.pumpAndSettle();

    // Only the parent (whose trace matches currentScreenLoadingTrace) reports
    verify(mockScreenLoadingManager.reportScreenLoading(any)).called(1);
    verifyNever(
        mockScreenLoadingManager.reportManualScreenLoading(any, any, any),);
  });

  testWidgets('dispose releases manual claim', (WidgetTester tester) async {
    const screenName = "/TestScreen";

    when(mockScreenLoadingManager.sanitizeScreenName(screenName))
        .thenReturn(screenName);
    when(mockScreenLoadingManager.startScreenLoadingTrace(any))
        .thenAnswer((_) async => false);
    stubClaimManualTrace();
    when(mockScreenLoadingManager.reportManualScreenLoading(any, any, any))
        .thenAnswer((_) async {});

    await tester.pumpWidget(
      MaterialApp(
        home: LuciqCaptureScreenLoading(
          screenName: screenName,
          child: Container(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Now dispose the widget by pumping a different widget
    await tester.pumpWidget(
      MaterialApp(
        home: Container(),
      ),
    );

    verify(mockScreenLoadingManager.releaseManualScreenLoadingTrace(screenName))
        .called(1);
  });
}
