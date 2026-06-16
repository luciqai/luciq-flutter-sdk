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
/// Errors thrown by `body` are logged and swallowed - the call resolves with
/// `null` instead. This keeps SDK failures from propagating into the host app,
/// per the SDK-wide rule that no exception may escape into the embedding
/// application.
///
/// `method` is the fully-qualified short form used in logs, e.g.
/// `SUR.showSurvey`. `tag` is the `DebugTags` constant for the area. `callId`
/// is included on async/callback APIs so Dart and native logs can be matched.
/// `args` are formatted as `key=value` pairs and never include raw payload -
/// callers are responsible for converting strings/lists into `*Length` /
/// `*Count` / `*Present` summaries before passing them in.
Future<T?> hostCall<T>(
  String method,
  Future<T> Function() body, {
  required String tag,
  String? callId,
  Map<String, Object?> args = const {},
}) async {
  final logging = _logger.isDebugEnabled();
  if (logging) _logger.d(_formatEnter(method, callId, args), tag: tag);
  try {
    final result = await body();
    if (logging) _logger.d(_formatExit(method, callId, result), tag: tag);
    return result;
  } catch (e) {
    _logError(method, callId, e, tag: tag, debugEnabled: logging);
    return null;
  }
}

/// Synchronous variant of [hostCall].
T? hostCallSync<T>(
  String method,
  T Function() body, {
  required String tag,
  String? callId,
  Map<String, Object?> args = const {},
}) {
  final logging = _logger.isDebugEnabled();
  if (logging) _logger.d(_formatEnter(method, callId, args), tag: tag);
  try {
    final result = body();
    if (logging) _logger.d(_formatExit(method, callId, result), tag: tag);
    return result;
  } catch (e) {
    _logError(method, callId, e, tag: tag, debugEnabled: logging);
    return null;
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
  if (!_logger.isDebugEnabled()) return;
  _logger.d(_format(method, callId, 'fire', args), tag: tag);
}

String _formatEnter(String method, String? callId, Map<String, Object?> args) =>
    _format(method, callId, 'enter', args);

String _formatExit(String method, String? callId, Object? result) {
  final args = _summarizeResult(result);
  return _format(method, callId, 'exit', args);
}

/// Emits the canonical `phase=error` pair: `errorType` always (error level),
/// `errorMessage` only when debug is enabled. `errorMessage` is
/// `error.toString()` and routinely embeds URLs, file paths, and route names
/// that the rest of the SDK redacts, so it must not surface at the default
/// (error-level) threshold.
void _logError(
  String method,
  String? callId,
  Object error, {
  required String tag,
  required bool debugEnabled,
}) {
  final type = error.runtimeType.toString();
  _logger.e(_format(method, callId, 'error', {'errorType': type}), tag: tag);
  if (debugEnabled) {
    final msg = _truncate(error.toString(), _maxErrorMessageLength);
    _logger.d(
      _format(method, callId, 'error', {
        'errorType': type,
        'errorMessage': msg,
      }),
      tag: tag,
    );
  }
}

String _format(
  String method,
  String? callId,
  String phase,
  Map<String, Object?> args,
) {
  final buf = StringBuffer('[')
    ..write(method)
    ..write(']');
  if (callId != null) {
    buf
      ..write(' #')
      ..write(callId);
  }
  buf
    ..write(' phase=')
    ..write(phase);
  args.forEach((k, v) {
    buf
      ..write(' ')
      ..write(k)
      ..write('=')
      ..write(_formatValue(v));
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
