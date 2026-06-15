import 'package:flutter/material.dart';

/// Shared inset helpers — mirrors web safe-area usage for native status/home bars.
class ViewInsets {
  ViewInsets._();

  static double topOf(BuildContext context) => MediaQuery.paddingOf(context).top;

  static double bottomOf(BuildContext context) => MediaQuery.paddingOf(context).bottom;

  /// Standard app bar content height (matches web `h-[72px]`).
  static const toolbarHeight = 72.0;

  static double appBarTotalHeight(BuildContext context) => toolbarHeight + topOf(context);
}

/// Wraps custom top chrome (headers without Scaffold AppBar).
class SafeTop extends StatelessWidget {
  const SafeTop({super.key, required this.child, this.color});

  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: color ?? Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: EdgeInsets.only(top: ViewInsets.topOf(context)),
        child: child,
      ),
    );
  }
}
