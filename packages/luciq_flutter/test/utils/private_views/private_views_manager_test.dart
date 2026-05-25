import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luciq_flutter/luciq_flutter.dart';
import 'package:luciq_flutter/src/utils/private_views/private_views_manager.dart';
import 'package:luciq_flutter/src/utils/screen_rendering/luciq_screen_render_manager.dart';
import 'package:mockito/mockito.dart';

import '../luciq_navigator_observer_test.mocks.dart';

Future<Uint8List> createTestImage() async {
  // Create an empty 1x1 image
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final paint = Paint()..color = const Color(0xFFFF0000); // Red pixel
  canvas.drawRect(const Rect.fromLTWH(0, 0, 1, 1), paint);

  final img = await recorder.endRecording().toImage(1, 1);
  final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();

  // LuciqNavigatorObserver fires screenChanged on every push, which on
  // Flutter stable awaits a pigeon channel.send that never resolves in
  // test mode and hangs pump()/pumpAndSettle. Stubbing the host APIs and
  // singletons short-circuits the channel calls so the tests can settle.
  final mockHost = MockLuciqHostApi();
  final mockApmHost = MockApmHostApi();
  final mockScreenLoadingManager = MockScreenLoadingManager();
  final mockScreenRenderManager = MockLuciqScreenRenderManager();

  setUpAll(() {
    Luciq.$setHostApi(mockHost);
    APM.$setHostApi(mockApmHost);
    ScreenLoadingManager.setInstance(mockScreenLoadingManager);
    LuciqScreenRenderManager.setInstance(mockScreenRenderManager);
  });

  group('PrivateViewsManager Tests', () {
    late PrivateViewsManager manager;

    setUp(() {
      manager = PrivateViewsManager.instance;
      when(mockScreenLoadingManager.currentUiTrace).thenReturn(null);
    });

    test('isPrivateWidget detects LuciqPrivateView', () {
      final widget = LuciqPrivateView(child: Container());
      expect(PrivateViewsManager.isPrivateWidget(widget), isTrue);
    });

    test('isPrivateWidget detects LuciqSliverPrivateView', () {
      final widget = LuciqSliverPrivateView(sliver: Container());
      expect(PrivateViewsManager.isPrivateWidget(widget), isTrue);
    });

    test('isPrivateWidget returns false for other widgets', () {
      expect(PrivateViewsManager.isPrivateWidget(Container()), isFalse);
      expect(PrivateViewsManager.isPrivateWidget(const Text('Hello')), isFalse);
    });

    testWidgets('getRectsOfPrivateViews detects masked views', (tester) async {
      await tester.pumpWidget(
        LuciqWidget(
          child: MaterialApp(
            home: Scaffold(
              body: ListView(
                children: const [
                  SizedBox(width: 100, height: 100),
                  LuciqPrivateView(child: TextField()),
                ],
              ),
            ),
          ),
        ),
      );

      final rects = manager.getRectsOfPrivateViews();
      expect(rects.length, 1);
    });

    testWidgets('getRectsOfPrivateViews detects masked labels', (tester) async {
      await tester.pumpWidget(
        LuciqWidget(
          automasking: const [AutoMasking.labels],
          child: MaterialApp(
            home: Scaffold(
              body: ListView(
                children: const [
                  SizedBox(width: 100, height: 100),
                  Text("Test 1"),
                  Text("Test 2"),
                ],
              ),
            ),
          ),
        ),
      );

      final rects = manager.getRectsOfPrivateViews();
      expect(rects.length, 2);
    });

    testWidgets(
        'getPrivateViews returns correct list of masked view coordinates',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: const [
                LuciqPrivateView(
                  child: SizedBox(width: 50, height: 50),
                ),
              ],
            ),
          ),
        ),
      );

      final privateViews = manager.getPrivateViews();
      expect(
        privateViews.length % 4,
        0,
      ); // Ensure coordinates come in sets of four
    });

    testWidgets('getRectsOfPrivateViews detects masked Media', (tester) async {
      final validImage = await tester.runAsync(() => createTestImage());

      await tester.pumpWidget(
        LuciqWidget(
          automasking: const [AutoMasking.media],
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  const SizedBox(width: 100, height: 100),
                  Image.memory(
                    validImage!,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      final rects = manager.getRectsOfPrivateViews();
      expect(rects.length, 1);
    });

    testWidgets(
        'getRectsOfPrivateViews returns empty when no private views are mounted and auto-masking is off',
        (tester) async {
      // Reset auto-masking to AutoMasking.none to take the fast path.
      manager.addAutoMasking(const [AutoMasking.none]);

      await tester.pumpWidget(
        LuciqWidget(
          child: MaterialApp(
            home: Scaffold(
              body: ListView(
                children: const [
                  SizedBox(width: 100, height: 100),
                  Text('Plain text'),
                  TextField(),
                ],
              ),
            ),
          ),
        ),
      );

      expect(manager.getRectsOfPrivateViews(), isEmpty);
    });

    testWidgets('getRectsOfPrivateViews drops rects of unmounted private views',
        (tester) async {
      manager.addAutoMasking(const [AutoMasking.none]);

      await tester.pumpWidget(
        const LuciqWidget(
          child: MaterialApp(
            home: Scaffold(
              body: LuciqPrivateView(
                child: SizedBox(width: 100, height: 100),
              ),
            ),
          ),
        ),
      );

      expect(manager.getRectsOfPrivateViews().length, 1);

      // Replace the tree so the previous LuciqPrivateView is disposed.
      await tester.pumpWidget(
        const LuciqWidget(
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(width: 100, height: 100),
            ),
          ),
        ),
      );

      expect(manager.getRectsOfPrivateViews(), isEmpty);
    });

    testWidgets('getRectsOfPrivateViews detects masked textInputs',
        (tester) async {
      await tester.pumpWidget(
        LuciqWidget(
          automasking: const [AutoMasking.textInputs],
          child: MaterialApp(
            home: Scaffold(
              body: ListView(
                children: const [
                  SizedBox(width: 100, height: 100),
                  TextField(),
                ],
              ),
            ),
          ),
        ),
      );

      final rects = manager.getRectsOfPrivateViews();
      expect(rects.length, 1);
    });

    group('background visibility under overlays', () {
      tearDown(LuciqNavigatorObserver.debugResetInstances);

      testWidgets(
          'reports background LuciqPrivateView when a non-opaque overlay '
          '(dialog / popup) is pushed on top',
          (tester) async {
        LuciqNavigatorObserver.debugResetInstances();
        manager.addAutoMasking(const [AutoMasking.none]);
        final navigatorKey = GlobalKey<NavigatorState>();
        await tester.pumpWidget(
          LuciqWidget(
            child: MaterialApp(
              navigatorKey: navigatorKey,
              navigatorObservers: [
                LuciqNavigatorObserver(screenReportDelay: Duration.zero),
              ],
              home: const Scaffold(
                body: LuciqPrivateView(
                  child: SizedBox(width: 100, height: 100),
                ),
              ),
            ),
          ),
        );

        expect(manager.getRectsOfPrivateViews().length, 1);

        // A non-opaque route mirrors DialogRoute / ModalBottomSheetRoute /
        // PopupRoute behaviour (all opaque = false). Using PageRouteBuilder
        // avoids `showDialog`'s never-completing future, which hangs
        // pumpAndSettle.
        // ignore: unawaited_futures
        navigatorKey.currentState!.push<void>(
          PageRouteBuilder<void>(
            opaque: false,
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
            pageBuilder: (_, __, ___) =>
                const Center(child: Text('overlay')),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(manager.getRectsOfPrivateViews().length, 1);
      });

      testWidgets(
          'reports background LuciqPrivateView when a bottom sheet is shown on top',
          (tester) async {
        LuciqNavigatorObserver.debugResetInstances();
        manager.addAutoMasking(const [AutoMasking.none]);
        final navigatorKey = GlobalKey<NavigatorState>();
        await tester.pumpWidget(
          LuciqWidget(
            child: MaterialApp(
              navigatorKey: navigatorKey,
              navigatorObservers: [
                LuciqNavigatorObserver(screenReportDelay: Duration.zero),
              ],
              home: const Scaffold(
                body: LuciqPrivateView(
                  child: SizedBox(width: 100, height: 100),
                ),
              ),
            ),
          ),
        );

        expect(manager.getRectsOfPrivateViews().length, 1);

        final sheetController =
            BottomSheet.createAnimationController(navigatorKey.currentState!)
              ..duration = Duration.zero
              ..reverseDuration = Duration.zero;
        // ignore: unawaited_futures
        showModalBottomSheet<void>(
          context: navigatorKey.currentContext!,
          transitionAnimationController: sheetController,
          builder: (_) => const SizedBox(height: 100, child: Text('sheet')),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(manager.getRectsOfPrivateViews().length, 1);
      });

      testWidgets(
          'reports background auto-masked labels when a dialog is shown on top',
          (tester) async {
        LuciqNavigatorObserver.debugResetInstances();
        final navigatorKey = GlobalKey<NavigatorState>();
        await tester.pumpWidget(
          LuciqWidget(
            automasking: const [AutoMasking.labels],
            child: MaterialApp(
              navigatorKey: navigatorKey,
              navigatorObservers: [
                LuciqNavigatorObserver(screenReportDelay: Duration.zero),
              ],
              // Column lacks a const constructor on the Flutter SDK paired
              // with Dart 2.10.5, so Scaffold/Column stay non-const here.
              // ignore: prefer_const_constructors
              home: Scaffold(
                // ignore: prefer_const_constructors
                body: Column(
                  children: const [
                    Text('Background label 1'),
                    Text('Background label 2'),
                  ],
                ),
              ),
            ),
          ),
        );

        expect(manager.getRectsOfPrivateViews().length, 2);

        // Non-opaque overlay simulates a dialog / popup; no never-completing
        // future to hang pumpAndSettle.
        // ignore: unawaited_futures
        navigatorKey.currentState!.push<void>(
          PageRouteBuilder<void>(
            opaque: false,
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
            pageBuilder: (_, __, ___) =>
                const Center(child: Text('overlay label')),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        // Two background labels must still be reported. The overlay adds its
        // own label rect, so length grows but stays >= 2.
        expect(
          manager.getRectsOfPrivateViews().length,
          greaterThanOrEqualTo(2),
        );
      });

      testWidgets(
          'drops rects from previous route after an opaque MaterialPageRoute push '
          '(regression guard for the original isElementInCurrentRoute fix)',
          (tester) async {
        LuciqNavigatorObserver.debugResetInstances();
        manager.addAutoMasking(const [AutoMasking.none]);
        final navigatorKey = GlobalKey<NavigatorState>();
        await tester.pumpWidget(
          LuciqWidget(
            child: MaterialApp(
              navigatorKey: navigatorKey,
              navigatorObservers: [
                LuciqNavigatorObserver(screenReportDelay: Duration.zero),
              ],
              home: const Scaffold(
                body: LuciqPrivateView(
                  child: SizedBox(width: 100, height: 100),
                ),
              ),
            ),
          ),
        );

        expect(manager.getRectsOfPrivateViews().length, 1);

        // ignore: unawaited_futures
        navigatorKey.currentState!.push<void>(
          PageRouteBuilder<void>(
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
            pageBuilder: (_, __, ___) =>
                const Scaffold(body: Text('Page B')),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        // Page A's private rect must NOT bleed onto Page B.
        expect(manager.getRectsOfPrivateViews(), isEmpty);
      });

      testWidgets(
          'drops rects from previous route after pushNamed (example-app pattern, '
          "mirrors the bug where Core-page screenshot showed MyHomePage's rect)",
          (tester) async {
        LuciqNavigatorObserver.debugResetInstances();
        manager.addAutoMasking(const [AutoMasking.none]);
        final navigatorKey = GlobalKey<NavigatorState>();
        final routeBuilders = <String, WidgetBuilder>{
          '/': (_) => const Scaffold(
                body: LuciqPrivateView(
                  child: SizedBox(width: 100, height: 100),
                ),
              ),
          '/page-b': (_) => const Scaffold(body: Text('Page B')),
        };
        await tester.pumpWidget(
          LuciqWidget(
            child: MaterialApp(
              navigatorKey: navigatorKey,
              navigatorObservers: [
                LuciqNavigatorObserver(screenReportDelay: Duration.zero),
              ],
              onGenerateRoute: (settings) => PageRouteBuilder<void>(
                settings: settings,
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
                pageBuilder: (ctx, __, ___) =>
                    routeBuilders[settings.name]!(ctx),
              ),
            ),
          ),
        );

        expect(manager.getRectsOfPrivateViews().length, 1);

        // ignore: unawaited_futures
        navigatorKey.currentState!.pushNamed('/page-b');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(manager.getRectsOfPrivateViews(), isEmpty);
      });

      testWidgets(
          'reports rect of a LuciqPrivateView with no enclosing ModalRoute',
          (tester) async {
        LuciqNavigatorObserver.debugResetInstances();
        manager.addAutoMasking(const [AutoMasking.none]);
        // Widget tree without MaterialApp / Navigator — element has no
        // ModalRoute ancestor. Previously the `?? false` filtered it out.
        await tester.pumpWidget(
          const Directionality(
            textDirection: TextDirection.ltr,
            child: LuciqWidget(
              child: LuciqPrivateView(
                child: SizedBox(width: 100, height: 100),
              ),
            ),
          ),
        );

        expect(manager.getRectsOfPrivateViews().length, 1);
      });
    });
  });
}
