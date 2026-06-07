import 'package:flutter/widgets.dart' show WidgetBuilder, BuildContext;
import 'package:luciq_flutter/luciq_flutter.dart';
import 'package:luciq_flutter/src/constants/debug_tags.dart';
import 'package:luciq_flutter/src/utils/lcq_date_time.dart';
import 'package:luciq_flutter/src/utils/luciq_logger.dart';
import 'package:luciq_flutter/src/utils/luciq_montonic_clock.dart';
import 'package:luciq_flutter/src/utils/luciq_utils.dart';
import 'package:luciq_flutter/src/utils/screen_loading/screen_loading_trace.dart';
import 'package:luciq_flutter/src/utils/screen_loading/ui_trace.dart';
import 'package:luciq_flutter/src/utils/ui_trace/flags_config.dart';
import 'package:meta/meta.dart';

const int _traceValidationTimeout = 500;
const String _kSlDocs =
    'https://docs.luciq.ai/docs/flutter-apm-screen-loading#disablingenabling-screen-loading-tracking';

/// Manages screen loading traces and UI traces for performance monitoring.
///
/// This class handles the tracking of screen loading times and UI transitions,
/// providing an interface for Luciq APM to capture and report performance metrics.
@internal
class ScreenLoadingManager {
  ScreenLoadingManager._();

  /// @nodoc
  @internal
  @visibleForTesting
  ScreenLoadingManager.init();

  static ScreenLoadingManager _instance = ScreenLoadingManager._();

  /// Returns the singleton instance of [ScreenLoadingManager].
  static ScreenLoadingManager get instance => _instance;

  /// Shorthand for [instance]
  static ScreenLoadingManager get I => instance;

  /// Logging tag for debugging purposes.
  static const tag = "ScreenLoadingManager";

  /// Stores the current UI trace.
  UiTrace? currentUiTrace;

  /// Stores the current screen loading trace.
  ScreenLoadingTrace? currentScreenLoadingTrace;

  /// Stores prematurely ended traces for debugging purposes.
  @internal
  final List<ScreenLoadingTrace> prematurelyEndedTraces = [];

  /// Tracks which manual screen names have been claimed by a parent widget.
  final Set<String> _activeManualScreenNames = {};

  /// Allows setting a custom instance for testing.
  @visibleForTesting
  // ignore: use_setters_to_change_properties
  static void setInstance(ScreenLoadingManager instance) {
    _instance = instance;
  }

  /// Resets the flag indicating a screen loading trace has started.
  @internal
  void resetDidStartScreenLoading() {
    // Allows starting a new screen loading capture trace in the same ui trace (without navigating out and in to the same screen)
    currentUiTrace?.didStartScreenLoading = false;
    LuciqLogger.I.kv(
      'screen_loading.reset_start',
      tag: DebugTags.apmScreenLoading,
      fields: {'traceId': currentUiTrace?.traceId},
    );
  }

  /// @nodoc
  void _logExceptionErrorAndStackTrace(Object error, StackTrace stackTrace) {
    LuciqLogger.I.kv(
      'screen_loading.exception',
      tag: DebugTags.apmScreenLoading,
      level: LogLevel.error,
      fields: {
        'traceId': currentUiTrace?.traceId,
        'type': error.runtimeType,
      },
    );
  }

  /// Checks if the Luciq SDK is built before calling API methods.
  Future<bool> _checkLuciqSDKBuilt(String apiName) async {
    final isLuciqSDKBuilt = await Luciq.isBuilt();
    if (!isLuciqSDKBuilt) {
      LuciqLogger.I.kv(
        'screen_loading.sdk_not_built',
        tag: DebugTags.apmScreenLoading,
        level: LogLevel.error,
        fields: {
          'api': apiName,
          'docs':
              'https://docs.luciq.ai/reference#showing-and-manipulating-the-invocation',
        },
      );
    }
    return isLuciqSDKBuilt;
  }

