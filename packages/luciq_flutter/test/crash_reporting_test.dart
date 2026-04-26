import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luciq_flutter/luciq_flutter.dart';
import 'package:luciq_flutter/src/generated/crash_reporting.api.g.dart';
import 'package:luciq_flutter/src/utils/lcq_build_info.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:stack_trace/stack_trace.dart' as stack_trace;

import 'crash_reporting_test.mocks.dart';

@GenerateMocks([
  CrashReportingHostApi,
  LCQBuildInfo,
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();

  final mHost = MockCrashReportingHostApi();
  final mBuildInfo = MockLCQBuildInfo();

  setUpAll(() {
    CrashReporting.$setHostApi(mHost);
    LCQBuildInfo.setInstance(mBuildInfo);
  });

  test('[setEnabled] should call host method', () async {
    const enabled = true;

    await CrashReporting.setEnabled(enabled);

    verify(
      mHost.setEnabled(enabled),
    ).called(1);
  });

  test('[reportHandledCrash] should call host method', () async {
    try {
      final params = <dynamic>[1, 2];
      params[5] = 2;
    } catch (exception, stack) {
      final trace = stack_trace.Trace.from(stack);
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

      when(mBuildInfo.operatingSystem).thenReturn('unit-test');

      final data = CrashData(
        os: LCQBuildInfo.instance.operatingSystem,
        message: exception.toString(),
        exception: frames,
      );
      final userAttributes = {"name": "flutter"};
      const fingerPrint = "fingerprint";
      const level = NonFatalExceptionLevel.critical;

      await CrashReporting.reportHandledCrash(
        exception,
        stack,
        userAttributes: userAttributes,
        fingerprint: fingerPrint,
        level: level,
      );

      verify(
        mHost.sendNonFatalError(
          jsonEncode(data),
          userAttributes,
          fingerPrint,
          level.toString(),
        ),
      ).called(1);
    }
  });

  test('[setNDKEnabled] should call host method', () async {
    const enabled = true;

    await CrashReporting.setNDKEnabled(enabled);

    verify(
      mHost.setNDKEnabled(enabled),
    ).called(1);
  });

  group('Error Handler Installation', () {
    late FlutterExceptionHandler? savedFlutterOnError;
    late ErrorCallback? savedPlatformOnError;

    setUp(() {
      savedFlutterOnError = FlutterError.onError;
      savedPlatformOnError = PlatformDispatcher.instance.onError;
      CrashReporting.restoreErrorHandlers();
    });

    tearDown(() {
      CrashReporting.restoreErrorHandlers();
      FlutterError.onError = savedFlutterOnError;
      PlatformDispatcher.instance.onError = savedPlatformOnError;
    });

    test(
        '[installErrorHandlers] should replace FlutterError.onError and PlatformDispatcher.onError',
        () {
      final originalFlutterHandler = FlutterError.onError;
      final originalPlatformHandler = PlatformDispatcher.instance.onError;

      CrashReporting.installErrorHandlers();

      expect(CrashReporting.handlersInstalled, isTrue);
      expect(FlutterError.onError, isNot(equals(originalFlutterHandler)));
      expect(
        PlatformDispatcher.instance.onError,
        isNot(equals(originalPlatformHandler)),
      );
    });

    test('[installErrorHandlers] should be idempotent', () {
      CrashReporting.installErrorHandlers();
      final handlerAfterFirstInstall = FlutterError.onError;

      CrashReporting.installErrorHandlers();
      final handlerAfterSecondInstall = FlutterError.onError;

      expect(handlerAfterFirstInstall, equals(handlerAfterSecondInstall));
    });

    test('[restoreErrorHandlers] should restore original handlers', () {
      final originalFlutterHandler = FlutterError.onError;
      final originalPlatformHandler = PlatformDispatcher.instance.onError;

      CrashReporting.installErrorHandlers();
      CrashReporting.restoreErrorHandlers();

      expect(CrashReporting.handlersInstalled, isFalse);
      expect(FlutterError.onError, equals(originalFlutterHandler));
      expect(
        PlatformDispatcher.instance.onError,
        equals(originalPlatformHandler),
      );
    });

    test('[restoreErrorHandlers] should be safe to call when not installed',
        () {
      expect(CrashReporting.handlersInstalled, isFalse);
      CrashReporting.restoreErrorHandlers();
      expect(CrashReporting.handlersInstalled, isFalse);
    });

    test(
        '[installErrorHandlers] FlutterError.onError should chain to original handler',
        () {
      var originalCalled = false;
      FlutterError.onError = (details) {
        originalCalled = true;
      };

      when(mBuildInfo.isReleaseMode).thenReturn(false);

      CrashReporting.installErrorHandlers();

      final details = FlutterErrorDetails(
        exception: Exception('test'),
        stack: StackTrace.current,
      );
      FlutterError.onError?.call(details);

      expect(originalCalled, isTrue);
    });

    test(
        '[installErrorHandlers] PlatformDispatcher.onError should chain to original handler',
        () {
      var originalCalled = false;
      PlatformDispatcher.instance.onError = (error, stack) {
        originalCalled = true;
        return true;
      };

      when(mBuildInfo.isReleaseMode).thenReturn(false);

      CrashReporting.installErrorHandlers();

      PlatformDispatcher.instance.onError
          ?.call(Exception('test'), StackTrace.current);

      expect(originalCalled, isTrue);
    });

    test('[handlersInstalled] should reflect current state', () {
      expect(CrashReporting.handlersInstalled, isFalse);

      CrashReporting.installErrorHandlers();
      expect(CrashReporting.handlersInstalled, isTrue);

      CrashReporting.restoreErrorHandlers();
      expect(CrashReporting.handlersInstalled, isFalse);
    });
  });
}
