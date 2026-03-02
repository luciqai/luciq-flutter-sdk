// ignore_for_file: avoid_classes_with_only_static_members

import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:luciq_flutter/src/generated/crash_reporting.api.g.dart';
import 'package:luciq_flutter/src/models/crash_data.dart';
import 'package:luciq_flutter/src/models/exception_data.dart';
import 'package:luciq_flutter/src/utils/lcq_build_info.dart';
import 'package:stack_trace/stack_trace.dart';

enum NonFatalExceptionLevel { error, critical, info, warning }

class CrashReporting {
  static var _host = CrashReportingHostApi();
  static bool enabled = true;

  static final _CrashReportQueue _queue = _CrashReportQueue();

  /// @nodoc
  @visibleForTesting
  // ignore: use_setters_to_change_properties
  static void $setHostApi(CrashReportingHostApi host) {
    _host = host;
  }

  /// Enables and disables Enables and disables automatic crash reporting.
  /// [boolean] isEnabled
  static Future<void> setEnabled(bool isEnabled) async {
    enabled = isEnabled;
    return _host.setEnabled(isEnabled);
  }

  static Future<void> reportCrash(Object exception, StackTrace stack) async {
    if (LCQBuildInfo.instance.isReleaseMode && enabled) {
      await _reportUnhandledCrash(exception, stack);
    } else {
      FlutterError.dumpErrorToConsole(
        FlutterErrorDetails(stack: stack, exception: exception),
      );
    }
  }

  /// Reports a handled crash to you dashboard
  /// [Object] exception
  /// [StackTrace] stack
  static Future<void> reportHandledCrash(
    Object exception,
    StackTrace? stack, {
    Map<String, String>? userAttributes,
    String? fingerprint,
    NonFatalExceptionLevel level = NonFatalExceptionLevel.error,
  }) {
    final capturedStack = stack ?? StackTrace.current;
    return _queue.enqueue(
      () => _sendHandledCrash(
        exception,
        capturedStack,
        userAttributes,
        fingerprint,
        level,
      ),
    );
  }

  static Future<void> _reportUnhandledCrash(
    Object exception,
    StackTrace stack,
  ) async {
    await _sendCrash(exception, stack, false);
  }

  static Future<void> _sendCrash(
    Object exception,
    StackTrace stack,
    bool handled,
  ) async {
    final crashData = getCrashDataFromException(stack, exception);

    return _host.send(jsonEncode(crashData), handled);
  }

  static Future<void> _sendHandledCrash(
    Object exception,
    StackTrace stack,
    Map<String, String>? userAttributes,
    String? fingerprint,
    NonFatalExceptionLevel? nonFatalExceptionLevel,
  ) async {
    final crashData = getCrashDataFromException(stack, exception);

    return _host.sendNonFatalError(
      jsonEncode(crashData),
      userAttributes,
      fingerprint,
      nonFatalExceptionLevel.toString(),
    );
  }

  static CrashData getCrashDataFromException(
    StackTrace stack,
    Object exception,
  ) {
    final trace = Trace.from(stack);
    final frames = trace.frames
        .map(
          (frame) => ExceptionData(
            file: frame.uri.toString(),
            methodName: frame.member,
            lineNumber: frame.line,
            column: frame.column ?? 0,
          ),
        )
        .toList();

    final crashData = CrashData(
      os: LCQBuildInfo.instance.operatingSystem,
      message: exception.toString(),
      exception: frames,
    );
    return crashData;
  }

  /// Enables and disables NDK crash reporting.
  /// [boolean] isEnabled
  ///
  /// Requires the [Luciq NDK package](https://pub.dev/packages/luciq_flutter_ndk to be added to the project for this to work.
  ///
  /// This method is Android-only and has no effect on iOS.
  static Future<void> setNDKEnabled(bool isEnabled) async {
    return _host.setNDKEnabled(isEnabled);
  }
}

/// Serializes platform channel calls so only one is in-flight at a time,
/// preventing main-thread flooding when many crash reports are sent rapidly.
class _CrashReportQueue {
  static const int _maxQueueSize = 1000;

  final Queue<_QueueEntry> _pending = Queue<_QueueEntry>();
  bool _processing = false;

  Future<void> enqueue(Future<void> Function() task) {
    final completer = Completer<void>();

    if (_pending.length >= _maxQueueSize) {
      _pending.removeFirst().completer.complete();
    }

    _pending.add(_QueueEntry(task: task, completer: completer));
    _startProcessing();
    return completer.future;
  }

  void _startProcessing() {
    if (_processing) return;
    _processing = true;
    _drain();
  }

  Future<void> _drain() async {
    while (_pending.isNotEmpty) {
      final entry = _pending.removeFirst();
      try {
        await entry.task();
        entry.completer.complete();
      } catch (e, s) {
        entry.completer.completeError(e, s);
      }
    }
    _processing = false;
  }
}

class _QueueEntry {
  _QueueEntry({required this.task, required this.completer});

  final Future<void> Function() task;
  final Completer<void> completer;
}
