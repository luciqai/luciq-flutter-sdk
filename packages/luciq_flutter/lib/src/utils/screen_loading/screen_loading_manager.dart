import 'package:flutter/widgets.dart' show WidgetBuilder, BuildContext;
import 'package:luciq_flutter/luciq_flutter.dart';
import 'package:luciq_flutter/src/utils/lcq_date_time.dart';
import 'package:luciq_flutter/src/utils/luciq_logger.dart';
import 'package:luciq_flutter/src/utils/luciq_montonic_clock.dart';
import 'package:luciq_flutter/src/utils/screen_loading/screen_loading_trace.dart';
import 'package:luciq_flutter/src/utils/screen_loading/ui_trace.dart';
import 'package:luciq_flutter/src/utils/ui_trace/flags_config.dart';
import 'package:meta/meta.dart';

const int _traceValidationTimeout = 500;

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
    LuciqLogger.I.d(
      'Resetting didStartScreenLoading — setting didStartScreenLoading: ${currentUiTrace?.didStartScreenLoading}',
      tag: APM.tag,
    );
  }

  /// @nodoc
  void _logExceptionErrorAndStackTrace(Object error, StackTrace stackTrace) {
    LuciqLogger.I.e(
      '[Error]:$error \n'
      '[StackTrace]: $stackTrace',
      tag: APM.tag,
    );
  }

  /// Checks if the Luciq SDK is built before calling API methods.
  Future<bool> _checkLuciqSDKBuilt(String apiName) async {
    final isLuciqSDKBuilt = await Luciq.isBuilt();
    if (!isLuciqSDKBuilt) {
      LuciqLogger.I.e(
        'Luciq API {$apiName} was called before the SDK is built. To build it, first by following the instructions at this link:\n'
        'https://docs.luciq.ai/reference#showing-and-manipulating-the-invocation',
        tag: APM.tag,
      );
    }
    return isLuciqSDKBuilt;
  }

  /// Resets the flag indicating a screen loading trace has been reported.
  @internal
  void resetDidReportScreenLoading() {
    // Allows reporting a new screen loading capture trace in the same ui trace even if one was reported before by resetting the flag which is used for checking.
    currentUiTrace?.didReportScreenLoading = false;
    LuciqLogger.I.d(
      'Resetting didExtendScreenLoading — setting didExtendScreenLoading: ${currentUiTrace?.didExtendScreenLoading}',
      tag: APM.tag,
    );
  }

  /// Starts a new UI trace with a given screen name.
  @internal
  void resetDidExtendScreenLoading() {
    // Allows reporting a new screen loading capture trace in the same ui trace even if one was reported before by resetting the flag which is used for checking.
    currentUiTrace?.didExtendScreenLoading = false;
    LuciqLogger.I.d(
      'Resetting didReportScreenLoading — setting didReportScreenLoading: ${currentUiTrace?.didReportScreenLoading}',
      tag: APM.tag,
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

      LuciqLogger.I.d(
        'Prepared UI trace — traceId: $uiTraceId, '
        'screenName: $sanitizedScreenName (pending validation)',
        tag: APM.tag,
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
        LuciqLogger.I.e(
          'Auto UI trace is disabled, skipping starting the UI trace for screen: $screenName.\n'
          'Please refer to the documentation for how to enable APM on your app: '
          'https://docs.luciq.ai/docs/react-native-apm-disabling-enabling',
          tag: APM.tag,
        );
        _discardUiTrace(trace, 'Auto UI trace disabled');
        return;
      }

      APM.startCpUiTrace(screenName, startTimeStampMicro, trace.traceId);
      trace.validationCompleter.complete(true);

      LuciqLogger.I.d(
        'UI trace validated — traceId: ${trace.traceId}, screenName: $screenName',
        tag: APM.tag,
      );
    } catch (error, stackTrace) {
      _discardUiTrace(trace, 'Exception: $error');
      _logExceptionErrorAndStackTrace(error, stackTrace);
    }
  }

  void _discardUiTrace(UiTrace trace, String reason) {
    LuciqLogger.I.d(
      'Discarding UI trace — reason: $reason',
      tag: APM.tag,
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
  @internal
  Future<void> startScreenLoadingTrace(ScreenLoadingTrace trace) async {
    try {
      final isSDKBuilt =
          await _checkLuciqSDKBuilt("APM.LuciqCaptureScreenLoading");
      if (!isSDKBuilt) {
        LuciqLogger.I.e(
          'Luciq SDK is not built, skipping starting screen loading monitoring for screen: ${trace.screenName}.',
          tag: APM.tag,
        );
        return;
      }

      final isScreenLoadingEnabled =
          await FlagsConfig.screenLoading.isEnabled();
      if (!isScreenLoadingEnabled) {
        LuciqLogger.I.e(
          'Screen loading monitoring is disabled, skipping starting screen loading monitoring for screen: ${trace.screenName}.\n'
          'Please refer to the documentation for how to enable screen loading monitoring on your app: '
          'https://docs.luciq.ai/docs/flutter-apm-screen-loading#disablingenabling-screen-loading-tracking '
          "If Screen Loading is enabled but you're still seeing this message, please reach out to support.",
          tag: APM.tag,
        );

        return;
      }

      final isSameScreen = currentUiTrace?.matches(trace.screenName) == true;

      final didStartLoading = currentUiTrace?.didStartScreenLoading == true;

      if (isSameScreen && !didStartLoading) {
        LuciqLogger.I.d(
          'Starting screen loading trace — screenName: ${trace.screenName}, startTimeInMicroseconds: ${trace.startTimeInMicroseconds}',
          tag: APM.tag,
        );
        currentUiTrace?.didStartScreenLoading = true;
        currentScreenLoadingTrace = trace;
        return;
      }
      LuciqLogger.I.d(
        'failed to start screen loading trace — screenName: ${trace.screenName}, startTimeInMicroseconds: ${trace.startTimeInMicroseconds}',
        tag: APM.tag,
      );
      LuciqLogger.I.d(
        'didStartScreenLoading: $didStartLoading, isSameScreen: $isSameScreen',
        tag: APM.tag,
      );
    } catch (error, stackTrace) {
      _logExceptionErrorAndStackTrace(error, stackTrace);
    }
  }

  /// Reports the input [ScreenLoadingTrace] to the native side.
  @internal
  Future<void> reportScreenLoading(ScreenLoadingTrace? trace) async {
    try {
      final isSDKBuilt =
          await _checkLuciqSDKBuilt("APM.LuciqCaptureScreenLoading");
      if (!isSDKBuilt) {
        LuciqLogger.I.e(
          'Luciq SDK is not built, skipping reporting screen loading time for screen: ${trace?.screenName}.',
          tag: APM.tag,
        );
        return;
      }

      int? duration;
      final isScreenLoadingEnabled =
          await FlagsConfig.screenLoading.isEnabled();
      if (!isScreenLoadingEnabled) {
        LuciqLogger.I.e(
          'Screen loading monitoring is disabled, skipping reporting screen loading time for screen: ${trace?.screenName}.\n'
          'Please refer to the documentation for how to enable screen loading monitoring on your app: '
          'https://docs.luciq.ai/docs/flutter-apm-screen-loading#disablingenabling-screen-loading-tracking '
          "If Screen Loading is enabled but you're still seeing this message, please reach out to support.",
          tag: APM.tag,
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
            LuciqLogger.I.e(
              'UI trace validation timed out — dropping screen loading trace',
              tag: APM.tag,
            );
            return false;
          },
        );

        if (isUiTraceValid != true) {
          LuciqLogger.I.d(
            'Dropping screen loading trace — UI trace validation failed for screen: ${trace?.screenName}',
            tag: APM.tag,
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
        LuciqLogger.I.d(
          'Failed to report screen loading trace — screenName: ${trace?.screenName}, '
          'startTimeInMicroseconds: ${trace?.startTimeInMicroseconds}, '
          'duration: $duration, '
          'trace.duration: ${trace?.duration ?? 0}',
          tag: APM.tag,
        );
        LuciqLogger.I.d(
          'didReportScreenLoading: $isReported, '
          'isSameName: $isSameScreen',
          tag: APM.tag,
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
      String screenName, int startTimeInMicroseconds, int duration,) async {
    try {
      final isSDKBuilt =
          await _checkLuciqSDKBuilt("APM.LuciqCaptureScreenLoading");
      if (!isSDKBuilt) {
        LuciqLogger.I.e(
          'Luciq SDK is not built, skipping reporting manual screen loading time for screen: $screenName.',
          tag: APM.tag,
        );
        return;
      }

      final isScreenLoadingEnabled =
          await FlagsConfig.screenLoading.isEnabled();
      if (!isScreenLoadingEnabled) {
        LuciqLogger.I.e(
          'Screen loading monitoring is disabled, skipping reporting manual screen loading time for screen: $screenName.\n'
          'Please refer to the documentation for how to enable screen loading monitoring on your app: '
          'https://docs.luciq.ai/docs/flutter-apm-screen-loading#disablingenabling-screen-loading-tracking '
          "If Screen Loading is enabled but you're still seeing this message, please reach out to support.",
          tag: APM.tag,
        );
        return;
      }

      APM.reportManualScreenLoadingCP(
          screenName, startTimeInMicroseconds, duration,);
      return;
    } catch (error, stackTrace) {
      _logExceptionErrorAndStackTrace(error, stackTrace);
    }
  }

  void _reportScreenLoadingDroppedError(ScreenLoadingTrace? trace) {
    LuciqLogger.I.e(
      "Screen Loading trace dropped as the trace isn't from the current screen, or another trace was reported before the current one. — $trace",
      tag: APM.tag,
    );
  }

  /// Extends the already ended screen loading adding a stage to it
  Future<void> endScreenLoading() async {
    try {
      final isSDKBuilt = await _checkLuciqSDKBuilt("endScreenLoading");
      if (!isSDKBuilt) return;

      final isScreenLoadingEnabled =
          await FlagsConfig.screenLoading.isEnabled();
      if (!isScreenLoadingEnabled) {
        LuciqLogger.I.e(
          'Screen loading monitoring is disabled, skipping ending screen loading monitoring with APM.endScreenLoading().\n'
          'Please refer to the documentation for how to enable screen loading monitoring in your app: '
          'https://docs.luciq.ai/docs/flutter-apm-screen-loading#disablingenabling-screen-loading-tracking '
          "If Screen Loading is enabled but you're still seeing this message, please reach out to support.",
          tag: APM.tag,
        );
        return;
      }

      final isEndScreenLoadingEnabled =
          await FlagsConfig.endScreenLoading.isEnabled();

      if (!isEndScreenLoadingEnabled) {
        LuciqLogger.I.e(
          'End Screen loading API is disabled.\n'
          'Please refer to the documentation for how to enable screen loading monitoring in your app: '
          'https://docs.luciq.ai/docs/flutter-apm-screen-loading#disablingenabling-screen-loading-tracking '
          "If Screen Loading is enabled but you're still seeing this message, please reach out to support.",
          tag: APM.tag,
        );

        return;
      }

      final didExtendScreenLoading =
          currentUiTrace?.didExtendScreenLoading == true;
      if (didExtendScreenLoading) {
        LuciqLogger.I.e(
          'endScreenLoading has already been called for the current screen visit. Multiple calls to this API are not allowed during a single screen visit, only the first call will be considered.',
          tag: APM.tag,
        );
        return;
      }

      // Handles no active screen loading trace - cannot end
      final didStartScreenLoading =
          currentScreenLoadingTrace?.startTimeInMicroseconds != null;
      if (!didStartScreenLoading) {
        LuciqLogger.I.e(
          "endScreenLoading wasn’t called as there is no active screen loading trace.",
          tag: APM.tag,
        );
        return;
      }

      final extendedMonotonicEndTimeInMicroseconds = LuciqMonotonicClock.I.now;

      var duration = extendedMonotonicEndTimeInMicroseconds -
          currentScreenLoadingTrace!.startMonotonicTimeInMicroseconds;

      var extendedEndTimeInMicroseconds =
          currentScreenLoadingTrace!.startTimeInMicroseconds + duration;

      // cannot extend as the trace has not ended yet.
      // we report the extension timestamp as 0 and can be override later on.
      final didEndScreenLoadingPrematurely =
          currentScreenLoadingTrace?.endTimeInMicroseconds == null;
      if (didEndScreenLoadingPrematurely) {
        extendedEndTimeInMicroseconds = 0;
        duration = 0;

        LuciqLogger.I.e(
          "endScreenLoading was called too early in the Screen Loading cycle. Please make sure to call the API after the screen is done loading.",
          tag: APM.tag,
        );
      }
      LuciqLogger.I.d(
        'endTimeInMicroseconds: ${currentScreenLoadingTrace?.endTimeInMicroseconds}, '
        'didEndScreenLoadingPrematurely: $didEndScreenLoadingPrematurely, extendedEndTimeInMicroseconds: $extendedEndTimeInMicroseconds.',
        tag: APM.tag,
      );
      LuciqLogger.I.d(
        'Ending screen loading capture — duration: $extendedEndTimeInMicroseconds',
        tag: APM.tag,
      );

      // Wait for UI trace validation before calling native API
      final isUiTraceValid = await currentUiTrace?.whenValidated.timeout(
        const Duration(milliseconds: _traceValidationTimeout),
        onTimeout: () {
          LuciqLogger.I.e(
            'UI trace validation timed out — dropping endScreenLoading',
            tag: APM.tag,
          );
          return false;
        },
      );

      if (isUiTraceValid != true) {
        LuciqLogger.I.d(
          'Dropping endScreenLoading — UI trace validation failed',
          tag: APM.tag,
        );
        return;
      }

      // Ends screen loading trace
      APM.endScreenLoadingCP(
        extendedEndTimeInMicroseconds,
        currentUiTrace?.traceId ?? 0,
      );
      currentUiTrace?.didExtendScreenLoading = true;

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
