import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:luciq_flutter/luciq_flutter.dart';
import 'package:luciq_flutter/src/constants/debug_tags.dart';
import 'package:luciq_flutter/src/utils/luciq_logger.dart';

class LuciqSliverPrivateView extends StatelessWidget {
  final Widget sliver;

  const LuciqSliverPrivateView({required this.sliver, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (LuciqLogger.I.isVerboseEnabled()) {
      LuciqLogger.I.kv(
        'private_view.build',
        tag: DebugTags.privateView,
        level: LogLevel.verbose,
        fields: {'kind': 'sliver'},
      );
    }
    return sliver;
  }
}
