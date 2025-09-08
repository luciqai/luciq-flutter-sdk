import 'package:flutter/material.dart';
import 'package:luciq_flutter_example/src/widget/luciq_text_field.dart';
import 'package:luciq_flutter_example/src/widget/luciq_clipboard_icon_button.dart';

class LuciqClipboardInput extends StatelessWidget {
  const LuciqClipboardInput({
    Key? key,
    required this.label,
    required this.controller,
    this.symanticLabel,
  }) : super(key: key);

  final String label;
  final TextEditingController controller;
  final String? symanticLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: LuciqTextField(
            label: label,
            margin: const EdgeInsetsDirectional.only(
              start: 20.0,
            ),
            controller: controller,
            symanticLabel: symanticLabel,
          ),
        ),
        LuciqClipboardIconButton(
          onPaste: (String? clipboardText) {
            controller.text = clipboardText ?? controller.text;
          },
        ),
      ],
    );
  }
}
