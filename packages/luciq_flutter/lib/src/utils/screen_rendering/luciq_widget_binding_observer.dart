import 'package:flutter/widgets.dart';
import 'package:luciq_flutter/src/utils/lcq_build_info.dart';
import 'package:luciq_flutter/src/utils/screen_loading/screen_loading_manager.dart';
import 'package:luciq_flutter/src/utils/screen_name_masker.dart';
import 'package:luciq_flutter/src/utils/screen_rendering/luciq_screen_render_manager.dart';
import 'package:luciq_flutter/src/utils/ui_trace/flags_config.dart';
import 'package:meta/meta.dart';

class LuciqWidgetsBindingObserver extends WidgetsBindingObserver {
  LuciqWidgetsBindingObserver._();

  static final LuciqWidgetsBindingObserver _instance =
      LuciqWidgetsBindingObserver._();

  /// Returns the singleton instance of [LuciqWidgetsBindingObserver].
  static LuciqWidgetsBindingObserver get instance => _instance;

  /// Shorthand for [instance]
  static LuciqWidgetsBindingObserver get I => instance;

  /// Logging tag for debugging purposes.
  static const tag = "LuciqWidgetsBindingObserver";

  /// Disposes all screen render resources.
  static void dispose() {
    //Save the screen rendering data for the active traces Auto|Custom.
    LuciqScreenRenderManager.I.stopScreenRenderCollector();

    // The dispose method is safe to call multiple times due to state tracking
    LuciqScreenRenderManager.I.dispose();
  }

  void _handleResumedState() {
    final lastUiTrace = ScreenLoadingManager.I.currentUiTrace;

    if (lastUiTrace == null) return;

    final maskedScreenName = ScreenNameMasker.I.mask(lastUiTrace.screenName);

    ScreenLoadingManager.I
        .startUiTrace(maskedScreenName, lastUiTrace.screenName)
        .then((uiTraceId) async {
      if (uiTraceId == null) return;

      final isScreenRenderEnabled =
          await FlagsConfig.screenRendering.isEnabled();

      if (!isScreenRenderEnabled) return;

      await LuciqScreenRenderManager.I
          .checkForScreenRenderInitialization(isScreenRenderEnabled);

      //End any active ScreenRenderCollector before starting a new one (Safe garde condition).
      LuciqScreenRenderManager.I.endScreenRenderCollector();

      //Start new ScreenRenderCollector.
      LuciqScreenRenderManager.I
          .startScreenRenderCollectorForTraceId(uiTraceId);
    });
  }

  void _handlePausedState() {
    // Only handles iOS platform because in android we use pigeon @FlutterApi().
    // To overcome the onActivityDestroy() before sending the data to the android side.
    if (LuciqScreenRenderManager.I.screenRenderEnabled &&
        LCQBuildInfo.I.isIOS) {
      LuciqScreenRenderManager.I.stopScreenRenderCollector();
    }
  }

  Future<void> _handleDetachedState() async {
    // Only handles iOS platform because in android we use pigeon @FlutterApi().
    // To overcome the onActivityDestroy() before sending the data to the android side.
    if (LuciqScreenRenderManager.I.screenRenderEnabled &&
        LCQBuildInfo.I.isIOS) {
      dispose();
    }
  }

  void _handleDefaultState() {
    // Added for lint warnings
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _handleResumedState();
        break;
      case AppLifecycleState.paused:
        _handlePausedState();
        break;
      case AppLifecycleState.detached:
        _handleDetachedState();
        break;
      default:
        _handleDefaultState();
    }
  }
}

@internal
void checkForWidgetBinding() {
  try {
    WidgetsBinding.instance;
  } catch (_) {
    WidgetsFlutterBinding.ensureInitialized();
  }
}
