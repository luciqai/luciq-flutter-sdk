import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:luciq_flutter/luciq_flutter.dart';
import 'package:luciq_flutter/src/generated/luciq_private_view.api.g.dart';
import 'package:luciq_flutter/src/utils/luciq_logger.dart';
import 'package:luciq_flutter/src/utils/private_views/private_views_manager.dart';
import 'package:meta/meta.dart';

@internal
final luciqWidgetKey = GlobalKey(debugLabel: 'luciq_screenshot_widget');

class LuciqWidget extends StatefulWidget {
  final Widget child;
  final bool enablePrivateViews;
  final bool enableUserSteps;
  final List<AutoMasking>? automasking;

  /// Custom handler for Flutter errors.
  ///
  /// This callback is called when a Flutter error occurs. It receives a
  /// [FlutterErrorDetails] object containing information about the error.
  ///
  /// Example:
  /// ```dart
  /// LuciqWidget(
  ///   flutterErrorHandler: (details) {
  ///     print('Flutter error: ${details.exception}');
  ///     // Custom error handling logic
  ///   },
  ///   child: MyApp(),
  /// )
  /// ```
  ///
  /// Note: If this handler throws an error, it will be caught and logged
  /// to prevent it from interfering with Luciq's error reporting.
  final Function(FlutterErrorDetails)? flutterErrorHandler;

  /// Custom handler for platform errors.
  ///
  /// This callback is called when a platform error occurs. It receives the
  /// error object and stack trace.
  ///
  /// Example:
  /// ```dart
  /// LuciqWidget(
  ///   platformErrorHandler: (error, stack) {
  ///     print('Platform error: $error');
  ///     // Custom error handling logic
  ///   },
  ///   child: MyApp(),
  /// )
  /// ```
  ///
  /// Note: If this handler throws an error, it will be caught and logged
  /// to prevent it from interfering with Luciq's error reporting.
  final Function(Object, StackTrace)? platformErrorHandler;

  /// Whether to handle Flutter errors.
  ///
  /// If true, the Flutter error will be reported as a non-fatal crash, instead of a fatal crash.
  final bool nonFatalFlutterErrors;

  /// The level of the non-fatal exception.
  ///
  /// This is used to determine the level of the non-fatal exception.
  ///
  /// Note: This has no effect if [nonFatalFlutterErrors] is false.
  final NonFatalExceptionLevel nonFatalExceptionLevel;

  /// This widget is used to wrap the root of your application. It will automatically
  /// configure both FlutterError.onError and PlatformDispatcher.instance.onError handlers to report errors to Luciq.
  ///
  /// Example:
  /// ```dart
  /// MaterialApp(
  ///   home: LuciqWidget(
  ///     child: MyApp(),
  ///   ),
  /// )
  /// ```
  ///
  /// Note: Custom error handlers are called before the error is reported to Luciq.

  const LuciqWidget({
    Key? key,
    required this.child,
    this.enableUserSteps = true,
    this.enablePrivateViews = true,
    this.automasking,
    this.flutterErrorHandler,
    this.platformErrorHandler,
    this.nonFatalFlutterErrors = false,
    this.nonFatalExceptionLevel = NonFatalExceptionLevel.error,

  }) : super(key: key);

  @override
  State<LuciqWidget> createState() => _LuciqWidgetState();
}

class _LuciqWidgetState extends State<LuciqWidget> {
  @override
  void initState() {
    if (widget.enablePrivateViews) {
      _enableLuciqMaskingPrivateViews();
    }
    if (widget.automasking != null) {
      PrivateViewsManager.I.addAutoMasking(widget.automasking!);
    }
    _setupErrorHandlers();

    super.initState();
  }

  void _setupErrorHandlers() {
    FlutterError.onError = (FlutterErrorDetails details) {
      // Call user's custom handler if provided
      if (widget.flutterErrorHandler != null) {
        try {
          widget.flutterErrorHandler!(details);
        } catch (e) {
          LuciqLogger.I.e(
            'Custom Flutter error handler failed: $e',
            tag: 'LuciqWidget',
          );
        }
      }

      if (widget.nonFatalFlutterErrors) {
        CrashReporting.reportHandledCrash(
          details.exception,
          details.stack ?? StackTrace.current,
          level: widget.nonFatalExceptionLevel,
        );
      } else {
        CrashReporting.reportCrash(
          details.exception,
          details.stack ?? StackTrace.current,
        );
      }

      FlutterError.presentError(details);
    };

    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      // Call user's custom handler if provided
      if (widget.platformErrorHandler != null) {
        try {
          widget.platformErrorHandler!(error, stack);
        } catch (e) {
          LuciqLogger.I.e(
            'Custom platform error handler failed: $e',
            tag: 'LuciqWidget',
          );
        }
      }

      CrashReporting.reportCrash(error, stack);

      return true;
    };
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.enableUserSteps
        ? LuciqUserSteps(child: widget.child)
        : widget.child;

    if (widget.enablePrivateViews) {
      return RepaintBoundary(
        key: luciqWidgetKey,
        child: child,
      );
    }
    return child;
  }
}

void _enableLuciqMaskingPrivateViews() {
  final api = LuciqPrivateViewHostApi();
  api.init();
  LuciqPrivateViewFlutterApi.setup(PrivateViewsManager.I);
}
