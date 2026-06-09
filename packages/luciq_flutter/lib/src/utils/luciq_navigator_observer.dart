import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:luciq_flutter/luciq_flutter.dart';
import 'package:luciq_flutter/src/constants/debug_tags.dart';
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
    LuciqLogger.I.d(
      '[SCREEN.screenChanged] phase=enter screenNameLength=${newRoute.settings.name?.length ?? 0}',
      tag: DebugTags.screenTracking,
    );
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

      // Must run synchronously — the new route's widget tree mounts on the
      // very next frame and its initState calls startScreenLoadingTrace,
      // which needs currentUiTrace to already reflect the new screen.
      LuciqScreenRenderManager.I.endScreenRenderCollector();
      ScreenLoadingManager.I.prepareUiTrace(maskedScreenName, screenName);

      final uiTrace = ScreenLoadingManager.I.currentUiTrace;
      uiTrace?.whenValidated.then((isValid) {
        if (isValid) {
          _startScreenRenderCollector(uiTrace.traceId);
        }
      });

      // Repro-steps reporting has its own animation delay, so defer it to
      // avoid blocking the navigation frame.
      //// ignore: invalid_null_aware_operator
      SchedulerBinding.instance?.scheduleTask(
        () async {
          try {
            final pendingStep = _steps.isNotEmpty ? _steps.last : null;
            if (pendingStep != null) {
              await reportScreenChange(pendingStep.name);
              _steps.remove(pendingStep);
            }

            _steps.add(route);

            if (_steps.contains(route)) {
              await reportScreenChange(route.name);
              _steps.remove(route);
            }
          } catch (e) {
            // Sub-labelled to keep it from looking like a terminal failure on
            // the outer [SCREEN.screenChanged] call, which already logged
            // phase=exit by the time this deferred task runs.
            LuciqLogger.I.e(
              '[SCREEN.screenChanged.deferred] phase=error errorType=${e.runtimeType}',
              tag: DebugTags.screenTracking,
            );
          }
        },
        Priority.idle,
      );
      LuciqLogger.I.d(
        '[SCREEN.screenChanged] phase=exit',
        tag: DebugTags.screenTracking,
      );
    } catch (e) {
      LuciqLogger.I.e(
        '[SCREEN.screenChanged] phase=error errorType=${e.runtimeType}',
        tag: DebugTags.screenTracking,
      );
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
