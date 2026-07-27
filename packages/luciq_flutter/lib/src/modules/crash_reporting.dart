// ignore_for_file: avoid_classes_with_only_static_members

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:luciq_flutter/src/constants/debug_tags.dart';
import 'package:luciq_flutter/src/generated/crash_reporting.api.g.dart';
import 'package:luciq_flutter/src/models/crash_data.dart';
import 'package:luciq_flutter/src/models/exception_data.dart';
import 'package:luciq_flutter/src/utils/host_call.dart';
import 'package:luciq_flutter/src/utils/lcq_build_info.dart';
import 'package:luciq_flutter/src/utils/luciq_logger.dart';
import 'package:stack_trace/stack_trace.dart';

enum NonFatalExceptionLevel { error, critical, info, warning }

class CrashReporting {
  static var _host = CrashReportingHostApi();
  static bool enabled = true;

  /// @nodoc
  @visibleForTesting
  // ignore: use_setters_to_change_properties
  static void $setHostApi(CrashReportingHostApi host) {
    _host = host;
  }

  /// Enables and disables Enables and disables automatic crash reporting.
  /// [boolean] isEnabled
  static Future<void> setEnabled(bool isEnabled) {
    enabled = isEnabled;
    return hostCall(
      'CR.setEnabled',
      () => _host.setEnabled(isEnabled),
      tag: DebugTags.crashReporting,
      args: {'isEnabled': isEnabled},
    );
  }

  static Future<void> reportCrash(Object exception, StackTrace stack) =>
      hostCall(
        'CR.reportCrash',
        () async {
          if (LCQBuildInfo.instance.isReleaseMode && enabled) {
            await _reportUnhandledCrash(exception, stack);
          } else {
            FlutterError.dumpErrorToConsole(
              FlutterErrorDetails(stack: stack, exception: exception),
            );
          }
        },
        tag: DebugTags.crashReporting,
        args: {
          'exceptionType': exception.runtimeType,
          'isReleaseMode': LCQBuildInfo.instance.isReleaseMode,
          'enabled': enabled,
        },
      );

  /// Reports a handled crash to you dashboard
  /// [Object] exception
  /// [StackTrace] stack
  static Future<void> reportHandledCrash(
    Object exception,
    StackTrace? stack, {
    Map<String, String>? userAttributes,
    String? fingerprint,
    NonFatalExceptionLevel level = NonFatalExceptionLevel.error,
  }) =>
      hostCall(
        'CR.reportHandledCrash',
        () => _sendHandledCrash(
          exception,
          stack ?? StackTrace.current,
          userAttributes,
          fingerprint,
          level,
        ),
        tag: DebugTags.crashReporting,
        args: {
          'exceptionType': exception.runtimeType,
          'stackPresent': stack != null,
          'userAttributesCount': userAttributes?.length ?? 0,
          'fingerprintPresent': fingerprint != null,
          'level': level,
        },
      );

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
    LuciqLogger.I.d(
      '[CR.getCrashDataFromException] phase=enter exceptionType=${exception.runtimeType}',
      tag: DebugTags.crashReporting,
    );
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
    LuciqLogger.I.d(
      '[CR.getCrashDataFromException] phase=exit frameCount=${frames.length}',
      tag: DebugTags.crashReporting,
    );
    return crashData;
  }

  /// Enables and disables NDK crash reporting.
  /// [boolean] isEnabled
  ///
  /// Requires the [Luciq NDK package](https://pub.dev/packages/luciq_flutter_ndk to be added to the project for this to work.
  ///
  /// This method is Android-only and has no effect on iOS.
  static Future<void> setNDKEnabled(bool isEnabled) => hostCall(
        'CR.setNDKEnabled',
        () => _host.setNDKEnabled(isEnabled),
        tag: DebugTags.crashReporting,
        args: {'isEnabled': isEnabled},
      );
}
