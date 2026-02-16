import 'dart:async';

import 'package:flutter/material.dart';
import 'package:luciq_flutter/luciq_flutter.dart';
import 'package:luciq_flutter/src/models/luciq_route.dart';
import 'package:luciq_flutter/src/utils/luciq_logger.dart';
import 'package:luciq_flutter/src/utils/repro_steps_constants.dart';
import 'package:luciq_flutter/src/utils/screen_name_masker.dart';
import 'package:luciq_flutter/src/utils/screen_rendering/luciq_screen_render_manager.dart';
import 'package:luciq_flutter/src/utils/ui_trace/flags_config.dart';

class LuciqNavigatorObserver extends NavigatorObserver {
  LuciqNavigatorObserver({Duration? screenReportDelay})
      : _screenReportDelay =
            screenReportDelay ?? const Duration(milliseconds: 100);

  final Duration _screenReportDelay;
  final List<LuciqRoute> _steps = [];

  void screenChanged(Route newRoute) {
    try {
      final rawScreenName = newRoute.settings.name.toString().trim();
      final screenName = rawScreenName.isEmpty
          ? ReproStepsConstants.emptyScreenFallback
          : rawScreenName;
      final maskedScreenName = ScreenNameMasker.I.mask(screenName);

      final route = LuciqRoute(
        route: newRoute,
        name: maskedScreenName,
      );

      //Ends the last screen rendering collector if exists.
      LuciqScreenRenderManager.I.endScreenRenderCollector();

      // Synchronously prepares the UI trace so the widget can find it immediately.
      ScreenLoadingManager.I.prepareUiTrace(maskedScreenName, screenName);

      // Start screen render collector after UI trace validation completes.
      final uiTrace = ScreenLoadingManager.I.currentUiTrace;
      uiTrace?.whenValidated.then((isValid) {
        if (isValid) {
          _startScreenRenderCollector(uiTrace.traceId);
        }
      });


      //ignore: invalid_null_aware_operator
      WidgetsBinding.instance?.addPostFrameCallback((_) async {
        try {
          // If there is a step that hasn't been pushed yet
          final pendingStep = _steps.isNotEmpty ? _steps.last : null;
          if (pendingStep != null) {
            await reportScreenChange(pendingStep.name);
            // Remove the specific pending step regardless of current ordering
            _steps.remove(pendingStep);
          }

          // Add the new step to the list
          _steps.add(route);

          // If this route is in the array, report it and remove it from the list
          if (_steps.contains(route)) {
            await reportScreenChange(route.name);
            _steps.remove(route);
          }
        } catch (e) {
          LuciqLogger.I.e('Reporting screen change failed:', tag: Luciq.tag);
          LuciqLogger.I.e(e.toString(), tag: Luciq.tag);
        }
      });
    } catch (e) {
      LuciqLogger.I.e('Reporting screen change failed:', tag: Luciq.tag);
      LuciqLogger.I.e(e.toString(), tag: Luciq.tag);
    }
  }

  Future<void> reportScreenChange(String name) async {
    // Wait for the animation to complete
    await Future.delayed(_screenReportDelay);

    Luciq.reportScreenChange(name);
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    if (previousRoute != null) {
      screenChanged(previousRoute);
    }
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    screenChanged(route);
  }

  FutureOr<void> _startScreenRenderCollector(int? uiTraceId) async {
    if (uiTraceId == null) return;
    final isScreenRenderEnabled = await FlagsConfig.screenRendering.isEnabled();
    await LuciqScreenRenderManager.I
        .checkForScreenRenderInitialization(isScreenRenderEnabled);
    if (isScreenRenderEnabled) {
      LuciqScreenRenderManager.I
          .startScreenRenderCollectorForTraceId(uiTraceId);
    }
  }
}
