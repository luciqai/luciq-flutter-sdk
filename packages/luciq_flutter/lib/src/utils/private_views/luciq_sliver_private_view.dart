import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:luciq_flutter/src/utils/private_views/private_view_debug_check.dart';

class LuciqSliverPrivateView extends StatelessWidget {
  final Widget sliver;

  const LuciqSliverPrivateView({required this.sliver, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    debugCheckPrivateViewSetup(context, 'LuciqSliverPrivateView');
    return sliver;
  }
}
