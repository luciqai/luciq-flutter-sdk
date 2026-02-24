import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luciq_flutter/luciq_flutter.dart';
import 'package:mockito/mockito.dart';
import '../luciq_navigator_observer_test.mocks.dart';

void main() {
  late MockScreenLoadingManager mockScreenLoadingManager;

  setUp(() {
    mockScreenLoadingManager = MockScreenLoadingManager();
    ScreenLoadingManager.setInstance(mockScreenLoadingManager);
  });

  testWidgets(
      'LuciqCaptureScreenLoading starts and reports screen loading trace',
      (WidgetTester tester) async {
    const screenName = "/TestScreen";

    when(mockScreenLoadingManager.sanitizeScreenName(screenName))
        .thenReturn(screenName);
    when(mockScreenLoadingManager.startScreenLoadingTrace(any))
        .thenAnswer((_) async {});
    when(mockScreenLoadingManager.reportScreenLoading(any))
        .thenAnswer((_) async {});

    await tester.pumpWidget(
      MaterialApp(
        home: LuciqCaptureScreenLoading(
          screenName: screenName,
          child: Container(),
        ),
      ),
    );

    verify(mockScreenLoadingManager.startScreenLoadingTrace(any)).called(1);
    await tester.pumpAndSettle();
    verify(mockScreenLoadingManager.reportScreenLoading(any)).called(1);
  });
}
