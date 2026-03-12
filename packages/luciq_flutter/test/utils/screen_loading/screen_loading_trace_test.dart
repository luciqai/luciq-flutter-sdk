import 'package:flutter_test/flutter_test.dart';
import 'package:luciq_flutter/src/utils/screen_loading/screen_loading_stage.dart';
import 'package:luciq_flutter/src/utils/screen_loading/screen_loading_trace.dart';

void main() {
  test(
      'ScreenLoadingTrace copyWith method should keep original values when no override happens',
      () {
    final trace = ScreenLoadingTrace(
      'TestScreen',
      startTimeInMicroseconds: 1000,
      startMonotonicTimeInMicroseconds: 2000,
      endTimeInMicroseconds: 3000,
      duration: 4000,
    );

    final updatedTrace = trace.copyWith();

    expect(updatedTrace.screenName, 'TestScreen');
    expect(updatedTrace.startTimeInMicroseconds, 1000);
    expect(updatedTrace.startMonotonicTimeInMicroseconds, 2000);
    expect(updatedTrace.endTimeInMicroseconds, 3000);
    expect(updatedTrace.duration, 4000);
  });

  test('ScreenLoadingTrace copyWith method updates fields correctly', () {
    final trace = ScreenLoadingTrace(
      'TestScreen',
      startTimeInMicroseconds: 1000,
      startMonotonicTimeInMicroseconds: 2000,
      endTimeInMicroseconds: 3000,
      duration: 4000,
    );

    final updatedTrace = trace.copyWith(
      startTimeInMicroseconds: 1500,
      startMonotonicTimeInMicroseconds: 2500,
      endTimeInMicroseconds: 3500,
      duration: 4500,
    );

    expect(updatedTrace.screenName, 'TestScreen');
    expect(updatedTrace.startTimeInMicroseconds, 1500);
    expect(updatedTrace.startMonotonicTimeInMicroseconds, 2500);
    expect(updatedTrace.endTimeInMicroseconds, 3500);
    expect(updatedTrace.duration, 4500);
  });

  test('ScreenLoadingTrace toString method returns correct format', () {
    final trace = ScreenLoadingTrace(
      'TestScreen',
      startTimeInMicroseconds: 1000,
      startMonotonicTimeInMicroseconds: 2000,
      endTimeInMicroseconds: 3000,
      duration: 4000,
    );

    expect(
      trace.toString(),
      'ScreenLoadingTrace{screenName: TestScreen, startTimeInMicroseconds: 1000, startMonotonicTimeInMicroseconds: 2000, endTimeInMicroseconds: 3000, duration: 4000, stages: []}',
    );
  });

  test('ScreenLoadingTrace defaults to empty stages list', () {
    final trace = ScreenLoadingTrace(
      'TestScreen',
      startTimeInMicroseconds: 1000,
      startMonotonicTimeInMicroseconds: 2000,
    );

    expect(trace.stages, isEmpty);
  });

  test('ScreenLoadingTrace copyWith preserves stages when not overridden', () {
    final stages = [
      const ScreenLoadingStage(
        type: ScreenLoadingStageType.initState,
        startMonotonicTimeInMicroseconds: 100,
        durationInMicroseconds: 50,
      ),
    ];
    final trace = ScreenLoadingTrace(
      'TestScreen',
      startTimeInMicroseconds: 1000,
      startMonotonicTimeInMicroseconds: 2000,
      stages: stages,
    );

    final copied = trace.copyWith(duration: 5000);

    expect(copied.stages, equals(stages));
    expect(copied.duration, 5000);
  });

  test('ScreenLoadingTrace copyWith can override stages', () {
    final trace = ScreenLoadingTrace(
      'TestScreen',
      startTimeInMicroseconds: 1000,
      startMonotonicTimeInMicroseconds: 2000,
    );

    final newStages = [
      const ScreenLoadingStage(
        type: ScreenLoadingStageType.build,
        startMonotonicTimeInMicroseconds: 200,
        durationInMicroseconds: 30,
      ),
    ];
    final copied = trace.copyWith(stages: newStages);

    expect(copied.stages, equals(newStages));
  });
}
