import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:luciq_flutter/luciq_flutter.dart';
import 'package:luciq_flutter/src/utils/user_steps/user_step_details.dart';
import 'package:luciq_flutter/src/utils/user_steps/widget_utils.dart';

Element? _clickTrackerElement;

class LuciqUserSteps extends StatefulWidget {
  final Widget child;

  const LuciqUserSteps({Key? key, required this.child}) : super(key: key);

  @override
  LuciqUserStepsState createState() => LuciqUserStepsState();

  @override
  StatefulElement createElement() {
    final element = super.createElement();
    _clickTrackerElement = element;
    return element;
  }
}

class LuciqUserStepsState extends State<LuciqUserSteps> {
  static const double _doubleTapThreshold = 300.0; // milliseconds
  static const double _pinchSensitivity = 20.0;
  static const double _swipeSensitivity = 50.0;
  static const double _scrollSensitivity = 50.0;
  static const double _tapSensitivity = 20 * 20;

  Timer? _longPressTimer;
  Offset? _pointerDownLocation;
  GestureType? _gestureType;
  String? _gestureMetaData;
  DateTime? _lastTapTime;
  double _pinchDistance = 0.0;
  int _pointerCount = 0;
  double? _previousOffset;

  // NEW: Pre-classification rage tap tracking
  final Map<Element, _TapCluster> _tapClusters = {};
  static const int _rageTapMinCount = 3;
  static const double _rageTapTimeWindowMs = 1000;
  static const double _rageTapDistanceThreshold = 20;
  static const double _rageTapCooldownMs = 5000;

  void _onPointerDown(PointerDownEvent event) {
    _resetGestureTracking();
    _pointerDownLocation = event.localPosition;
    _pointerCount += event.buttons;
    _longPressTimer = Timer(const Duration(milliseconds: 500), () {
      _gestureType = GestureType.longPress;
    });
  }

  void _onPointerUp(PointerUpEvent event, BuildContext context) {
    _longPressTimer?.cancel();

    // NEW: Check for rage tap BEFORE gesture classification
    final delta = event.localPosition - (_pointerDownLocation ?? Offset.zero);
    if (_isTap(delta)) {
      // Only process tap-like gestures
      final tappedWidget =
          _getWidgetDetails(event.localPosition, context, GestureType.tap);

      if (tappedWidget != null &&
          tappedWidget.element != null &&
          !tappedWidget.isPrivate) {
        // Process potential rage tap
        final rageTapResult = _processRageTapDetection(
          tappedWidget.element!,
          event.localPosition,
          tappedWidget,
        );

        // Always skip normal processing when tap is being tracked
        if (rageTapResult == _RageTapResult.suppressed) {
          _pointerCount = 0;
          _resetGestureTracking(); // Important: reset gesture state
          return;
        }
      }
    }

    // Continue with normal gesture detection only if not a rage tap
    final gestureType = _detectGestureType(event.localPosition);
    if (_gestureType != GestureType.longPress) {
      _gestureType = gestureType;
    }

    _pointerCount = 0;

    if (_gestureType == null) {
      return;
    }
    final tappedWidget =
        _getWidgetDetails(event.localPosition, context, _gestureType!);
    if (tappedWidget != null) {
      final userStepDetails = tappedWidget.copyWith(
        gestureType: _gestureType,
        gestureMetaData: _gestureMetaData,
      );
      if (userStepDetails.gestureType == null ||
          userStepDetails.message == null) {
        return;
      }

      Luciq.logUserSteps(
        userStepDetails.gestureType!,
        userStepDetails.message!,
        userStepDetails.widgetName,
      );
    }
  }

  GestureType? _detectGestureType(Offset upLocation) {
    final delta = upLocation - (_pointerDownLocation ?? Offset.zero);

    if (_pointerCount == 1) {
      if (_isTap(delta)) return _detectTapType();
      if (_isSwipe(delta)) return GestureType.swipe;
    } else if (_pointerCount == 2 && _isPinch()) {
      return GestureType.pinch;
    }

    return null;
  }

  bool _isTap(Offset delta) => delta.distanceSquared < _tapSensitivity;

  GestureType? _detectTapType() {
    final now = DateTime.now();
    final isDoubleTap = _lastTapTime != null &&
        now.difference(_lastTapTime!).inMilliseconds <= _doubleTapThreshold;

    _lastTapTime = now;
    return isDoubleTap ? GestureType.doubleTap : GestureType.tap;
  }

  bool _isSwipe(Offset delta) {
    final isHorizontal = delta.dx.abs() > delta.dy.abs();

    if (isHorizontal && delta.dx.abs() > _swipeSensitivity) {
      _gestureMetaData = delta.dx > 0 ? "Right" : "Left";
      return true;
    }

    if (!isHorizontal && delta.dy.abs() > _swipeSensitivity) {
      _gestureMetaData = delta.dy > 0 ? "Down" : "Up";
      return true;
    }

    return false;
  }

  bool _isPinch() => _pinchDistance.abs() > _pinchSensitivity;

