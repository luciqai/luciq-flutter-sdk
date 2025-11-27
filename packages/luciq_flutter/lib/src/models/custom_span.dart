import 'dart:async';

import 'package:luciq_flutter/src/modules/apm.dart';
import 'package:luciq_flutter/src/utils/lcq_date_time.dart';
import 'package:luciq_flutter/src/utils/luciq_montonic_clock.dart';

/// Represents a custom span for performance tracking.
class CustomSpan {
  /// Creates a new custom span with the given name.
  /// The span starts immediately upon creation.
  CustomSpan(this.name)
      : _startTimeInMicroseconds = LCQDateTime.I.now().microsecondsSinceEpoch,
        _startMonotonicTimeInMicroseconds = LuciqMonotonicClock.I.now;

  /// The name of the custom span (max 150 characters).
  final String name;

  /// Unix epoch timestamp when the span started (microseconds).
  final int _startTimeInMicroseconds;

  /// Monotonic clock timestamp for accurate duration measurement.
  final int _startMonotonicTimeInMicroseconds;

  /// Unix epoch timestamp when the span ended (microseconds).
  int? _endTimeInMicroseconds;

  /// Duration of the span in microseconds.
  int? _duration;

  /// Whether this span has been ended.
  bool _hasEnded = false;

  /// Lock to ensure thread-safe ending of the span.
  Completer<void>? _endLock;

  /// Ends this custom span and reports it to the native SDK.
  /// This method is thread-safe and will only execute once even if called
  /// concurrently from multiple isolates.
  Future<void> end() async {
    // Thread-safe check and set using a Completer as a lock
    if (_hasEnded) {
      // If already ended, wait for any in-progress end operation
      if (_endLock != null && !_endLock!.isCompleted) {
        await _endLock!.future;
      }
      return; // Prevent double ending
    }

    // Check again after potential async yield
    if (_hasEnded) {
      return;
    }

    // Set up the lock before marking as ended
    _endLock = Completer<void>();
    _hasEnded = true;

    try {
      // Unregister from active spans
      APM.$unregisterSpan(this);

      // Calculate duration using monotonic clock
      final endMonotonicTime = LuciqMonotonicClock.I.now;
      _duration = endMonotonicTime - _startMonotonicTimeInMicroseconds;

      // Calculate end time using wall clock
      _endTimeInMicroseconds = _startTimeInMicroseconds + _duration!;

      // Send to native SDK
      await APM.$syncCustomSpan(
        name,
        _startTimeInMicroseconds,
        _endTimeInMicroseconds!,
      );
    } finally {
      // Complete the lock to allow waiting callers to proceed
      _endLock!.complete();
    }
  }

  @override
  String toString() {
    return 'CustomSpan{name: $name, hasEnded: $_hasEnded, '
        'duration: $_duration}';
  }
}
