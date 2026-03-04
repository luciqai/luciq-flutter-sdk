import 'dart:async';

import 'package:luciq_flutter/src/utils/screen_loading/route_matcher.dart';

class UiTrace {
  final String screenName;

  /// The screen name used while matching the UI trace with a Screen Loading
  /// trace.
  ///
  /// For example, this is set to the original screen name before masking when
  /// screen names masking is enabled.
  final String _matchingScreenName;

  final int traceId;
  bool didStartScreenLoading = false;
  bool didReportScreenLoading = false;
  bool didExtendScreenLoading = false;

  /// Completes with `true` if the UI trace was validated and activated
  /// on the native side, or `false` if it was discarded.
  final Completer<bool> validationCompleter = Completer<bool>();

  /// Awaitable future that resolves when validation finishes.
  Future<bool> get whenValidated => validationCompleter.future;

  UiTrace({
    required this.screenName,
    required this.traceId,
    String? matchingScreenName,
  }) : _matchingScreenName = matchingScreenName ?? screenName;

  UiTrace copyWith({
    String? screenName,
    String? matchingScreenName,
    int? traceId,
  }) {
    return UiTrace(
      screenName: screenName ?? this.screenName,
      matchingScreenName: matchingScreenName ?? _matchingScreenName,
      traceId: traceId ?? this.traceId,
    );
  }

  bool matches(String routePath) {
    return RouteMatcher.I.match(
      routePath: routePath,
      actualPath: _matchingScreenName,
    );
  }

  @override
  String toString() {
    return 'UiTrace{screenName: $screenName, traceId: $traceId, isFirstScreenLoadingReported: $didReportScreenLoading, isFirstScreenLoading: $didStartScreenLoading}';
  }
}