  void _resetGestureTracking() {
    _gestureType = null;
    _gestureMetaData = null;
    _longPressTimer?.cancel();
  }

  UserStepDetails? _getWidgetDetails(
    Offset location,
    BuildContext context,
    GestureType gestureType,
  ) {
    Element? tappedElement;
    var isPrivate = false;

    final rootElement = _clickTrackerElement;
    if (rootElement == null || rootElement.widget != widget) return null;

    final hitTestResult = BoxHitTestResult();
    final renderBox = context.findRenderObject()! as RenderBox;

    renderBox.hitTest(hitTestResult, position: _pointerDownLocation!);

    final targets = hitTestResult.path
        .where((e) => e.target is RenderBox)
        .map((e) => e.target)
        .toList();

    void visitor(Element visitedElement) {
      final renderObject = visitedElement.renderObject;
      if (renderObject == null) return;

      if (targets.contains(renderObject)) {
        final transform = renderObject.getTransformTo(rootElement.renderObject);
        final paintBounds =
            MatrixUtils.transformRect(transform, renderObject.paintBounds);

        if (paintBounds.contains(_pointerDownLocation!)) {
          final widget = visitedElement.widget;
          if (!isPrivate) {
            isPrivate = widget.runtimeType.toString() == 'LuciqPrivateView' ||
                widget.runtimeType.toString() == 'LuciqSliverPrivateView';
          }
          if (_isTargetWidget(widget, gestureType)) {
            tappedElement = visitedElement;
            return;
          }
        }
      }
      if (tappedElement == null) {
        visitedElement.visitChildElements(visitor);
      }
    }

    rootElement.visitChildElements(visitor);
    if (tappedElement == null) return null;
    return UserStepDetails(element: tappedElement, isPrivate: isPrivate);
  }

  bool _isTargetWidget(Widget? widget, GestureType type) {
    if (widget == null) return false;
    switch (type) {
      case GestureType.swipe:
        return isSwipedWidget(widget);
      case GestureType.tap:
      case GestureType.longPress:
      case GestureType.doubleTap:
      case GestureType.rageTap:
        return isTappedWidget(widget);
      case GestureType.pinch:
        return isPinchWidget(widget);
      case GestureType.scroll:
        return false;
    }
  }

  void _detectScrollDirection(double currentOffset, Axis direction) {
    if (_previousOffset == null) return;

    final delta = (currentOffset - _previousOffset!).abs();
    if (delta < _scrollSensitivity) return;
    final String swipeDirection;
    if (direction == Axis.horizontal) {
      swipeDirection = currentOffset > _previousOffset! ? "Left" : "Right";
    } else {
      swipeDirection = currentOffset > _previousOffset! ? "Down" : "Up";
    }

    final userStepDetails = UserStepDetails(
      element: null,
      isPrivate: false,
      gestureMetaData: swipeDirection,
      gestureType: GestureType.scroll,
    );

    if (userStepDetails.gestureType == null ||
        userStepDetails.message == null) {
      return;
    }
    Luciq.logUserSteps(
      userStepDetails.gestureType!,
      userStepDetails.message!,
      "ListView",
    );
  }

  // NEW: Process rage tap detection with wait-and-see approach
  _RageTapResult _processRageTapDetection(
    Element element,
    Offset localPosition,
    UserStepDetails tappedWidget,
  ) {
    // Get or create tap cluster for this element
    final cluster = _tapClusters.putIfAbsent(
      element,
      () => _TapCluster(element, _onTapClusterDecision),
    );

    // Skip if in cooldown
    if (cluster.isInCooldown()) {
      return _RageTapResult.notDetected;
    }

    // Check if tap is within distance threshold
    if (!cluster.isWithinDistanceThreshold(localPosition)) {
      cluster.reset();
    }

    // Add current tap with buffered data
    cluster.addTap(localPosition, tappedWidget);

    // Always suppress individual tap emission while collecting
    // The decision timer will handle emission later
    return _RageTapResult.suppressed;
  }

  // NEW: Callback when tap cluster makes a decision
  void _onTapClusterDecision(bool isRageTap, _TapCluster cluster) {
    if (isRageTap) {
      // Emit single consolidated rage tap with full count
      final firstTapData = cluster.bufferedTapData.first;
      final userStepDetails = firstTapData.tapDetails.copyWith(
        gestureType: GestureType.rageTap,
        tapCount: cluster.taps.length, // Use full count
      );

      Luciq.logUserSteps(
        userStepDetails.gestureType!,
        userStepDetails.message!,
        userStepDetails.widgetName,
      );
    } else {
      // Replay buffered taps as normal tap/double-tap events
      _replayBufferedTaps(cluster.bufferedTapData);
    }
  }

