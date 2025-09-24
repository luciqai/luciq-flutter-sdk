import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class LuciqSliverPrivateView extends StatelessWidget {
  final Widget sliver;

  const LuciqSliverPrivateView({required this.sliver, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return sliver;
  }
}
