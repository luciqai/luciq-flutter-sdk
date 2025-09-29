import 'package:flutter/foundation.dart';
import 'package:luciq_flutter/src/models/luciq_frame_data.dart';
import 'package:luciq_flutter/src/utils/lcq_date_time.dart';

class LuciqScreenRenderData {
  int traceId;
  int slowFramesTotalDurationMicro;
  int frozenFramesTotalDurationMicro;
  int? endTimeMicro;
  List<LuciqFrameData> frameData;

  LuciqScreenRenderData({
    this.slowFramesTotalDurationMicro = 0,
    this.frozenFramesTotalDurationMicro = 0,
    this.endTimeMicro,
    required this.frameData,
    this.traceId = -1,
  });

  bool get isEmpty => frameData.isEmpty;

  bool get isNotEmpty => frameData.isNotEmpty;

  bool get isActive => traceId != -1;

  void clear() {
    traceId = -1;
    frozenFramesTotalDurationMicro = 0;
    slowFramesTotalDurationMicro = 0;
    frameData.clear();
  }

  void saveEndTime() =>
      endTimeMicro = LCQDateTime.I.now().microsecondsSinceEpoch;

  @override
  String toString() => '\nTraceId: $traceId\n'
      'SlowFramesTotalDuration: $slowFramesTotalDurationMicro\n'
      'FrozenFramesTotalDuration: $frozenFramesTotalDurationMicro\n'
      'EndTime: $endTimeMicro\n'
      'FrameData: [${frameData.map((element) => '$element')}]';

  @override
  // ignore: hash_and_equals
  bool operator ==(covariant LuciqScreenRenderData other) {
    if (identical(this, other)) return true;
    return traceId == other.traceId &&
        slowFramesTotalDurationMicro == other.slowFramesTotalDurationMicro &&
        frozenFramesTotalDurationMicro ==
            other.frozenFramesTotalDurationMicro &&
        listEquals(frameData, other.frameData);
  }

  /// Serializes the object to a Map for efficient channel transfer.
  Map<String, dynamic> toMap() {
    return {
      'traceId': traceId,
      'slowFramesTotalDuration': slowFramesTotalDurationMicro,
      'frozenFramesTotalDuration': frozenFramesTotalDurationMicro,
      'endTime': endTimeMicro,
      // Convert List<LuciqFrameData> to List<List<int>>
      'frameData': frameData.map((frame) => frame.toList()).toList(),
    };
  }
}
