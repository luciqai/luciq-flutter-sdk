/// The type of lifecycle stage tracked during screen loading.
enum ScreenLoadingStageType {
  initState,
  didChangeDependencies,
  build,
  postFrameRender,
}

/// An immutable record of a single lifecycle stage during screen loading.
class ScreenLoadingStage {
  const ScreenLoadingStage({
    required this.type,
    required this.startMonotonicTimeInMicroseconds,
    required this.durationInMicroseconds,
  });

  final ScreenLoadingStageType type;
  final int startMonotonicTimeInMicroseconds;
  final int durationInMicroseconds;

  /// Serializes to a Map for Pigeon channel transfer.
  Map<String, Object> toMap() {
    return {
      'type': type.name,
      'startMonotonicTimeInMicroseconds': startMonotonicTimeInMicroseconds,
      'durationInMicroseconds': durationInMicroseconds,
    };
  }

  @override
  String toString() {
    return 'ScreenLoadingStage{type: ${type.name}, startMonotonicTimeInMicroseconds: $startMonotonicTimeInMicroseconds, durationInMicroseconds: $durationInMicroseconds}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ScreenLoadingStage &&
        other.type == type &&
        other.startMonotonicTimeInMicroseconds ==
            startMonotonicTimeInMicroseconds &&
        other.durationInMicroseconds == durationInMicroseconds;
  }

  @override
  int get hashCode => Object.hash(
        type,
        startMonotonicTimeInMicroseconds,
        durationInMicroseconds,
      );
}
