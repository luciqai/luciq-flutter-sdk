import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:luciq_flutter/luciq_flutter.dart';
import 'package:luciq_flutter/src/generated/luciq.api.g.dart';
import 'package:luciq_flutter/src/generated/luciq_private_view.api.g.dart';
import 'package:luciq_flutter/src/utils/enum_converter.dart';
import 'package:luciq_flutter/src/utils/user_steps/widget_utils.dart';
import 'package:meta/meta.dart';

enum AutoMasking { labels, textInputs, media, none }

extension ValidationMethod on AutoMasking {
  bool Function(Widget) hides() {
    switch (this) {
      case AutoMasking.labels:
        return isTextWidget;
      case AutoMasking.textInputs:
        return isTextInputWidget;
      case AutoMasking.media:
        return isMedia;
      case AutoMasking.none:
        return (_) => false;
    }
  }
}

/// responsible for masking views
/// before they are sent to the native SDKs.
class PrivateViewsManager implements LuciqPrivateViewFlutterApi {
  PrivateViewsManager._() {
    _viewChecks = List.of([isPrivateWidget]);
  }

  static PrivateViewsManager _instance = PrivateViewsManager._();

  static PrivateViewsManager get instance => _instance;
  static final _host = LuciqHostApi();

  /// Shorthand for [instance]
  static PrivateViewsManager get I => instance;

  @visibleForTesting
  // ignore: use_setters_to_change_properties
  static void setInstance(PrivateViewsManager instance) {
    _instance = instance;
  }

  static bool isPrivateWidget(Widget widget) {
    final isPrivate = (widget.runtimeType == LuciqPrivateView) ||
        (widget.runtimeType == LuciqSliverPrivateView);

    return isPrivate;
  }

  late List<bool Function(Widget)> _viewChecks;
  bool _autoMaskingEnabled = false;

  // Registry of mounted LuciqPrivateView / LuciqSliverPrivateView elements.
  // Lets us skip the full widget-tree walk when auto-masking is off.
  final Set<Element> _registeredPrivateElements = <Element>{};

  @internal
  void registerPrivateElement(Element element) {
    _registeredPrivateElements.add(element);
  }

  @internal
  void unregisterPrivateElement(Element element) {
    _registeredPrivateElements.remove(element);
  }

  void addAutoMasking(List<AutoMasking> masking) {
    _viewChecks = List.of([isPrivateWidget]);
    final hasMasking =
        !(masking.contains(AutoMasking.none) && masking.length == 1) &&
            masking.isNotEmpty;
    if (hasMasking) {
      _viewChecks.addAll(masking.map((e) => e.hides()).toList());
    }
    _autoMaskingEnabled = hasMasking;
    _host.enableAutoMasking(masking.mapToString());
  }

  Rect? getLayoutRectInfoFromRenderObject(RenderObject? renderObject) {
    if (renderObject == null || !renderObject.attached) {
      return null;
    }

    final globalOffset = _getRenderGlobalOffset(renderObject);

    // Case 1: RenderBox (e.g. Container, Text, etc.)
    if (renderObject is RenderBox) {
      return renderObject.paintBounds.shift(globalOffset);
    }

    // Case 2: RenderSliver (e.g. SliverList, SliverToBoxAdapter, etc.)
    if (renderObject is RenderSliver) {
      final geometry = renderObject.geometry;
      if (geometry == null) {
        return null;
      }

      final crossAxisExtent = renderObject.constraints.crossAxisExtent;
      final paintExtent = geometry.paintExtent;

      return Rect.fromLTWH(
        globalOffset.dx,
        globalOffset.dy,
        // assume vertical scroll by default
        crossAxisExtent,
        paintExtent,
      );
    }

    return null;
  }

  // The is the same implementation used in RenderBox.localToGlobal (a subclass of RenderObject)
  Offset _getRenderGlobalOffset(RenderObject renderObject) {
    // Find the nearest RenderBox ancestor to calculate global position
    RenderObject? current = renderObject;
    while (current != null && current is! RenderBox) {
      final parentNode = current.parent;
      if (parentNode is RenderObject) {
        current = parentNode;
      } else {
        current = null;
      }
    }

    if (current is RenderBox) {
      // Get transform from this object to screen root
      final transform = renderObject.getTransformTo(null);
      return MatrixUtils.transformPoint(transform, Offset.zero);
    }

    // fallback: treat as zero offset (shouldn't happen if widget is mounted in tree)
    return Offset.zero;
  }

  List<Rect> getRectsOfPrivateViews() {
    final context = luciqWidgetKey.currentContext;
    if (context == null) return [];

    final rootRenderObject =
        context.findRenderObject() as RenderRepaintBoundary?;
    if (rootRenderObject is! RenderBox) return [];

    final bounds = Offset.zero & rootRenderObject!.size;

    final rects = <Rect>[];

    // Fast path: when auto-masking is off, only the explicitly-mounted
    // LuciqPrivateView / LuciqSliverPrivateView elements can mask. Iterate
    // the registry instead of walking the entire widget tree on every call.
    if (!_autoMaskingEnabled) {
      for (final element in _registeredPrivateElements) {
        // owner is cleared when the element is unmounted; portable
        // equivalent of `element.mounted` (which only exists from
        // Flutter 3.7+, but the package supports older versions).
        if (element.owner == null) continue;
        final renderObject = element.findRenderObject();
        if ((renderObject is RenderBox || renderObject is RenderSliver) &&
            renderObject?.attached == true) {
          final rect = getLayoutRectInfoFromRenderObject(renderObject);
          if (rect != null &&
              rect.overlaps(bounds) &&
              isElementInCurrentRoute(element)) {
            rects.add(rect);
          }
        }
      }
      return rects;
    }

    void findPrivateViews(Element element) {
      final widget = element.widget;
      final isPrivate = _viewChecks.any((e) => e.call(widget));
      if (isPrivate) {
        final renderObject = element.findRenderObject();
        if ((renderObject is RenderBox || renderObject is RenderSliver) &&
            renderObject?.attached == true) {
          final isElementInCurrentScreen = isElementInCurrentRoute(element);
          final rect = getLayoutRectInfoFromRenderObject(renderObject);
          if (rect != null &&
              rect.overlaps(bounds) &&
              isElementInCurrentScreen) {
            rects.add(rect);
          }
        }
      } else {
        element.visitChildElements(findPrivateViews);
      }
    }

    context.visitChildElements(findPrivateViews);

    return rects;
  }

  bool isElementInCurrentRoute(Element element) {
    final modalRoute = ModalRoute.of(element);
    // root tree below MaterialApp
    if (modalRoute == null) return true;
    if (modalRoute.isCurrent) return true;
    if (!modalRoute.isActive) return false;
    // Not current, but still active — only visible if the observer confirms
    // that nothing opaque sits above this route. This preserves the original
    // guarantee that page A's rects do not leak onto page B after an opaque
    // MaterialPageRoute push, while still masking the background behind
    // non-opaque overlays (dialogs, bottom sheets, popups).
    return LuciqNavigatorObserver.isRouteVisible(modalRoute) == true;
  }

  @override
  List<double?> getPrivateViews() {
    final rects = getRectsOfPrivateViews();
    final result = <double>[];

    for (final rect in rects) {
      result.addAll([
        rect.left,
        rect.top,
        rect.right,
        rect.bottom,
      ]);
    }

    return result;
  }
}
