import 'package:flutter_modular/flutter_modular.dart';
import 'package:luciq_flutter/luciq_flutter.dart';
import 'package:luciq_flutter_modular/src/luciq_module.dart';
import 'package:meta/meta.dart';

class LuciqModularManager {
  LuciqModularManager._();

  static LuciqModularManager _instance = LuciqModularManager._();
  static LuciqModularManager get instance => _instance;

  /// Shorthand for [instance]
  static LuciqModularManager get I => instance;

  @visibleForTesting
  // ignore: use_setters_to_change_properties
  static void setInstance(LuciqModularManager instance) {
    _instance = instance;
  }

  List<ModularRoute> wrapRoutes(
    List<ModularRoute> routes, {
    String parent = '/',
    bool wrapModules = true,
  }) {
    return routes
        .map(
          (route) => wrapRoute(
            route,
            parent: parent,
            wrapModules: wrapModules,
          ),
        )
        .toList();
  }

  ModularRoute wrapRoute(
    ModularRoute route, {
    String parent = '/',
    bool wrapModules = true,
  }) {
    final fullPath = (parent + route.name).replaceFirst('//', '/');

    if (route is ModuleRoute && route.context is Module && wrapModules) {
      final module = LuciqModule(
        route.context! as Module,
        path: fullPath,
      );

      return route.addModule(
        route.name,
        module: module,
      );
    } else if (route is ParallelRoute && route is! ModuleRoute) {
      ModularChild? child;

      if (route.child != null) {
        child = (context, args) => LuciqCaptureScreenLoading(
              screenName: fullPath,
              child: route.child!(context, args),
            );
      }

      return route.copyWith(
        child: child,
        children: wrapRoutes(
          route.children,
          parent: fullPath,
          wrapModules: wrapModules,
        ),
      );
    }

    return route;
  }
}
