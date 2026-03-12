import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luciq_flutter/luciq_flutter.dart';
import 'package:luciq_flutter/src/utils/screen_loading/screen_loading_stage.dart';
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
      capturedTrace =
          invocation.positionalArguments[0] as ScreenLoadingTrace;
      return true;
    });

    when(mockScreenLoadingManager.currentScreenLoadingTrace)
        .thenAnswer((_) => capturedTrace);
  }

  testWidgets(
      'LuciqCaptureScreenLoading (default constructor, isManual=true) starts trace and reports manual screen loading',
      (WidgetTester tester) async {
    const screenName = "/TestScreen";

    when(mockScreenLoadingManager.sanitizeScreenName(screenName))
        .thenReturn(screenName);
    stubStartAndCaptureTrace();
    when(mockScreenLoadingManager.reportManualScreenLoading(any, any, any, stages: anyNamed('stages')))
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
    verify(mockScreenLoadingManager.reportManualScreenLoading(
      screenName,
      any,
      any,
      stages: anyNamed('stages'),
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
        mockScreenLoadingManager.reportManualScreenLoading(any, any, any, stages: anyNamed('stages')),);
  });

  testWidgets(
      'Manual mode: trace has endTimeInMicroseconds and duration set after build (endScreenLoading prerequisite)',
      (WidgetTester tester) async {
    const screenName = "/TestScreen";

    when(mockScreenLoadingManager.sanitizeScreenName(screenName))
        .thenReturn(screenName);
    stubStartAndCaptureTrace();
    when(mockScreenLoadingManager.reportManualScreenLoading(any, any, any, stages: anyNamed('stages')))
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
      'Nested LuciqCaptureScreenLoading (isManual=true) only reports once for the parent',
      (WidgetTester tester) async {
    const screenName = "/TestScreen";

    when(mockScreenLoadingManager.sanitizeScreenName(screenName))
        .thenReturn(screenName);
    stubStartAndCaptureTrace();
    when(mockScreenLoadingManager.reportManualScreenLoading(any, any, any, stages: anyNamed('stages')))
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

    // Only the parent (whose trace matches currentScreenLoadingTrace) reports
    verify(mockScreenLoadingManager.reportManualScreenLoading(
      screenName,
      any,
      any,
      stages: anyNamed('stages'),
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
        mockScreenLoadingManager.reportManualScreenLoading(any, any, any, stages: anyNamed('stages')),);
  });

  testWidgets(
      'LuciqCaptureScreenLoading collects 4 lifecycle stages in correct order',
      (WidgetTester tester) async {
    const screenName = "/StagesTest";
    List<ScreenLoadingStage>? reportedStages;

    when(mockScreenLoadingManager.sanitizeScreenName(screenName))
        .thenReturn(screenName);
    stubStartAndCaptureTrace();
    when(mockScreenLoadingManager.reportManualScreenLoading(any, any, any, stages: anyNamed('stages')))
        .thenAnswer((invocation) async {
      reportedStages =
          invocation.namedArguments[#stages] as List<ScreenLoadingStage>?;
    });

    await tester.pumpWidget(
      MaterialApp(
        home: LuciqCaptureScreenLoading(
          screenName: screenName,
          child: Container(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(reportedStages, isNotNull);
    expect(reportedStages!.length, 4);
    expect(
        reportedStages![0].type, ScreenLoadingStageType.initState,);
    expect(reportedStages![1].type,
        ScreenLoadingStageType.didChangeDependencies,);
    expect(reportedStages![2].type, ScreenLoadingStageType.build);
    expect(reportedStages![3].type,
        ScreenLoadingStageType.postFrameRender,);

    // All stages should have non-negative durations
    for (final stage in reportedStages!) {
      expect(stage.durationInMicroseconds, greaterThanOrEqualTo(0));
      expect(
          stage.startMonotonicTimeInMicroseconds, greaterThanOrEqualTo(0),);
    }
  });
}
