// ignore_for_file: invalid_null_aware_operator

import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luciq_flutter/luciq_flutter.dart';
import 'package:luciq_flutter/src/generated/apm.api.g.dart';
import 'package:luciq_flutter/src/generated/luciq.api.g.dart';
import 'package:luciq_flutter/src/utils/screen_loading/ui_trace.dart';
import 'package:luciq_flutter/src/utils/screen_name_masker.dart';
import 'package:luciq_flutter/src/utils/screen_rendering/luciq_screen_render_manager.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'luciq_navigator_observer_test.mocks.dart';

@GenerateMocks([
  LuciqHostApi,
  ApmHostApi,
  ScreenLoadingManager,
  LuciqScreenRenderManager,
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final mHost = MockLuciqHostApi();
  final mApmHost = MockApmHostApi();
  final mScreenLoadingManager = MockScreenLoadingManager();
  final mScreenRenderManager = MockLuciqScreenRenderManager();

  late LuciqNavigatorObserver observer;
  const screen = '/screen';
  const previousScreen = '/previousScreen';
  late Route route;
  late Route previousRoute;

  setUpAll(() {
    Luciq.$setHostApi(mHost);
    APM.$setHostApi(mApmHost);
    ScreenLoadingManager.setInstance(mScreenLoadingManager);
    LuciqScreenRenderManager.setInstance(mScreenRenderManager);
  });

  setUp(() {
    observer = LuciqNavigatorObserver();
    route = createRoute(screen);
    previousRoute = createRoute(previousScreen);

    ScreenNameMasker.I.setMaskingCallback(null);
    when(mScreenLoadingManager.currentUiTrace).thenReturn(null);
  });

  test('should report screen change when a route is pushed', () {
    fakeAsync((async) {
      observer.didPush(route, previousRoute);
      WidgetsBinding.instance?.handleBeginFrame(Duration.zero);
      WidgetsBinding.instance?.handleDrawFrame();
      async.elapse(const Duration(milliseconds: 2000));

      verify(
        mScreenLoadingManager.prepareUiTrace(screen, screen),
      ).called(1);

      verify(
        mHost.reportScreenChange(screen),
      ).called(1);
    });
  });

  test('should respect configured screen report delay', () {
    fakeAsync((async) {
      observer = LuciqNavigatorObserver(
        screenReportDelay: const Duration(milliseconds: 500),
      );

      observer.didPush(route, previousRoute);
      WidgetsBinding.instance?.handleBeginFrame(Duration.zero);
      WidgetsBinding.instance?.handleDrawFrame();
      async.elapse(const Duration(milliseconds: 400));

      verifyNever(
        mHost.reportScreenChange(screen),
      );

      async.elapse(const Duration(milliseconds: 100));

      verify(
        mScreenLoadingManager.prepareUiTrace(screen, screen),
      ).called(1);

      verify(
        mHost.reportScreenChange(screen),
      ).called(1);
    });
  });

  test(
      'should report screen change when a route is popped and previous is known',
      () {
    fakeAsync((async) {
      observer.didPop(route, previousRoute);
      WidgetsBinding.instance?.handleBeginFrame(Duration.zero);
      WidgetsBinding.instance?.handleDrawFrame();
      async.elapse(const Duration(milliseconds: 1000));

      verify(
        mScreenLoadingManager.prepareUiTrace(previousScreen, previousScreen),
      ).called(1);

      verify(
        mHost.reportScreenChange(previousScreen),
      ).called(1);
    });
  });

  test(
      'should not report screen change when a route is popped and previous is not known',
      () {
    fakeAsync((async) {
      observer.didPop(route, null);
      WidgetsBinding.instance?.handleBeginFrame(Duration.zero);
      WidgetsBinding.instance?.handleDrawFrame();
      async.elapse(const Duration(milliseconds: 1000));

      verifyNever(
        mScreenLoadingManager.prepareUiTrace(any, any),
      );

      verifyNever(
        mHost.reportScreenChange(any),
      );
    });
  });

  test('should fallback to "N/A" when the screen name is empty', () {
    fakeAsync((async) {
      final route = createRoute('');
      const fallback = 'N/A';

      observer.didPush(route, previousRoute);
      WidgetsBinding.instance?.handleBeginFrame(Duration.zero);
      WidgetsBinding.instance?.handleDrawFrame();
      async.elapse(const Duration(milliseconds: 1000));

      verify(
        mScreenLoadingManager.prepareUiTrace(fallback, fallback),
      ).called(1);

      verify(
        mHost.reportScreenChange(fallback),
      ).called(1);
    });
  });

  test('should mask screen name when masking callback is set', () {
    const maskedScreen = 'maskedScreen';

    ScreenNameMasker.I.setMaskingCallback((_) => maskedScreen);

    fakeAsync((async) {
      observer.didPush(route, previousRoute);
      WidgetsBinding.instance?.handleBeginFrame(Duration.zero);
      WidgetsBinding.instance?.handleDrawFrame();
      async.elapse(const Duration(milliseconds: 2000));

      verify(
        mScreenLoadingManager.prepareUiTrace(maskedScreen, screen),
      ).called(1);

      verify(
        mHost.reportScreenChange(maskedScreen),
      ).called(1);
    });
  });

  test('should start new screen render collector when a route is pushed', () {
    fakeAsync((async) {
      const traceID = 123;

      final uiTrace = UiTrace(screenName: screen, traceId: traceID);
      uiTrace.validationCompleter.complete(true);
      when(mScreenLoadingManager.currentUiTrace).thenReturn(uiTrace);
      when(mApmHost.isScreenRenderEnabled()).thenAnswer((_) async => true);

      observer.didPush(route, previousRoute);
      WidgetsBinding.instance?.handleBeginFrame(Duration.zero);
      WidgetsBinding.instance?.handleDrawFrame();
      async.elapse(const Duration(milliseconds: 1000));

      verify(
        mScreenRenderManager.startScreenRenderCollectorForTraceId(traceID),
      ).called(1);
    });
  });

  test(
      'should not start new screen render collector when a route is pushed and currentUiTrace is null',
      () {
    fakeAsync((async) {
      when(mScreenLoadingManager.currentUiTrace).thenReturn(null);

      observer.didPush(route, previousRoute);
      WidgetsBinding.instance?.handleBeginFrame(Duration.zero);
      WidgetsBinding.instance?.handleDrawFrame();
      async.elapse(const Duration(milliseconds: 1000));

      verifyNever(
        mScreenRenderManager.startScreenRenderCollectorForTraceId(any),
      );
    });
  });

  test(
      'should not start new screen render collector when a route is pushed and UI trace validation fails',
      () {
    fakeAsync((async) {
      final uiTrace = UiTrace(screenName: screen, traceId: 123);
      uiTrace.validationCompleter.complete(false);
      when(mScreenLoadingManager.currentUiTrace).thenReturn(uiTrace);

      observer.didPush(route, previousRoute);
      WidgetsBinding.instance?.handleBeginFrame(Duration.zero);
      WidgetsBinding.instance?.handleDrawFrame();
      async.elapse(const Duration(milliseconds: 1000));

      verifyNever(
        mScreenRenderManager.startScreenRenderCollectorForTraceId(any),
      );
    });
  });

  test(
      'should not start new screen render collector when a route is pushed and screen rendering is disabled',
      () {
    fakeAsync((async) {
      const traceID = 123;

      final uiTrace = UiTrace(screenName: screen, traceId: traceID);
      uiTrace.validationCompleter.complete(true);
      when(mScreenLoadingManager.currentUiTrace).thenReturn(uiTrace);
      when(mApmHost.isScreenRenderEnabled()).thenAnswer((_) async => false);

      observer.didPush(route, previousRoute);
      WidgetsBinding.instance?.handleBeginFrame(Duration.zero);
      WidgetsBinding.instance?.handleDrawFrame();
      async.elapse(const Duration(milliseconds: 1000));

      verifyNever(
        mScreenRenderManager.startScreenRenderCollectorForTraceId(any),
      );
    });
  });

  group('isRouteVisible', () {
    setUp(LuciqNavigatorObserver.debugResetInstances);
    tearDown(LuciqNavigatorObserver.debugResetInstances);

    test('returns null when no observer instance has seen the route', () {
      // Reset and create a fresh observer that has never seen this route.
      LuciqNavigatorObserver.debugResetInstances();
      LuciqNavigatorObserver();
      final unseen = MaterialPageRoute<void>(builder: (_) => Container());

      expect(LuciqNavigatorObserver.isRouteVisible(unseen), isNull);
    });

    test('returns null when no observer instances are registered', () {
      LuciqNavigatorObserver.debugResetInstances();
      final route = MaterialPageRoute<void>(builder: (_) => Container());

      expect(LuciqNavigatorObserver.isRouteVisible(route), isNull);
    });

    test('returns true for the only route on the stack', () {
      final obs = LuciqNavigatorObserver();
      final routeA = MaterialPageRoute<void>(builder: (_) => Container());
      obs.didPush(routeA, null);

      expect(LuciqNavigatorObserver.isRouteVisible(routeA), isTrue);
    });

    test('returns true for a route covered only by a non-opaque overlay', () {
      final obs = LuciqNavigatorObserver();
      final routeA = MaterialPageRoute<void>(builder: (_) => Container());
      final overlay = PageRouteBuilder<void>(
        opaque: false,
        pageBuilder: (_, __, ___) => Container(),
      );
      obs.didPush(routeA, null);
      obs.didPush(overlay, routeA);

      expect(overlay.opaque, isFalse);
      expect(LuciqNavigatorObserver.isRouteVisible(routeA), isTrue);
      expect(LuciqNavigatorObserver.isRouteVisible(overlay), isTrue);
    });

    test(
        'returns false for a route covered by an opaque MaterialPageRoute push',
        () {
      final obs = LuciqNavigatorObserver();
      final routeA = MaterialPageRoute<void>(builder: (_) => Container());
      final routeB = MaterialPageRoute<void>(builder: (_) => Container());
      obs.didPush(routeA, null);
      obs.didPush(routeB, routeA);

      expect(routeB.opaque, isTrue);
      expect(LuciqNavigatorObserver.isRouteVisible(routeA), isFalse);
      expect(LuciqNavigatorObserver.isRouteVisible(routeB), isTrue);
    });

    test('updates the stack on didPop', () {
      final obs = LuciqNavigatorObserver();
      final routeA = MaterialPageRoute<void>(builder: (_) => Container());
      final routeB = MaterialPageRoute<void>(builder: (_) => Container());
      obs.didPush(routeA, null);
      obs.didPush(routeB, routeA);
      obs.didPop(routeB, routeA);

      expect(LuciqNavigatorObserver.isRouteVisible(routeA), isTrue);
      // routeB is no longer in the stack.
      expect(LuciqNavigatorObserver.isRouteVisible(routeB), isNull);
    });

    test('updates the stack on didRemove', () {
      final obs = LuciqNavigatorObserver();
      final routeA = MaterialPageRoute<void>(builder: (_) => Container());
      final routeB = MaterialPageRoute<void>(builder: (_) => Container());
      obs.didPush(routeA, null);
      obs.didPush(routeB, routeA);
      obs.didRemove(routeB, routeA);

      expect(LuciqNavigatorObserver.isRouteVisible(routeA), isTrue);
      expect(LuciqNavigatorObserver.isRouteVisible(routeB), isNull);
    });

    test('replaces a route in place on didReplace', () {
      final obs = LuciqNavigatorObserver();
      final routeA = MaterialPageRoute<void>(builder: (_) => Container());
      final routeB = MaterialPageRoute<void>(builder: (_) => Container());
      final routeC = MaterialPageRoute<void>(builder: (_) => Container());
      obs.didPush(routeA, null);
      obs.didPush(routeB, routeA);
      obs.didReplace(newRoute: routeC, oldRoute: routeB);

      // routeC replaced routeB at the same index — it is on top, opaque.
      expect(LuciqNavigatorObserver.isRouteVisible(routeC), isTrue);
      expect(LuciqNavigatorObserver.isRouteVisible(routeA), isFalse);
      expect(LuciqNavigatorObserver.isRouteVisible(routeB), isNull);
    });
  });
}


Route createRoute(String? name) {
  return MaterialPageRoute(
    builder: (_) => Container(),
    settings: RouteSettings(name: name),
  );
}
