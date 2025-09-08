import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luciq_flutter/luciq_flutter.dart';
import 'package:luciq_flutter/src/utils/private_views/private_views_manager.dart';

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

  group('PrivateViewsManager Tests', () {
    late PrivateViewsManager manager;

    setUp(() {
      manager = PrivateViewsManager.instance;
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
  });
}
