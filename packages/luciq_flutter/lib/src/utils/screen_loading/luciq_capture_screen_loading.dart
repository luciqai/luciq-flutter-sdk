import 'package:flutter/material.dart';
import 'package:luciq_flutter/src/utils/lcq_date_time.dart';
import 'package:luciq_flutter/src/utils/luciq_montonic_clock.dart';
import 'package:luciq_flutter/src/utils/screen_loading/screen_loading_manager.dart';
import 'package:luciq_flutter/src/utils/screen_loading/screen_loading_stage.dart';
import 'package:luciq_flutter/src/utils/screen_loading/screen_loading_trace.dart';
import 'package:meta/meta.dart';

/// A widget that tracks and reports screen loading times to Luciq.
///
/// This widget wraps around a child widget and measures the time taken
/// for the screen to fully render. The recorded loading time is reported
/// using the [ScreenLoadingManager].
///
/// ## Usage
/// ```dart
/// LuciqCaptureScreenLoading(
///   screenName: "HomeScreen",
///   child: HomeScreenWidget(),
/// )
/// ```
class LuciqCaptureScreenLoading extends StatefulWidget {
  /// A unique identifier for the widget used internally for debugging purposes.
  static const tag = "LuciqCaptureScreenLoading";

  /// Creates an instance of [LuciqCaptureScreenLoading].
  ///
  /// Requires [screenName] to identify the screen being tracked and [child]
  /// which represents the UI component to be rendered.
  const LuciqCaptureScreenLoading({
    Key? key,
    required this.screenName,
    required this.child,
  })  : isManual = true,
        super(key: key);

  /// Internal constructor that allows configuring [isManual].
  @internal
  const LuciqCaptureScreenLoading.withConfig({
    Key? key,
    required this.screenName,
    required this.child,
    this.isManual = true,
  }) : super(key: key);

  /// The UI component whose loading time is being measured.
  final Widget child;

  /// The name of the screen being monitored for loading performance.
  final String screenName;

  /// Whether the screen loading is manual or automatic.
  final bool isManual;

  @override
  State<LuciqCaptureScreenLoading> createState() =>
      _LuciqCaptureScreenLoadingState();
}

class _LuciqCaptureScreenLoadingState extends State<LuciqCaptureScreenLoading> {
  /// Trace object that records screen loading details.
  ScreenLoadingTrace? trace;

  /// Timestamp in microseconds when the widget is created.
  final startTimeInMicroseconds = LCQDateTime.I.now().microsecondsSinceEpoch;

  /// Monotonic timestamp in microseconds for more precise duration tracking.
  final startMonotonicTimeInMicroseconds = LuciqMonotonicClock.I.now;

  /// Stopwatch to measure screen loading time.
  final stopwatch = Stopwatch()..start();

  /// Collected lifecycle stages.
  final List<ScreenLoadingStage> _stages = [];

  /// Monotonic time at build completion, used as postFrameRender start.
  int _buildCompleteMicro = 0;

  @override
  void initState() {
    final initStateStart = LuciqMonotonicClock.I.now;
    super.initState();
    trace = ScreenLoadingTrace(
      ScreenLoadingManager.I.sanitizeScreenName(widget.screenName),
      startTimeInMicroseconds: startTimeInMicroseconds,
      startMonotonicTimeInMicroseconds: startMonotonicTimeInMicroseconds,
    );

    final didStartTrace =
        ScreenLoadingManager.I.startScreenLoadingTrace(trace!);

    // Ensures compatibility with Flutter versions before 3.0.0
    // ignore: invalid_null_aware_operator
    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      stopwatch.stop();
      final postFrameEnd = LuciqMonotonicClock.I.now;
      final duration = stopwatch.elapsedMicroseconds;
      trace?.duration = duration;
      trace?.endTimeInMicroseconds = startTimeInMicroseconds + duration;

      // Record postFrameRender stage
      if (_buildCompleteMicro > 0) {
        _stages.add(ScreenLoadingStage(
          type: ScreenLoadingStageType.postFrameRender,
          startMonotonicTimeInMicroseconds: _buildCompleteMicro,
          durationInMicroseconds: postFrameEnd - _buildCompleteMicro,
        ),);
      }

      trace?.stages = List.unmodifiable(_stages);

      if (!await didStartTrace) return;

      if (widget.isManual) {
        ScreenLoadingManager.I.reportManualScreenLoading(
          widget.screenName,
          startTimeInMicroseconds,
          duration,
          stages: trace?.stages ?? const [],
        );
      } else {
        ScreenLoadingManager.I.reportScreenLoading(trace);
      }
    });

    final initStateEnd = LuciqMonotonicClock.I.now;
    _stages.add(ScreenLoadingStage(
      type: ScreenLoadingStageType.initState,
      startMonotonicTimeInMicroseconds: initStateStart,
      durationInMicroseconds: initStateEnd - initStateStart,
    ),);
  }

  @override
  void didChangeDependencies() {
    final start = LuciqMonotonicClock.I.now;
    super.didChangeDependencies();
    final end = LuciqMonotonicClock.I.now;
    _stages.add(ScreenLoadingStage(
      type: ScreenLoadingStageType.didChangeDependencies,
      startMonotonicTimeInMicroseconds: start,
      durationInMicroseconds: end - start,
    ),);
  }

  @override
  Widget build(BuildContext context) {
    final buildStart = LuciqMonotonicClock.I.now;
    final child = widget.child;
    _buildCompleteMicro = LuciqMonotonicClock.I.now;
    _stages.add(ScreenLoadingStage(
      type: ScreenLoadingStageType.build,
      startMonotonicTimeInMicroseconds: buildStart,
      durationInMicroseconds: _buildCompleteMicro - buildStart,
    ),);
    return child;
  }
}
