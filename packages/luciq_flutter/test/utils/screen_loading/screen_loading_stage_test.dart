import 'package:flutter_test/flutter_test.dart';
import 'package:luciq_flutter/src/utils/screen_loading/screen_loading_stage.dart';

void main() {
  group('ScreenLoadingStage', () {
    test('toMap serializes correctly', () {
      const stage = ScreenLoadingStage(
        type: ScreenLoadingStageType.initState,
        startMonotonicTimeInMicroseconds: 1000,
        durationInMicroseconds: 500,
      );

      final map = stage.toMap();

      expect(map['type'], 'initState');
      expect(map['startMonotonicTimeInMicroseconds'], 1000);
      expect(map['durationInMicroseconds'], 500);
    });

    test('toMap serializes all stage types', () {
      for (final type in ScreenLoadingStageType.values) {
        final stage = ScreenLoadingStage(
          type: type,
          startMonotonicTimeInMicroseconds: 0,
          durationInMicroseconds: 0,
        );
        expect(stage.toMap()['type'], type.name);
      }
    });

    test('toString returns correct format', () {
      const stage = ScreenLoadingStage(
        type: ScreenLoadingStageType.build,
        startMonotonicTimeInMicroseconds: 2000,
        durationInMicroseconds: 300,
      );

      expect(
        stage.toString(),
        'ScreenLoadingStage{type: build, startMonotonicTimeInMicroseconds: 2000, durationInMicroseconds: 300}',
      );
    });

    test('equality works correctly', () {
      const stage1 = ScreenLoadingStage(
        type: ScreenLoadingStageType.postFrameRender,
        startMonotonicTimeInMicroseconds: 100,
        durationInMicroseconds: 200,
      );
      const stage2 = ScreenLoadingStage(
        type: ScreenLoadingStageType.postFrameRender,
        startMonotonicTimeInMicroseconds: 100,
        durationInMicroseconds: 200,
      );
      const stage3 = ScreenLoadingStage(
        type: ScreenLoadingStageType.build,
        startMonotonicTimeInMicroseconds: 100,
        durationInMicroseconds: 200,
      );

      expect(stage1, equals(stage2));
      expect(stage1, isNot(equals(stage3)));
    });

    test('hashCode is consistent with equality', () {
      const stage1 = ScreenLoadingStage(
        type: ScreenLoadingStageType.didChangeDependencies,
        startMonotonicTimeInMicroseconds: 500,
        durationInMicroseconds: 100,
      );
      const stage2 = ScreenLoadingStage(
        type: ScreenLoadingStageType.didChangeDependencies,
        startMonotonicTimeInMicroseconds: 500,
        durationInMicroseconds: 100,
      );

      expect(stage1.hashCode, equals(stage2.hashCode));
    });
  });
}
