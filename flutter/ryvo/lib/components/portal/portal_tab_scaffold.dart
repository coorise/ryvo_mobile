import 'package:flutter/material.dart';

class PortalTabScaffold extends StatelessWidget {
  const PortalTabScaffold({
    super.key,
    required this.tabs,
    required this.children,
    this.initialIndex = 0,
  });

  final List<String> tabs;
  final List<Widget> children;
  final int initialIndex;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: tabs.length,
      initialIndex: initialIndex,
      child: Column(
        children: [
          TabBar(
            isScrollable: tabs.length > 3,
            tabs: [for (final tab in tabs) Tab(text: tab)],
          ),
          Expanded(
            child: TabBarView(
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}