  /// Resets the flag indicating a screen loading trace has been reported.
  @internal
  void resetDidReportScreenLoading() {
    // Allows reporting a new screen loading capture trace in the same ui trace even if one was reported before by resetting the flag which is used for checking.
    currentUiTrace?.didReportScreenLoading = false;
    LuciqLogger.I.kv(
      'screen_loading.reset_report',
      tag: DebugTags.apmScreenLoading,
      fields: {'traceId': currentUiTrace?.traceId},
    );
  }

  /// Starts a new UI trace with a given screen name.
  @internal
  void resetDidExtendScreenLoading() {
    // Allows reporting a new screen loading capture trace in the same ui trace even if one was reported before by resetting the flag which is used for checking.
    currentUiTrace?.didExtendScreenLoading = false;
    LuciqLogger.I.kv(
      'screen_loading.reset_extend',
      tag: DebugTags.apmScreenLoading,
      fields: {'traceId': currentUiTrace?.traceId},
    );
  }

  /// Synchronously prepares a new UI trace so that [currentUiTrace] is
  /// immediately available for the widget's [startScreenLoadingTrace] call.
  ///
  /// Async validation (SDK built, feature flag) runs in the background.
  /// Consumers must await [UiTrace.whenValidated] before calling native APIs.
  @internal
  void prepareUiTrace(String screenName, [String? matchingScreenName]) {
    matchingScreenName ??= screenName;

    try {
      resetDidStartScreenLoading();
      _activeManualScreenNames.clear();

      final sanitizedScreenName = sanitizeScreenName(screenName);
      final sanitizedMatchingScreenName =
          sanitizeScreenName(matchingScreenName);

      final now = LCQDateTime.I.now();
      final microTimeStamp = now.microsecondsSinceEpoch;
      final uiTraceId = now.millisecondsSinceEpoch;

      currentUiTrace = UiTrace(
        screenName: sanitizedScreenName,
        matchingScreenName: sanitizedMatchingScreenName,
        traceId: uiTraceId,
      );

      LuciqLogger.I.kv(
        'ui_trace.prepare',
        tag: DebugTags.apmScreenLoading,
        fields: {
          'traceId': uiTraceId,
          'screenHash': hashForLog(sanitizedScreenName),
          'screenLen': sanitizedScreenName.length,
        },
      );

      _validateAndActivateUiTrace(
        currentUiTrace!,
        sanitizedScreenName,
        microTimeStamp,
      );
    } catch (error, stackTrace) {
      _logExceptionErrorAndStackTrace(error, stackTrace);
    }
  }

  /// Runs the async checks and either activates or discards the trace.
  Future<void> _validateAndActivateUiTrace(
    UiTrace trace,
    String screenName,
    int startTimeStampMicro,
  ) async {
    try {
      final isSDKBuilt =
          await _checkLuciqSDKBuilt("APM.LuciqCaptureScreenLoading");
      if (!isSDKBuilt) {
        _discardUiTrace(trace, 'SDK not built');
        return;
      }

      final isAutoUiTraceEnabled = await FlagsConfig.uiTrace.isEnabled();
      if (!isAutoUiTraceEnabled) {
        LuciqLogger.I.kv(
          'ui_trace.auto_disabled',
          tag: DebugTags.apmScreenLoading,
          level: LogLevel.error,
          fields: {
            'traceId': trace.traceId,
            'screenLen': screenName.length,
            'docs':
                'https://docs.luciq.ai/docs/react-native-apm-disabling-enabling',
          },
        );
        _discardUiTrace(trace, 'auto_disabled');
        return;
      }

      APM.startCpUiTrace(screenName, startTimeStampMicro, trace.traceId);
      trace.validationCompleter.complete(true);

      LuciqLogger.I.kv(
        'ui_trace.validate.ok',
        tag: DebugTags.apmScreenLoading,
        fields: {
          'traceId': trace.traceId,
          'screenHash': hashForLog(screenName),
        },
      );
    } catch (error, stackTrace) {
      _discardUiTrace(trace, 'exception_${error.runtimeType}');
      _logExceptionErrorAndStackTrace(error, stackTrace);
    }
  }

