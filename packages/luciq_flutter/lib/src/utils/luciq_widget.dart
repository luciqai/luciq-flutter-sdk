import 'package:flutter/material.dart';
import 'package:luciq_flutter/luciq_flutter.dart';
import 'package:luciq_flutter/src/generated/luciq_private_view.api.g.dart';
import 'package:luciq_flutter/src/utils/private_views/private_views_manager.dart';
import 'package:meta/meta.dart';

@internal
final luciqWidgetKey = GlobalKey(debugLabel: 'luciq_screenshot_widget');

class LuciqWidget extends StatefulWidget {
  final Widget child;
  final bool enablePrivateViews;
  final bool enableUserSteps;
  final List<AutoMasking>? automasking;

  const LuciqWidget({
    Key? key,
    required this.child,
    this.enableUserSteps = true,
    this.enablePrivateViews = true,
    this.automasking,
  }) : super(key: key);

  @override
  State<LuciqWidget> createState() => _LuciqWidgetState();
}

class _LuciqWidgetState extends State<LuciqWidget> {
  @override
  void initState() {
    if (widget.enablePrivateViews) {
      _enableLuciqMaskingPrivateViews();
    }
    if (widget.automasking != null) {
      PrivateViewsManager.I.addAutoMasking(widget.automasking!);
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.enableUserSteps
        ? LuciqUserSteps(child: widget.child)
        : widget.child;

    if (widget.enablePrivateViews) {
      return RepaintBoundary(
        key: luciqWidgetKey,
        child: child,
      );
    }
    return child;
  }
}

void _enableLuciqMaskingPrivateViews() {
  final api = LuciqPrivateViewHostApi();
  api.init();
  LuciqPrivateViewFlutterApi.setup(PrivateViewsManager.I);
}
