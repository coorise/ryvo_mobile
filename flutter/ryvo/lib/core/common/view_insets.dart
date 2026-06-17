import 'package:flutter/material.dart';

class ViewInsets {
  ViewInsets._();

  static double topOf(BuildContext context) => MediaQuery.paddingOf(context).top;

  static double bottomOf(BuildContext context) => MediaQuery.paddingOf(context).bottom;

  static const toolbarHeight = 72.0;

  static double appBarTotalHeight(BuildContext context) => toolbarHeight + topOf(context);
}

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