  void _discardUiTrace(UiTrace trace, String reason) {
    LuciqLogger.I.kv(
      'ui_trace.discard',
      tag: DebugTags.apmScreenLoading,
      fields: {'traceId': trace.traceId, 'reason': reason},
    );
    if (!trace.validationCompleter.isCompleted) {
      trace.validationCompleter.complete(false);
    }
    if (currentUiTrace == trace) {
      currentUiTrace = null;
    }
  }

  /// The function `sanitizeScreenName` removes leading and trailing slashes from a screen name in Dart.
  ///
  /// Args:
  ///   screenName (String): The `sanitizeScreenName` function is designed to remove a specific character
  /// ('/') from the beginning and end of a given `screenName` string. If the `screenName` is equal to
  /// '/', it will return 'ROOT_PAGE'. Otherwise, it will remove the character from the beginning and end
  /// if
  ///
  /// Returns:
  ///   The `sanitizeScreenName` function returns the sanitized screen name after removing any leading or
  /// trailing '/' characters. If the input `screenName` is equal to '/', it returns 'ROOT_PAGE'.

  @internal
  String sanitizeScreenName(String screenName) {
    const characterToBeRemoved = '/';
    var sanitizedScreenName = screenName;

    if (screenName == characterToBeRemoved) {
      return 'ROOT_PAGE';
    }
    if (screenName.startsWith(characterToBeRemoved)) {
      sanitizedScreenName = sanitizedScreenName.substring(1);
    }
    if (screenName.endsWith(characterToBeRemoved)) {
      sanitizedScreenName =
          sanitizedScreenName.substring(0, sanitizedScreenName.length - 1);
    }
    return sanitizedScreenName;
  }

  /// Starts a screen loading trace.
  ///
  /// Returns `true` if the trace was successfully started, `false` otherwise.
  @internal
  Future<bool> startScreenLoadingTrace(ScreenLoadingTrace trace) async {
    try {
      final isSDKBuilt =
          await _checkLuciqSDKBuilt("APM.LuciqCaptureScreenLoading");
      if (!isSDKBuilt) {
        LuciqLogger.I.kv(
          'screen_loading.start.skip_sdk_not_built',
          tag: DebugTags.apmScreenLoading,
          level: LogLevel.error,
          fields: {
            'traceId': currentUiTrace?.traceId,
            'screenLen': trace.screenName.length,
          },
        );
        return false;
      }

      final isScreenLoadingEnabled =
          await FlagsConfig.screenLoading.isEnabled();
      if (!isScreenLoadingEnabled) {
        LuciqLogger.I.kv(
          'screen_loading.start.skip_disabled',
          tag: DebugTags.apmScreenLoading,
          level: LogLevel.error,
          fields: {
            'traceId': currentUiTrace?.traceId,
            'screenLen': trace.screenName.length,
            'docs': _kSlDocs,
          },
        );

        return false;
      }

      final isSameScreen = currentUiTrace?.matches(trace.screenName) == true;

      final didStartLoading = currentUiTrace?.didStartScreenLoading == true;

      if (isSameScreen && !didStartLoading) {
        LuciqLogger.I.kv(
          'screen_loading.start',
          tag: DebugTags.apmScreenLoading,
          fields: {
            'traceId': currentUiTrace?.traceId,
            'screenHash': hashForLog(trace.screenName),
            'startUs': trace.startTimeInMicroseconds,
          },
        );
        currentUiTrace?.didStartScreenLoading = true;
        currentScreenLoadingTrace = trace;
        return true;
      }
      LuciqLogger.I.kv(
        'screen_loading.start.skipped',
        tag: DebugTags.apmScreenLoading,
        fields: {
          'traceId': currentUiTrace?.traceId,
          'screenHash': hashForLog(trace.screenName),
          'screenLen': trace.screenName.length,
          'startUs': trace.startTimeInMicroseconds,
          'didStart': didStartLoading,
          'isSameScreen': isSameScreen,
        },
      );
      return false;
    } catch (error, stackTrace) {
      _logExceptionErrorAndStackTrace(error, stackTrace);
      return false;
    }
  }

