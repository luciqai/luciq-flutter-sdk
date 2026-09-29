import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luciq_flutter/luciq_flutter.dart';
import 'package:luciq_flutter/src/utils/private_views/private_view_debug_check.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Private view setup warning', () {
    late List<String> logs;

    setUp(() {
      debugResetPrivateViewSetupWarning();
      logs = [];
    });

    /// Captures [debugPrint] output while pumping [widget], then restores it
    /// before the test ends (flutter_test asserts it is restored).
    Future<void> pumpCapturingLogs(WidgetTester tester, Widget widget) async {
      final original = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) logs.add(message);
      };
      try {
        await tester.pumpWidget(widget);
      } finally {
        debugPrint = original;
      }
    }

    List<String> warnings() =>
        logs.where((m) => m.contains('will NOT be masked')).toList();

    testWidgets('warns once when LuciqPrivateView has no LuciqWidget ancestor',
        (tester) async {
      await pumpCapturingLogs(
        tester,
        const MaterialApp(
          home: Column(
            children: [
              LuciqPrivateView(child: Text('national id')),
              LuciqPrivateView(child: Text('phone')),
            ],
          ),
        ),
      );

      expect(warnings(), hasLength(1));
      expect(warnings().single, contains('LuciqPrivateView'));
      expect(warnings().single, contains('no LuciqWidget ancestor'));
    });

    testWidgets('warns when LuciqSliverPrivateView has no LuciqWidget ancestor',
        (tester) async {
      await pumpCapturingLogs(
        tester,
        const MaterialApp(
          home: CustomScrollView(
            slivers: [
              LuciqSliverPrivateView(
                sliver: SliverToBoxAdapter(child: Text('national id')),
              ),
            ],
          ),
        ),
      );

      expect(warnings(), hasLength(1));
      expect(warnings().single, contains('LuciqSliverPrivateView'));
    });

    testWidgets('warns when LuciqWidget has private views disabled',
        (tester) async {
      await pumpCapturingLogs(
        tester,
        const LuciqWidget(
          enablePrivateViews: false,
          child: MaterialApp(
            home: LuciqPrivateView(child: Text('national id')),
          ),
        ),
      );

      expect(warnings(), hasLength(1));
      expect(warnings().single, contains('enablePrivateViews is false'));
    });

    testWidgets('does not warn when wrapped in LuciqWidget', (tester) async {
      await pumpCapturingLogs(
        tester,
        const LuciqWidget(
          child: MaterialApp(
            home: LuciqPrivateView(child: Text('national id')),
          ),
        ),
      );

      expect(warnings(), isEmpty);
    });
  });
}
