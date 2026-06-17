import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

enum RyvoButtonIntent { cta, signIn, outline }

class RyvoButton extends StatelessWidget {
  const RyvoButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.intent = RyvoButtonIntent.cta,
    this.size = ShadButtonSize.regular,
    this.fullWidth = false,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final RyvoButtonIntent intent;
  final ShadButtonSize size;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final button = switch (intent) {
      RyvoButtonIntent.outline => ShadButton.outline(onPressed: onPressed, size: size, child: child),
      RyvoButtonIntent.signIn || RyvoButtonIntent.cta =>
        ShadButton(onPressed: onPressed, size: size, child: child),
    };

    if (!fullWidth) return button;
    return SizedBox(width: double.infinity, child: button);
  }
}
