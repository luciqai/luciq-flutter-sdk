import 'package:flutter/widgets.dart' show WidgetsBinding;
import 'package:luciq_flutter/src/constants/debug_tags.dart';
import 'package:luciq_flutter/src/generated/apm.api.g.dart';
import 'package:luciq_flutter/src/modules/apm.dart' show APM;
import 'package:luciq_flutter/src/utils/host_call.dart';
import 'package:luciq_flutter/src/utils/lcq_date_time.dart';
import 'package:luciq_flutter/src/utils/luciq_logger.dart';
import 'package:luciq_flutter/src/utils/luciq_montonic_clock.dart';
import 'package:meta/meta.dart';

/// Manager responsible for capturing a cold app launch as staged durations.
///
/// The Flutter layer observes three boundaries it can see - the `Luciq.init`
/// call (T1), the first rendered frame (T2), and the host's `endAppLaunch()`
/// signal (T3) - and reports the derived stage durations to native, which owns
/// the process-start anchor (T0) and computes stage 1.
///
/// Follows the established singleton manager pattern (see [CustomSpanManager],
/// [ScreenLoadingManager]): launch-start state must be captured before the SDK
/// is fully built and must survive between `Luciq.init` and `endAppLaunch()`.
@internal
class AppLaunchManager {
  AppLaunchManager._();

  static AppLaunchManager? _instance;

  /// Returns the singleton instance of [AppLaunchManager].
  //ignore:prefer_constructors_over_static_methods
  static AppLaunchManager get I => _instance ??= AppLaunchManager._();

  /// Shorthand for [I].
  static AppLaunchManager get instance => I;

  /// Sets a custom instance (for testing).
  @visibleForTesting
  // ignore: use_setters_to_change_properties
  static void setInstance(AppLaunchManager instance) {
    _instance = instance;
  }

  /// Resets the instance to null (for testing).
  @visibleForTesting
  static void resetInstance() {
    _instance = null;
  }

  /// Log tag for app launch operations.
  static const String tag = DebugTags.apmAppLaunch;

  ApmHostApi _host = ApmHostApi();

  /// Sets the host API for native communication.
  /// Called from [APM.$setHostApi] and tests.
  /// @nodoc
  @internal
  // ignore: use_setters_to_change_properties
  void $setHostApi(ApmHostApi host) {
    _host = host;
  }

  /// Wall-clock epoch of the Dart-entry boundary (T1), the anchor native aligns
  /// stage 1 to.
  int? _dartEntryEpochMicros;

  /// Monotonic timestamp of the Dart-entry boundary (T1).
  int? _dartEntryMonotonicMicros;

  /// Monotonic timestamp of the first rendered frame (T2).
  int? _firstFrameMonotonicMicros;

  /// Guards against tracking more than the first launch window.
  bool _dartEntryMarked = false;

  /// Captures the Dart-entry boundary (T1) and schedules first-frame capture.
  ///
  /// Called once from `Luciq.init`. Repeated calls (hot restart, re-init) are
  /// ignored so only the first launch window is tracked. If the binding is not
  /// initialized, the first-frame callback is never registered and the launch
  /// degrades to bulk-only.
  void markDartEntry() {
    if (_dartEntryMarked) {
      LuciqLogger.I.d(
        '[AppLaunchManager.markDartEntry] phase=enter skipped=alreadyMarked',
        tag: tag,
      );
      return;
    }
    _dartEntryMarked = true;
    _dartEntryEpochMicros = LCQDateTime.I.now().microsecondsSinceEpoch;
    _dartEntryMonotonicMicros = LuciqMonotonicClock.I.now;

    // Ensures compatibility with Flutter versions before 3.0.0
    // ignore: invalid_null_aware_operator
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      _firstFrameMonotonicMicros = LuciqMonotonicClock.I.now;
    });
  }

  /// Captures the interactive boundary (T3), reports the staged durations when
  /// all boundaries are present, then ends the launch on native.
  Future<void> reportStagesOnEndAppLaunch() async {
    final t1Epoch = _dartEntryEpochMicros;
    final t1Monotonic = _dartEntryMonotonicMicros;
    final t2Monotonic = _firstFrameMonotonicMicros;

    if (t1Epoch != null && t1Monotonic != null && t2Monotonic != null) {
      final t3Monotonic = LuciqMonotonicClock.I.now;
      final uiRenderDurationMicros = t2Monotonic - t1Monotonic;
      final interactiveDurationMicros = t3Monotonic - t2Monotonic;
      await APM.reportAppLaunchStages(
        t1Epoch,
        uiRenderDurationMicros,
        interactiveDurationMicros,
      );
    } else {
      LuciqLogger.I.d(
        '[AppLaunchManager.reportStagesOnEndAppLaunch] phase=enter '
        'skipped=missingBoundaries degradedTo=bulk',
        tag: tag,
      );
    }

    return hostCall(
      'APM.endAppLaunch',
      () => _host.endAppLaunch(),
      tag: tag,
    );
  }
}