  /// Reports the input [ScreenLoadingTrace] to the native side.
  @internal
  Future<void> reportScreenLoading(ScreenLoadingTrace? trace) async {
    try {
      final isSDKBuilt =
          await _checkLuciqSDKBuilt("APM.LuciqCaptureScreenLoading");
      if (!isSDKBuilt) {
        LuciqLogger.I.kv(
          'screen_loading.report.skip_sdk_not_built',
          tag: DebugTags.apmScreenLoading,
          level: LogLevel.error,
          fields: {
            'traceId': currentUiTrace?.traceId,
            'screenLen': trace?.screenName.length ?? 0,
          },
        );
        return;
      }

      int? duration;
      final isScreenLoadingEnabled =
          await FlagsConfig.screenLoading.isEnabled();
      if (!isScreenLoadingEnabled) {
        LuciqLogger.I.kv(
          'screen_loading.report.skip_disabled',
          tag: DebugTags.apmScreenLoading,
          level: LogLevel.error,
          fields: {
            'traceId': currentUiTrace?.traceId,
            'screenLen': trace?.screenName.length ?? 0,
            'docs': _kSlDocs,
          },
        );

        return;
      }

      final isSameScreen = currentScreenLoadingTrace == trace;

      final isReported = currentUiTrace?.didReportScreenLoading ==
          true; // Changed to isReported
      final isValidTrace = trace != null;

      // Only report the first screen loading trace with the same name as the active UiTrace
      if (isSameScreen && !isReported && isValidTrace) {
        // Wait for UI trace native-side activation before reporting
        final isUiTraceValid = await currentUiTrace?.whenValidated.timeout(
          const Duration(milliseconds: _traceValidationTimeout),
          onTimeout: () {
            LuciqLogger.I.kv(
              'ui_trace.validate.timeout',
              tag: DebugTags.apmScreenLoading,
              level: LogLevel.error,
              fields: {
                'traceId': currentUiTrace?.traceId,
                'phase': 'report',
              },
            );
            return false;
          },
        );

        if (isUiTraceValid != true) {
          LuciqLogger.I.kv(
            'screen_loading.report.drop_validation',
            tag: DebugTags.apmScreenLoading,
            fields: {
              'traceId': currentUiTrace?.traceId,
              'screenLen': trace?.screenName.length ?? 0,
            },
          );
          currentScreenLoadingTrace = null;
          return;
        }

        currentUiTrace?.didReportScreenLoading = true;

        APM.reportScreenLoadingCP(
          trace?.startTimeInMicroseconds ?? 0,
          duration ?? trace?.duration ?? 0,
          currentUiTrace?.traceId ?? 0,
        );
        return;
      } else {
        LuciqLogger.I.kv(
          'screen_loading.report.skipped',
          tag: DebugTags.apmScreenLoading,
          fields: {
            'traceId': currentUiTrace?.traceId,
            'screenLen': trace?.screenName.length ?? 0,
            'startUs': trace?.startTimeInMicroseconds,
            'durationUs': duration ?? trace?.duration ?? 0,
            'didReport': isReported,
            'isSameScreen': isSameScreen,
          },
        );
        _reportScreenLoadingDroppedError(trace);
      }
      return;
    } catch (error, stackTrace) {
      _logExceptionErrorAndStackTrace(error, stackTrace);
    }
  }

