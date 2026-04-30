import 'dart:async';

import 'package:luciq_flutter/src/utils/luciq_logger.dart';

const _tag = 'Luciq';

/// Runs a synchronous void [action], logging any thrown error to
/// [LuciqLogger] under [method] and swallowing it. Used so the SDK never
/// crashes the host app.
void runCatching(String method, void Function() action) {
  try {
    action();
  } catch (e, st) {
    LuciqLogger.I.e('$method failed: $e\n$st', tag: _tag);
  }
}

/// Async variant of [runCatching] for `Future<void>` methods.
Future<void> runCatchingAsync(
  String method,
  FutureOr<void> Function() action,
) async {
  try {
    await action();
  } catch (e, st) {
    LuciqLogger.I.e('$method failed: $e\n$st', tag: _tag);
  }
}

/// Async variant that returns a value, falling back to [fallback] on error.
Future<T> runCatchingReturn<T>(
  String method,
  FutureOr<T> Function() action, {
  required T fallback,
}) async {
  try {
    return await action();
  } catch (e, st) {
    LuciqLogger.I.e('$method failed: $e\n$st', tag: _tag);
    return fallback;
  }
}
