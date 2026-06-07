import 'package:flutter/material.dart';
import 'package:luciq_flutter/luciq_flutter.dart';
import 'package:luciq_flutter/src/constants/debug_tags.dart';
import 'package:luciq_flutter/src/utils/luciq_logger.dart';

class LuciqPrivateView extends StatelessWidget {
  final Widget child;

  const LuciqPrivateView({required this.child, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (LuciqLogger.I.isVerboseEnabled()) {
      LuciqLogger.I.kv(
        'private_view.build',
        tag: DebugTags.privateView,
        level: LogLevel.verbose,
        fields: {'kind': 'widget'},
      );
    }
    return child;
  }
}
