import 'package:flutter/material.dart';
import 'package:luciq_flutter/src/utils/private_views/private_views_manager.dart';

class LuciqPrivateView extends StatefulWidget {
  final Widget child;

  const LuciqPrivateView({required this.child, Key? key}) : super(key: key);

  @override
  State<LuciqPrivateView> createState() => _LuciqPrivateViewState();
}

class _LuciqPrivateViewState extends State<LuciqPrivateView> {
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
    return widget.child;
  }
}