  @internal
  Future<void> reportManualScreenLoading(
    String screenName,
    int startTimeInMicroseconds,
    int duration,
  ) async {
    try {
      final isSDKBuilt =
          await _checkLuciqSDKBuilt("APM.LuciqCaptureScreenLoading");
      if (!isSDKBuilt) {
        LuciqLogger.I.kv(
          'screen_loading.report_manual.skip_sdk_not_built',
          tag: DebugTags.apmScreenLoading,
          level: LogLevel.error,
          fields: {'screenLen': screenName.length},
        );
        return;
      }

      final isScreenLoadingEnabled =
          await FlagsConfig.screenLoading.isEnabled();
      if (!isScreenLoadingEnabled) {
        LuciqLogger.I.kv(
          'screen_loading.report_manual.skip_disabled',
          tag: DebugTags.apmScreenLoading,
          level: LogLevel.error,
          fields: {
            'screenLen': screenName.length,
            'docs': _kSlDocs,
          },
        );
        return;
      }

      LuciqLogger.I.kv(
        'screen_loading.report_manual',
        tag: DebugTags.apmScreenLoading,
        fields: {
          'screenHash': hashForLog(screenName),
          'startUs': startTimeInMicroseconds,
          'durationUs': duration,
        },
      );

      APM.reportManualScreenLoadingCP(
        screenName,
        startTimeInMicroseconds,
        duration,
      );
      return;
    } catch (error, stackTrace) {
      _logExceptionErrorAndStackTrace(error, stackTrace);
    }
  }

  /// Called by manual widgets when [startScreenLoadingTrace] fails (no UI trace).
  /// Returns `true` if the manual trace was claimed (this widget is the parent).
  @internal
  bool claimManualScreenLoadingTrace(ScreenLoadingTrace trace) {
    // If auto trace already started for this screen, don't also claim manual
    if (currentUiTrace?.matches(trace.screenName) == true &&
        currentUiTrace?.didStartScreenLoading == true) {
      return false;
    }
    // Already claimed by a parent manual widget with same name → nested, skip
    if (_activeManualScreenNames.contains(trace.screenName)) {
      return false;
    }
    _activeManualScreenNames.add(trace.screenName);
    currentScreenLoadingTrace = trace;
    return true;
  }

  /// Called from widget dispose to release the manual claim.
  @internal
  void releaseManualScreenLoadingTrace(String screenName) {
    _activeManualScreenNames.remove(screenName);
  }

  void _reportScreenLoadingDroppedError(ScreenLoadingTrace? trace) {
    LuciqLogger.I.kv(
      'screen_loading.drop',
      tag: DebugTags.apmScreenLoading,
      level: LogLevel.error,
      fields: {
        'traceId': currentUiTrace?.traceId,
        'screenLen': trace?.screenName.length ?? 0,
        'reason': 'not_current_or_already_reported',
      },
    );
  }

