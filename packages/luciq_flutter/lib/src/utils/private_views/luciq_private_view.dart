import 'package:flutter/material.dart';
import 'package:luciq_flutter/src/utils/private_views/private_view_debug_check.dart';

class LuciqPrivateView extends StatelessWidget {
  final Widget child;

  const LuciqPrivateView({required this.child, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    debugCheckPrivateViewSetup(context, 'LuciqPrivateView');
    return child;
  }
}
