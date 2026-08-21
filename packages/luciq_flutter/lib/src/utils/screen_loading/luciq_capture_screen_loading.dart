import 'package:flutter/material.dart';
import 'package:luciq_flutter/src/utils/lcq_date_time.dart';
import 'package:luciq_flutter/src/utils/luciq_montonic_clock.dart';
import 'package:luciq_flutter/src/utils/screen_loading/screen_loading_manager.dart';
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

  /// Whether this widget claimed a manual screen loading trace.
  bool _didClaimManual = false;

  /// The sanitized screen name used for manual trace claiming.
  late final String _sanitizedScreenName;

  @override
  void initState() {
    super.initState();
    _sanitizedScreenName =
        ScreenLoadingManager.I.sanitizeScreenName(widget.screenName);
    trace = ScreenLoadingTrace(
      _sanitizedScreenName,
      startTimeInMicroseconds: startTimeInMicroseconds,
      startMonotonicTimeInMicroseconds: startMonotonicTimeInMicroseconds,
    );

    final didStartTrace =
        ScreenLoadingManager.I.startScreenLoadingTrace(trace!);

    // For manual widgets, also try to claim a manual slot
    // (for when no navigator observer fired)
    if (widget.isManual) {
      _didClaimManual =
          ScreenLoadingManager.I.claimManualScreenLoadingTrace(trace!);
    }

    // Ensures compatibility with Flutter versions before 3.0.0
    // ignore: invalid_null_aware_operator
    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      stopwatch.stop();
      final duration = stopwatch.elapsedMicroseconds;
      trace?.duration = duration;
      trace?.endTimeInMicroseconds = startTimeInMicroseconds + duration;

      if (widget.isManual) {
        final autoStarted = await didStartTrace;
        if (autoStarted) {
          // Navigator observer was triggered → use automatic path
          ScreenLoadingManager.I.reportScreenLoading(trace);
        } else if (_didClaimManual) {
          // No navigator observer → use manual path (this widget is the parent)
          ScreenLoadingManager.I.reportManualScreenLoading(
            widget.screenName,
            startTimeInMicroseconds,
            duration,
          );
        }
        // else: nested child with same screen name → skip
      } else {
        if (!await didStartTrace) return;
        ScreenLoadingManager.I.reportScreenLoading(trace);
      }
    });
  }

  @override
  void dispose() {
    if (_didClaimManual) {
      ScreenLoadingManager.I
          .releaseManualScreenLoadingTrace(_sanitizedScreenName);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
