// ignore_for_file: invalid_null_aware_operator

import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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

  // A pre-warmed add-to-app engine with no view attached never draws a frame, so
  // an animation on its first screen (e.g. a loading spinner) keeps a transient
  // frame callback pending forever, and the scheduler never lets idle-priority
  // work run. The screen must still be reported.
  test('should report screen change while the scheduler defers idle work',
      () async {
    final scheduler = SchedulerBinding.instance;
    scheduler?.schedulingStrategy = ({
      required int priority,
      required SchedulerBinding scheduler,
    }) =>
        false;
    addTearDown(
      () => scheduler?.schedulingStrategy = defaultSchedulingStrategy,
    );
    observer = LuciqNavigatorObserver(screenReportDelay: Duration.zero);

    observer.didPush(route, previousRoute);
    // No frame is drawn here either, so the report comes at the one-second cap.
    await Future<void>.delayed(const Duration(milliseconds: 1300));

    verify(mScreenLoadingManager.prepareUiTrace(screen, screen)).called(1);
    verify(mHost.reportScreenChange(screen)).called(1);
  });

  test('should respect configured screen report delay', () {
    fakeAsync((async) {
      observer = LuciqNavigatorObserver(
        screenReportDelay: const Duration(milliseconds: 500),
      );

      observer.didPush(route, previousRoute);
      drawFrame();
      async.elapse(const Duration(milliseconds: 400));

      verifyNever(
        mHost.reportScreenChange(screen),
      );

      async.elapse(const Duration(milliseconds: 100));
      drawFrame();
      async.flushMicrotasks();

      verify(
        mScreenLoadingManager.prepareUiTrace(screen, screen),
      ).called(1);

      verify(
        mHost.reportScreenChange(screen),
      ).called(1);
    });
  });

  test('should report screen change only once a frame is drawn after the delay',
      () {
    fakeAsync((async) {
      observer.didPush(route, previousRoute);
      async.elapse(const Duration(milliseconds: 100));
      async.flushMicrotasks();

      // The screen's engine has not drawn yet: a screenshot now would be blank.
      verifyNever(mHost.reportScreenChange(any));

      drawFrame();
      async.flushMicrotasks();

      verify(mScreenLoadingManager.prepareUiTrace(screen, screen)).called(1);
      verify(mHost.reportScreenChange(screen)).called(1);
    });
  });

  test('should wait until the route animation is over before reporting', () {
    fakeAsync((async) {
      var animating = true;
      void tick(Duration _) {
        if (animating) WidgetsBinding.instance?.scheduleFrameCallback(tick);
      }

      WidgetsBinding.instance?.scheduleFrameCallback(tick);
      observer.didPush(route, previousRoute);
      async.elapse(const Duration(milliseconds: 100));
      drawFrame();
      async.flushMicrotasks();

      // The transition is still running on the frame just drawn.
      verifyNever(mHost.reportScreenChange(any));

      animating = false;
      drawFrame();
      async.flushMicrotasks();

      verify(mScreenLoadingManager.prepareUiTrace(screen, screen)).called(1);
      verify(mHost.reportScreenChange(screen)).called(1);
    });
  });

  test(
      'should report screen change after at most a second when no frame is drawn',
      () {
    fakeAsync((async) {
      observer.didPush(route, previousRoute);
      async.elapse(const Duration(milliseconds: 1099));

      verifyNever(mHost.reportScreenChange(any));

      async.elapse(const Duration(milliseconds: 1));

      verify(mScreenLoadingManager.prepareUiTrace(screen, screen)).called(1);
      verify(mHost.reportScreenChange(screen)).called(1);
    });
  });

  test(
      'should report screen change when a route is popped and previous is known',
      () {
    fakeAsync((async) {
      observer.didPop(route, previousRoute);
      WidgetsBinding.instance?.handleBeginFrame(Duration.zero);
      WidgetsBinding.instance?.handleDrawFrame();
      async.elapse(const Duration(milliseconds: 2000));

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
      async.elapse(const Duration(milliseconds: 2000));

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
      async.elapse(const Duration(milliseconds: 2000));

      verify(
        mScreenLoadingManager.prepareUiTrace(fallback, fallback),
      ).called(1);

      verify(
        mHost.reportScreenChange(fallback),
      ).called(1);
    });
  });

  test('should fallback to "N/A" when the route has no name', () {
    fakeAsync((async) {
      final route = createRoute(null);
      const fallback = 'N/A';

      observer.didPush(route, previousRoute);
      WidgetsBinding.instance?.handleBeginFrame(Duration.zero);
      WidgetsBinding.instance?.handleDrawFrame();
      async.elapse(const Duration(milliseconds: 2000));

      verify(
        mScreenLoadingManager.prepareUiTrace(fallback, fallback),
      ).called(1);

      verify(
        mHost.reportScreenChange(fallback),
      ).called(1);
      verifyNever(mHost.reportScreenChange('null'));
    });
  });

  test('should not report an unnamed popup route as a screen when pushed', () {
    fakeAsync((async) {
      observer.didPush(createPopupRoute(null), previousRoute);
      WidgetsBinding.instance?.handleBeginFrame(Duration.zero);
      WidgetsBinding.instance?.handleDrawFrame();
      async.elapse(const Duration(milliseconds: 2000));

      verifyNever(mScreenLoadingManager.prepareUiTrace(any, any));
      verifyNever(mHost.reportScreenChange(any));
    });
  });

  test(
      'should not report the screen below again when an unnamed popup is popped',
      () {
    fakeAsync((async) {
      observer.didPop(createPopupRoute(null), previousRoute);
      WidgetsBinding.instance?.handleBeginFrame(Duration.zero);
      WidgetsBinding.instance?.handleDrawFrame();
      async.elapse(const Duration(milliseconds: 2000));

      verifyNever(mScreenLoadingManager.prepareUiTrace(any, any));
      verifyNever(mHost.reportScreenChange(any));
    });
  });

  test('should report a named popup route as a screen', () {
    fakeAsync((async) {
      const dialog = '/dialog';
      observer.didPush(createPopupRoute(dialog), previousRoute);
      WidgetsBinding.instance?.handleBeginFrame(Duration.zero);
      WidgetsBinding.instance?.handleDrawFrame();
      async.elapse(const Duration(milliseconds: 2000));

      verify(mHost.reportScreenChange(dialog)).called(1);

      observer.didPop(createPopupRoute(dialog), previousRoute);
      WidgetsBinding.instance?.handleBeginFrame(Duration.zero);
      WidgetsBinding.instance?.handleDrawFrame();
      async.elapse(const Duration(milliseconds: 2000));

      verify(mHost.reportScreenChange(previousScreen)).called(1);
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
      async.elapse(const Duration(milliseconds: 2000));

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
      async.elapse(const Duration(milliseconds: 2000));

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
      async.elapse(const Duration(milliseconds: 2000));

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
      async.elapse(const Duration(milliseconds: 2000));

      verifyNever(
        mScreenRenderManager.startScreenRenderCollectorForTraceId(any),
      );
    });
  });
}

/// Draws one frame, running the frame callbacks the scheduler has pending.
void drawFrame() {
  WidgetsBinding.instance?.handleBeginFrame(Duration.zero);
  WidgetsBinding.instance?.handleDrawFrame();
}

Route createRoute(String? name) {
  return MaterialPageRoute(
    builder: (_) => Container(),
    settings: RouteSettings(name: name),
  );
}

Route createPopupRoute(String? name) =>
    _TestPopupRoute(settings: RouteSettings(name: name));

/// A dialog-like overlay route, without the BuildContext a DialogRoute needs.
class _TestPopupRoute extends PopupRoute<void> {
  _TestPopupRoute({RouteSettings? settings}) : super(settings: settings);

  @override
  Color? get barrierColor => null;

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => null;

  @override
  Duration get transitionDuration => Duration.zero;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) =>
      Container();
}
