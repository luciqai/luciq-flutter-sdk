import 'package:flutter/foundation.dart';
import 'package:luciq_flutter/src/utils/luciq_logger.dart';

/// Maximum characters of `errorMessage` kept in an `phase=error` log.
/// Anything longer is truncated with a trailing ellipsis.
const int _maxErrorMessageLength = 256;

Logger? _testLoggerOverride;

Logger get _logger => _testLoggerOverride ?? LuciqLogger.I;

@visibleForTesting
void setHostCallLogger(Logger logger) {
  _testLoggerOverride = logger;
}

@visibleForTesting
void resetHostCallLogger() {
  _testLoggerOverride = null;
}

/// Wraps an async host (Pigeon) call so every public SDK API emits the
/// canonical lifecycle `phase=enter` -> `phase=exit | phase=error` line pair
/// without each call site repeating the format.
///
/// `method` is the fully-qualified short form used in logs, e.g.
/// `SUR.showSurvey`. `tag` is the `DebugTags` constant for the area. `callId`
/// is included on async/callback APIs so Dart and native logs can be matched.
/// `args` are formatted as `key=value` pairs and never include raw payload -
/// callers are responsible for converting strings/lists into `*Length` /
/// `*Count` / `*Present` summaries before passing them in.
Future<T> hostCall<T>(
  String method,
  Future<T> Function() body, {
  required String tag,
  String? callId,
  Map<String, Object?> args = const {},
}) async {
  _logger.d(_formatEnter(method, callId, args), tag: tag);
  try {
    final result = await body();
    _logger.d(_formatExit(method, callId, result), tag: tag);
    return result;
  } catch (e) {
    _logger.e(_formatError(method, callId, e), tag: tag);
    rethrow;
  }
}

/// Synchronous variant of [hostCall].
T hostCallSync<T>(
  String method,
  T Function() body, {
  required String tag,
  String? callId,
  Map<String, Object?> args = const {},
}) {
  _logger.d(_formatEnter(method, callId, args), tag: tag);
  try {
    final result = body();
    _logger.d(_formatExit(method, callId, result), tag: tag);
    return result;
  } catch (e) {
    _logger.e(_formatError(method, callId, e), tag: tag);
    rethrow;
  }
}

/// Emits a single `phase=fire` log for a Pigeon-invoked callback. Mirrors the
/// shape of [hostCall] but for the inbound (native -> Dart) direction so an
/// originating call id can be threaded through. Use at the very top of every
/// Dart method registered as a Flutter API handler.
void logCallbackFire(
  String method, {
  required String tag,
  String? callId,
  Map<String, Object?> args = const {},
}) {
  _logger.d(_format(method, callId, 'fire', args), tag: tag);
}

String _formatEnter(String method, String? callId, Map<String, Object?> args) =>
    _format(method, callId, 'enter', args);

String _formatExit(String method, String? callId, Object? result) {
  final args = _summarizeResult(result);
  return _format(method, callId, 'exit', args);
}

String _formatError(String method, String? callId, Object error) {
  final type = error.runtimeType.toString();
  final msg = _truncate(error.toString(), _maxErrorMessageLength);
  return _format(method, callId, 'error', {
    'errorType': type,
    'errorMessage': msg,
  });
}

String _format(
  String method,
  String? callId,
  String phase,
  Map<String, Object?> args,
) {
  final buf = StringBuffer('[')..write(method)..write(']');
  if (callId != null) {
    buf..write(' #')..write(callId);
  }
  buf..write(' phase=')..write(phase);
  args.forEach((k, v) {
    buf..write(' ')..write(k)..write('=')..write(_formatValue(v));
  });
  return buf.toString();
}

String _formatValue(Object? v) {
  if (v == null) return 'null';
  if (v is bool) return v ? 'true' : 'false';
  return v.toString();
}

Map<String, Object?> _summarizeResult(Object? result) {
  if (result == null) {
    return const {'resultPresent': false};
  }
  if (result is bool || result is num) {
    return {'result': result};
  }
  if (result is String) {
    return {'resultLength': result.length};
  }
  if (result is Iterable) {
    return {'resultCount': result.length};
  }
  if (result is Map) {
    return {'resultCount': result.length};
  }
  return const {'resultPresent': true};
}

String _truncate(String value, int max) {
  if (value.length <= max) return value;
  return '${value.substring(0, max)}...';
}
