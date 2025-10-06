import 'dart:async';

import 'package:flutter/material.dart';
import 'package:luciq_flutter/luciq_flutter.dart';
import 'package:luciq_flutter/src/models/luciq_route.dart';
import 'package:luciq_flutter/src/modules/luciq.dart';
import 'package:luciq_flutter/src/utils/luciq_logger.dart';
import 'package:luciq_flutter/src/utils/repro_steps_constants.dart';
import 'package:luciq_flutter/src/utils/screen_loading/flags_config.dart';
import 'package:luciq_flutter/src/utils/screen_loading/screen_loading_manager.dart';
import 'package:luciq_flutter/src/utils/screen_name_masker.dart';
import 'package:luciq_flutter/src/utils/screen_rendering/luciq_screen_render_manager.dart';

class LuciqNavigatorObserver extends NavigatorObserver {
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

      //ignore: invalid_null_aware_operator
      WidgetsBinding.instance?.addPostFrameCallback((_) async {
        //Ends the last screen rendering collector
        LuciqScreenRenderManager.I.endScreenRenderCollector();
        // Starts a the new UI trace which is exclusive to screen loading
        ScreenLoadingManager.I
            .startUiTrace(maskedScreenName, screenName)
            .then(_startScreenRenderCollector);

        // If there is a step that hasn't been pushed yet
        if (_steps.isNotEmpty) {
          await reportScreenChange(_steps.last.name);
          // Report the last step and remove it from the list
          _steps.removeLast();
        }

        // Add the new step to the list
        _steps.add(route);

        // If this route is in the array, report it and remove it from the list
        if (_steps.contains(route)) {
          await reportScreenChange(route.name);
          _steps.remove(route);
        }
      });
    } catch (e) {
      LuciqLogger.I.e('Reporting screen change failed:', tag: Luciq.tag);
      LuciqLogger.I.e(e.toString(), tag: Luciq.tag);
    }
  }

  Future<void> reportScreenChange(String name) async {
    // Wait for the animation to complete
    await Future.delayed(const Duration(milliseconds: 100));

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