  /// Extends the already ended screen loading adding a stage to it
  Future<void> endScreenLoading() async {
    try {
      final uiTrace = currentUiTrace;
      final screenLoadingTrace = currentScreenLoadingTrace;

      final isSDKBuilt = await _checkLuciqSDKBuilt("endScreenLoading");
      if (!isSDKBuilt) return;

      final isScreenLoadingEnabled =
          await FlagsConfig.screenLoading.isEnabled();
      if (!isScreenLoadingEnabled) {
        LuciqLogger.I.kv(
          'screen_loading.end.skip_disabled',
          tag: DebugTags.apmScreenLoading,
          level: LogLevel.error,
          fields: {
            'traceId': uiTrace?.traceId,
            'docs': _kSlDocs,
          },
        );
        return;
      }

      final isEndScreenLoadingEnabled =
          await FlagsConfig.endScreenLoading.isEnabled();

      if (!isEndScreenLoadingEnabled) {
        LuciqLogger.I.kv(
          'screen_loading.end.skip_api_disabled',
          tag: DebugTags.apmScreenLoading,
          level: LogLevel.error,
          fields: {
            'traceId': uiTrace?.traceId,
            'docs': _kSlDocs,
          },
        );

        return;
      }

      final didExtendScreenLoading = uiTrace?.didExtendScreenLoading == true;
      if (didExtendScreenLoading) {
        LuciqLogger.I.kv(
          'screen_loading.end.skip_already_called',
          tag: DebugTags.apmScreenLoading,
          level: LogLevel.error,
          fields: {'traceId': uiTrace?.traceId},
        );
        return;
      }

      // Handles no active screen loading trace - cannot end
      final didStartScreenLoading =
          screenLoadingTrace?.startTimeInMicroseconds != null;
      if (!didStartScreenLoading) {
        LuciqLogger.I.kv(
          'screen_loading.end.skip_no_active_trace',
          tag: DebugTags.apmScreenLoading,
          level: LogLevel.error,
          fields: {'traceId': uiTrace?.traceId},
        );
        return;
      }

      final extendedMonotonicEndTimeInMicroseconds = LuciqMonotonicClock.I.now;

      var duration = extendedMonotonicEndTimeInMicroseconds -
          screenLoadingTrace!.startMonotonicTimeInMicroseconds;

      var extendedEndTimeInMicroseconds =
          screenLoadingTrace.startTimeInMicroseconds + duration;

      // cannot extend as the trace has not ended yet.
      // we report the extension timestamp as 0 and can be override later on.
      final didEndScreenLoadingPrematurely =
          screenLoadingTrace.endTimeInMicroseconds == null;
      if (didEndScreenLoadingPrematurely) {
        extendedEndTimeInMicroseconds = 0;
        duration = 0;

        LuciqLogger.I.kv(
          'screen_loading.end.premature',
          tag: DebugTags.apmScreenLoading,
          level: LogLevel.error,
          fields: {'traceId': uiTrace?.traceId},
        );
      }
      LuciqLogger.I.kv(
        'screen_loading.end',
        tag: DebugTags.apmScreenLoading,
        fields: {
          'traceId': uiTrace?.traceId,
          'endUs': screenLoadingTrace.endTimeInMicroseconds,
          'extendedEndUs': extendedEndTimeInMicroseconds,
          'premature': didEndScreenLoadingPrematurely,
        },
      );

      // Wait for UI trace validation before calling native API
      final isUiTraceValid = await uiTrace?.whenValidated.timeout(
        const Duration(milliseconds: _traceValidationTimeout),
        onTimeout: () {
          LuciqLogger.I.kv(
            'ui_trace.validate.timeout',
            tag: DebugTags.apmScreenLoading,
            level: LogLevel.error,
            fields: {'traceId': uiTrace.traceId, 'phase': 'end'},
          );
          return false;
        },
      );

      if (isUiTraceValid != true) {
        LuciqLogger.I.kv(
          'screen_loading.end.drop_validation',
          tag: DebugTags.apmScreenLoading,
          fields: {'traceId': uiTrace?.traceId},
        );
        return;
      }

      // Ends screen loading trace
      APM.endScreenLoadingCP(
        extendedEndTimeInMicroseconds,
        uiTrace?.traceId ?? 0,
      );
      uiTrace?.didExtendScreenLoading = true;

      return;
    } catch (error, stackTrace) {
      _logExceptionErrorAndStackTrace(error, stackTrace);
    }
  }

  /// Wraps the given routes with [LuciqCaptureScreenLoading] widgets.
  ///
  /// This allows Luciq to automatically capture screen loading times.
  ///
  /// Example usage:
  ///
  /// Map<String, WidgetBuilder> routes = {
  /// '/home': (context) => const HomePage(),
  /// '/settings': (context) => const SettingsPage(),
  /// };
  ///
  /// Map<String, WidgetBuilder> wrappedRoutes =
  /// ScreenLoadingAutomaticManager.wrapRoutes( routes)
  static Map<String, WidgetBuilder> wrapRoutes(
    Map<String, WidgetBuilder> routes, {
    List<String> exclude = const [],
  }) {
    final excludedRoutes = <String, bool>{};
    for (final route in exclude) {
      excludedRoutes[route] = true;
    }

    final wrappedRoutes = <String, WidgetBuilder>{};
    for (final entry in routes.entries) {
      if (!excludedRoutes.containsKey(entry.key)) {
        wrappedRoutes[entry.key] =
            (BuildContext context) => LuciqCaptureScreenLoading.withConfig(
                  screenName: entry.key,
                  isManual: false,
                  child: entry.value(context),
                );
      } else {
        wrappedRoutes[entry.key] = entry.value;
      }
    }

    return wrappedRoutes;
  }
}

@internal
class DropScreenLoadingError extends Error {
  final ScreenLoadingTrace trace;

  DropScreenLoadingError(this.trace);

  @override
  String toString() {
    return 'DropScreenLoadingError: $trace';
  }
}
