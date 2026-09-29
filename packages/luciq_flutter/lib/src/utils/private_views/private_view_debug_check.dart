import 'package:flutter/widgets.dart';
import 'package:luciq_flutter/src/constants/debug_tags.dart';
import 'package:luciq_flutter/src/utils/luciq_widget.dart';

bool _hasWarned = false;

/// Resets the one-time warning so tests can trigger it again.
@visibleForTesting
void debugResetPrivateViewSetupWarning() {
  _hasWarned = false;
}

/// Warns once, in debug builds only, when a private view is built somewhere
/// it can't be masked.
///
/// Private views are only located (and masked) under the [LuciqWidget]
/// subtree, and only when [LuciqWidget.enablePrivateViews] is true. Outside
/// of it, [widgetName] is captured unmasked in screenshots and Session Replay.
///
/// Runs inside an `assert`, so it compiles out of profile and release builds.
void debugCheckPrivateViewSetup(BuildContext context, String widgetName) {
  assert(() {
    if (_hasWarned) return true;

    final luciqWidget = context.findAncestorWidgetOfExactType<LuciqWidget>();
    final String? problem;
    if (luciqWidget == null) {
      problem = 'no LuciqWidget ancestor was found';
    } else if (!luciqWidget.enablePrivateViews) {
      problem = 'LuciqWidget.enablePrivateViews is false';
    } else {
      problem = null;
    }

    if (problem != null) {
      _hasWarned = true;
      debugPrint(
        '${DebugTags.privateView} WARNING: $widgetName will NOT be masked '
        'because $problem. Its content will be visible in screenshots and '
        'Session Replay. Wrap your app root (e.g. MaterialApp) in '
        'LuciqWidget(enablePrivateViews: true, child: ...). '
        'This warning is shown once and only in debug builds.',
      );
    }
    return true;
  }());
}
