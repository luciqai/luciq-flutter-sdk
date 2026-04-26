// ignore_for_file: avoid_classes_with_only_static_members

import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:luciq_flutter/src/generated/crash_reporting.api.g.dart';
import 'package:luciq_flutter/src/models/crash_data.dart';
import 'package:luciq_flutter/src/models/exception_data.dart';
import 'package:luciq_flutter/src/utils/lcq_build_info.dart';
import 'package:meta/meta.dart';
import 'package:stack_trace/stack_trace.dart';

enum NonFatalExceptionLevel { error, critical, info, warning }

class CrashReporting {
  static var _host = CrashReportingHostApi();
  static bool enabled = true;

  static FlutterExceptionHandler? _originalFlutterOnError;
  static ErrorCallback? _originalPlatformOnError;
  static bool _handlersInstalled = false;

  /// Whether error handlers have been installed by [installErrorHandlers].
  @internal
  static bool get handlersInstalled => _handlersInstalled;

  /// Installs global error handlers for [FlutterError.onError] and
  /// [PlatformDispatcher.instance.onError] that forward errors to
  /// [reportCrash]. Chains to any previously installed handlers.
  ///
  /// This method is idempotent — calling it multiple times has no effect.
  @internal
  static void installErrorHandlers() {
    if (_handlersInstalled) return;

    _originalFlutterOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      reportCrash(details.exception, details.stack ?? StackTrace.empty);
      _originalFlutterOnError?.call(details);
    };

    _originalPlatformOnError = PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      reportCrash(error, stack);
      return _originalPlatformOnError?.call(error, stack) ?? true;
    };

    _handlersInstalled = true;
  }

  /// Restores the original error handlers that were saved during
  /// [installErrorHandlers]. After this call, the SDK will no longer
  /// capture unhandled errors automatically.
  @internal
  static void restoreErrorHandlers() {
    if (!_handlersInstalled) return;
    FlutterError.onError = _originalFlutterOnError;
    PlatformDispatcher.instance.onError = _originalPlatformOnError;
    _originalFlutterOnError = null;
    _originalPlatformOnError = null;
    _handlersInstalled = false;
  }

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
  }) async {
    await _sendHandledCrash(
      exception,
      stack ?? StackTrace.current,
      userAttributes,
      fingerprint,
      level,
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