  // NEW: Replay buffered taps when not a rage tap
  void _replayBufferedTaps(List<_BufferedTapData> bufferedTaps) {
    if (bufferedTaps.isEmpty) return;

    // Determine if it's a double-tap or individual taps
    if (bufferedTaps.length == 2) {
      final timeDiff = bufferedTaps[1]
          .timestamp
          .difference(bufferedTaps[0].timestamp)
          .inMilliseconds;

      if (timeDiff <= _doubleTapThreshold) {
        // Emit as double-tap
        final tapData = bufferedTaps.last;
        final userStepDetails = tapData.tapDetails.copyWith(
          gestureType: GestureType.doubleTap,
        );

        Luciq.logUserSteps(
          userStepDetails.gestureType!,
          userStepDetails.message!,
          userStepDetails.widgetName,
        );
        return;
      }
    }

    // Emit as individual tap events
    for (final tapData in bufferedTaps) {
      final userStepDetails = tapData.tapDetails.copyWith(
        gestureType: GestureType.tap,
      );

      Luciq.logUserSteps(
        userStepDetails.gestureType!,
        userStepDetails.message!,
        userStepDetails.widgetName,
      );
    }
  }

  @override
  void dispose() {
    _longPressTimer?.cancel();

    // Clean up all tap clusters and their timers
    for (final cluster in _tapClusters.values) {
      cluster.dispose();
    }
    _tapClusters.clear();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onPointerDown,
      onPointerMove: (event) {
        if (_pointerCount == 2) {
          _pinchDistance =
              (event.localPosition - (_pointerDownLocation ?? Offset.zero))
                  .distance;
        }
      },
      onPointerUp: (event) => _onPointerUp(event, context),
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollStartNotification) {
            _previousOffset = notification.metrics.pixels;
          } else if (notification is ScrollEndNotification) {
            _detectScrollDirection(
              notification.metrics.pixels, // Vertical position
              notification.metrics.axis,
            );
          }

          return true;
        },
        child: widget.child,
      ),
    );
  }
}

// NEW: Rage tap detection result enum
enum _RageTapResult {
  notDetected, // Not a rage tap, proceed with normal tap
  suppressed, // Part of rage tap tracking, suppress individual tap
  detected, // Rage tap detected and logged
}

// Helper class for tracking tap clusters with buffering
class _TapCluster {
  final List<_TapEvent> taps = [];
  final List<_BufferedTapData> bufferedTapData = [];
  DateTime? cooldownEndTime;
  final Element element;
  Timer? _decisionTimer;
  final Function(bool isRageTap, _TapCluster cluster) _onDecisionMade;

  static const int _decisionDelayMs = 300; // Time to wait for more taps

  _TapCluster(this.element, this._onDecisionMade);

  void addTap(Offset localPosition, UserStepDetails tapDetails) {
    final now = DateTime.now();

    // Remove old taps outside time window
    taps.removeWhere(
      (tap) =>
          now.difference(tap.timestamp).inMilliseconds >
          LuciqUserStepsState._rageTapTimeWindowMs,
    );

    // Also clean up old buffered data
    bufferedTapData.removeWhere(
      (data) =>
          now.difference(data.timestamp).inMilliseconds >
          LuciqUserStepsState._rageTapTimeWindowMs,
    );

    // Add new tap
    taps.add(_TapEvent(localPosition, now));

    // Buffer tap data for potential replay
    bufferedTapData.add(
      _BufferedTapData(
        localPosition: localPosition,
        tapDetails: tapDetails,
        timestamp: now,
      ),
    );

    // Cancel existing timer and start a new one
    _decisionTimer?.cancel();
    _decisionTimer = Timer(const Duration(milliseconds: _decisionDelayMs), () {
      _makeDecision();
    });
  }

  void _makeDecision() {
    // Decision time: rage tap or normal taps?
    final isRageTap = taps.length >= LuciqUserStepsState._rageTapMinCount;
    _onDecisionMade(isRageTap, this);

    if (isRageTap) {
      // Start cooldown after rage tap
      startCooldown();
    }

    // Clear buffers after decision
    reset();
  }

  bool isInCooldown() {
    if (cooldownEndTime == null) return false;
    return DateTime.now().isBefore(cooldownEndTime!);
  }

  void startCooldown() {
    cooldownEndTime = DateTime.now().add(
      Duration(milliseconds: LuciqUserStepsState._rageTapCooldownMs.toInt()),
    );
  }

  bool isWithinDistanceThreshold(Offset newPosition) {
    if (taps.isEmpty) return true;
    for (final tap in taps) {
      if ((tap.position - newPosition).distance >
          LuciqUserStepsState._rageTapDistanceThreshold) {
        return false;
      }
    }
    return true;
  }

  void reset() {
    taps.clear();
    bufferedTapData.clear();
    _decisionTimer?.cancel();
    _decisionTimer = null;
  }

  void dispose() {
    _decisionTimer?.cancel();
    _decisionTimer = null;
  }
}

class _TapEvent {
  final Offset position;
  final DateTime timestamp;
  _TapEvent(this.position, this.timestamp);
}

// Class to buffer tap data for potential replay
class _BufferedTapData {
  final Offset localPosition;
  final UserStepDetails tapDetails;
  final DateTime timestamp;

  _BufferedTapData({
    required this.localPosition,
    required this.tapDetails,
    required this.timestamp,
  });
}
