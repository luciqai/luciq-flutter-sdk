import 'package:flutter/foundation.dart';

/// Short, opaque correlation id for async / callback APIs.
///
/// A new id is minted on the Dart side at the top of an async API call,
/// included in that call's enter/exit/error logs, and forwarded over the
/// Pigeon channel so the native plugin can echo it in its own logs. The
/// matching `phase=fire` callback log uses the same id so a single
/// end-to-end trace can be reconstructed by grepping a fixed token.
///
/// IDs are 4 lowercase hex chars derived from a process-local counter.
/// They are not unique across processes and are not security-sensitive.
class CallId {
  CallId._();

  static int _counter = 0;

  /// Returns the next id (e.g. `c7f3`). Wraps at 0xFFFF.
  static String next() {
    final value = _counter++ & 0xFFFF;
    return value.toRadixString(16).padLeft(4, '0');
  }

  @visibleForTesting
  static void resetForTest() {
    _counter = 0;
  }
}
