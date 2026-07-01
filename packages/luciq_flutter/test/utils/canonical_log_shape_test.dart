// Verifies canonical [Feature.method] phase= shape on the paths that were
// recently refit (NavigatorObserver, PrivateViewsManager). The hostCall
// machinery itself is covered by host_call_test.dart - this file checks the
// callsites only.

import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luciq_flutter/luciq_flutter.dart';
import 'package:luciq_flutter/src/utils/private_views/private_views_manager.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'canonical_log_shape_test.mocks.dart';

@GenerateMocks([LuciqLogger])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockLuciqLogger logger;

  setUp(() {
    logger = MockLuciqLogger();
    when(logger.isDebugEnabled()).thenReturn(true);
    LuciqLogger.setInstance(logger);
  });

  group('PrivateViewsManager.getPrivateViews', () {
    testWidgets('emits PRIV.capture fire and exit with threaded callId',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));

      PrivateViewsManager.I.getPrivateViews('a1b2');

      final captured = verify(
        logger.d(captureAny, tag: anyNamed('tag')),
      ).captured.cast<String>();

      expect(
        captured,
        contains('[PRIV.capture] #a1b2 phase=fire'),
      );
      expect(
        captured.any((m) => m.startsWith('[PRIV.capture] #a1b2 phase=exit')),
        isTrue,
        reason: 'expected exit line, got: $captured',
      );
    });
  });

  group('LuciqNavigatorObserver.screenChanged', () {
    test('emits canonical SCREEN.screenChanged enter then exit', () {
      fakeAsync((async) {
        final observer = LuciqNavigatorObserver();

        observer.screenChanged(
          MaterialPageRoute<void>(
            settings: const RouteSettings(name: '/home'),
            builder: (_) => const SizedBox.shrink(),
          ),
        );

        async.elapse(const Duration(seconds: 1));

        final captured = verify(
          logger.d(captureAny, tag: anyNamed('tag')),
        ).captured.cast<String>();

        expect(
          captured.any(
            (m) =>
                m.startsWith('[SCREEN.screenChanged] phase=enter') &&
                m.contains('screenNameLength=5'),
          ),
          isTrue,
          reason: 'expected enter line, got: $captured',
        );
        expect(
          captured
              .any((m) => m.startsWith('[SCREEN.screenChanged] phase=exit')),
          isTrue,
          reason: 'expected exit line, got: $captured',
        );
      });
    });
  });
}
