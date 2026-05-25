import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:luciq_flutter/src/utils/private_views/private_views_manager.dart';

class LuciqSliverPrivateView extends StatefulWidget {
  final Widget sliver;

  const LuciqSliverPrivateView({required this.sliver, Key? key})
      : super(key: key);

  @override
  State<LuciqSliverPrivateView> createState() => _LuciqSliverPrivateViewState();
}

class _LuciqSliverPrivateViewState extends State<LuciqSliverPrivateView> {
  @override
  void initState() {
    super.initState();
    PrivateViewsManager.I.registerPrivateElement(context as Element);
  }

  @override
  void dispose() {
    PrivateViewsManager.I.unregisterPrivateElement(context as Element);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.sliver;
  }
}
