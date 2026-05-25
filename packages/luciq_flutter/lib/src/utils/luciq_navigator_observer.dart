import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:luciq_flutter/luciq_flutter.dart';
import 'package:luciq_flutter/src/models/luciq_route.dart';
import 'package:luciq_flutter/src/utils/luciq_logger.dart';
import 'package:luciq_flutter/src/utils/repro_steps_constants.dart';
import 'package:luciq_flutter/src/utils/screen_name_masker.dart';
import 'package:luciq_flutter/src/utils/screen_rendering/luciq_screen_render_manager.dart';
import 'package:luciq_flutter/src/utils/ui_trace/flags_config.dart';
import 'package:meta/meta.dart';

class LuciqNavigatorObserver extends NavigatorObserver {
  LuciqNavigatorObserver({Duration? screenReportDelay})
      : _screenReportDelay =
            screenReportDelay ?? const Duration(milliseconds: 100) {
    _instances.add(this);
  }

  static final Set<LuciqNavigatorObserver> _instances =
      <LuciqNavigatorObserver>{};

  final Duration _screenReportDelay;
  final List<LuciqRoute> _steps = [];
  final List<Route<dynamic>> _routeStack = <Route<dynamic>>[];

  /// Returns whether [route] is currently visible, accounting for non-opaque
  /// overlays (dialogs, bottom sheets, popups) that leave the route below
  /// visible.
  ///
  /// Returns `null` when no live observer has seen the route — callers should
  /// fall back to their own check in that case.
  @internal
  static bool? isRouteVisible(Route<dynamic> route) {
    if (_instances.isEmpty) return null;
    for (final observer in _instances) {
      final index = observer._routeStack.indexOf(route);
      if (index < 0) continue;
      for (var i = index + 1; i < observer._routeStack.length; i++) {
        final above = observer._routeStack[i];
        if (above is ModalRoute && above.opaque) {
          return false;
        }
      }
      return true;
    }
    return null;
  }

  @visibleForTesting
  static void debugResetInstances() {
    _instances.clear();
  }

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
            LuciqLogger.I.e('Reporting screen change failed:', tag: Luciq.tag);
            LuciqLogger.I.e(e.toString(), tag: Luciq.tag);
          }
        },
        Priority.idle,
      );
    } catch (e) {
      LuciqLogger.I.e('Screen change handling failed:', tag: Luciq.tag);
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
    _routeStack.remove(route);
    if (previousRoute != null) {
      screenChanged(previousRoute);
    }
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    _routeStack.add(route);
    screenChanged(route);
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    _routeStack.remove(route);
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    if (oldRoute == null) {
      if (newRoute != null) _routeStack.add(newRoute);
      return;
    }
    final index = _routeStack.indexOf(oldRoute);
    if (index < 0) {
      if (newRoute != null) _routeStack.add(newRoute);
      return;
    }
    if (newRoute == null) {
      _routeStack.removeAt(index);
    } else {
      _routeStack[index] = newRoute;
    }
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
