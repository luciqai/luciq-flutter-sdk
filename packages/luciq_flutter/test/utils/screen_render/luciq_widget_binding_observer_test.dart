import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luciq_flutter/luciq_flutter.dart';
import 'package:luciq_flutter/src/generated/apm.api.g.dart';
import 'package:luciq_flutter/src/utils/lcq_build_info.dart';
import 'package:luciq_flutter/src/utils/screen_loading/ui_trace.dart';
import 'package:luciq_flutter/src/utils/screen_name_masker.dart';
import 'package:luciq_flutter/src/utils/screen_rendering/luciq_screen_render_manager.dart';
import 'package:luciq_flutter/src/utils/screen_rendering/luciq_widget_binding_observer.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'luciq_widget_binding_observer_test.mocks.dart';




@GenerateMocks([
  LuciqScreenRenderManager,
  ScreenLoadingManager,
  ScreenNameMasker,
  UiTrace,
  ApmHostApi,
  LCQBuildInfo,
])
void main() {
  late MockLuciqScreenRenderManager mockRenderManager;
  late MockScreenLoadingManager mockLoadingManager;
  late MockScreenNameMasker mockNameMasker;
  late MockUiTrace mockUiTrace;

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    mockRenderManager = MockLuciqScreenRenderManager();
    mockLoadingManager = MockScreenLoadingManager();
    mockNameMasker = MockScreenNameMasker();
    mockUiTrace = MockUiTrace();

    // Inject singleton mocks
    LuciqScreenRenderManager.setInstance(mockRenderManager);
    ScreenLoadingManager.setInstance(mockLoadingManager);
    ScreenNameMasker.setInstance(mockNameMasker);
  });

  group('LuciqWidgetsBindingObserver', () {
    final mApmHost = MockApmHostApi();
    final mIBGBuildInfo = MockLCQBuildInfo();
    setUp(() {
      APM.$setHostApi(mApmHost);
      LCQBuildInfo.setInstance(mIBGBuildInfo);
    });

    test('returns the singleton instance', () {
      final instance = LuciqWidgetsBindingObserver.instance;
      final shorthand = LuciqWidgetsBindingObserver.I;
      expect(instance, isA<LuciqWidgetsBindingObserver>());
      expect(shorthand, same(instance));
    });

    test('handles AppLifecycleState.resumed and starts UiTrace', () async {
      when(mockLoadingManager.currentUiTrace).thenReturn(mockUiTrace);
      when(mockUiTrace.screenName).thenReturn("HomeScreen");
      when(mockNameMasker.mask("HomeScreen")).thenReturn("MaskedHome");
      when(mockLoadingManager.startUiTrace("MaskedHome", "HomeScreen"))
          .thenAnswer((_) async => 123);
      when(mockRenderManager.screenRenderEnabled).thenReturn(true);

      when(mApmHost.isScreenRenderEnabled()).thenAnswer((_) async => true);

      LuciqWidgetsBindingObserver.I
          .didChangeAppLifecycleState(AppLifecycleState.resumed);

      // wait for async call to complete
      await untilCalled(
        mockRenderManager.startScreenRenderCollectorForTraceId(123),
      );

      verify(mockRenderManager.startScreenRenderCollectorForTraceId(123))
          .called(1);
    });

    test(
        'handles AppLifecycleState.paused and stops render collector for iOS platform',
        () {
      when(mockRenderManager.screenRenderEnabled).thenReturn(true);
      when(mIBGBuildInfo.isIOS).thenReturn(true);

      LuciqWidgetsBindingObserver.I
          .didChangeAppLifecycleState(AppLifecycleState.paused);

      verify(mockRenderManager.syncCollectedScreenRenderingData()).called(1);
    });

    test('handles AppLifecycleState.inactive with no action', () {
      // Just ensure it doesn't crash
      expect(
        () {
          LuciqWidgetsBindingObserver.I
              .didChangeAppLifecycleState(AppLifecycleState.inactive);
        },
        returnsNormally,
      );
    });

    test('_handleResumedState does nothing if no currentUiTrace', () {
      when(mockLoadingManager.currentUiTrace).thenReturn(null);

      LuciqWidgetsBindingObserver.I
          .didChangeAppLifecycleState(AppLifecycleState.resumed);

      verifyNever(mockRenderManager.startScreenRenderCollectorForTraceId(any));
    });

    test('checkForWidgetBinding ensures initialization', () {
      expect(() => checkForWidgetBinding(), returnsNormally);
    });
  });
}
