import 'package:flutter/material.dart';

class PortalTabItem {
  const PortalTabItem({
    required this.id,
    required this.label,
    required this.child,
    this.visible = true,
  });

  final String id;
  final String label;
  final Widget child;
  final bool visible;
}

class PortalTabScaffold extends StatefulWidget {
  const PortalTabScaffold({
    super.key,
    required this.tabs,
    this.selectedTabId,
    this.initialTabId,
  });

  final List<PortalTabItem> tabs;
  final String? selectedTabId;
  final String? initialTabId;

  @override
  State<PortalTabScaffold> createState() => _PortalTabScaffoldState();
}

class _PortalTabScaffoldState extends State<PortalTabScaffold> with TickerProviderStateMixin {
  TabController? _controller;
  List<PortalTabItem> _visibleTabs = const [];
  String? _currentTabId;
  String? _lastAppliedSelectedTabId;

  @override
  void initState() {
    super.initState();
    _syncTabs(forceInitial: true);
  }

  @override
  void didUpdateWidget(covariant PortalTabScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tabs != widget.tabs || oldWidget.selectedTabId != widget.selectedTabId) {
      _syncTabs(previousSelectedTabId: oldWidget.selectedTabId);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _syncTabs({bool forceInitial = false, String? previousSelectedTabId}) {
    final visible = widget.tabs.where((tab) => tab.visible).toList(growable: false);
    if (visible.isEmpty) return;

    final preferredId = widget.selectedTabId ?? widget.initialTabId ?? _currentTabId;
    var nextIndex = 0;
    if (preferredId != null) {
      final idx = visible.indexWhere((tab) => tab.id == preferredId);
      if (idx >= 0) nextIndex = idx;
    }

    final selectedTabChanged =
        widget.selectedTabId != null && widget.selectedTabId != previousSelectedTabId;

    final sameTabs = _sameTabIds(_visibleTabs, visible);
    if (!sameTabs || _controller == null) {
      _controller?.dispose();
      _controller = TabController(length: visible.length, vsync: this, initialIndex: nextIndex);
      _lastAppliedSelectedTabId = widget.selectedTabId;
    } else if (selectedTabChanged && _controller!.index != nextIndex) {
      _controller!.animateTo(nextIndex);
      _lastAppliedSelectedTabId = widget.selectedTabId;
    }

    _visibleTabs = visible;
    _currentTabId = visible[_controller!.index].id;
    setState(() {});
  }

  bool _sameTabIds(List<PortalTabItem> a, List<PortalTabItem> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null || _visibleTabs.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        TabBar(
          controller: controller,
          isScrollable: _visibleTabs.length > 3,
          onTap: (index) => _currentTabId = _visibleTabs[index].id,
          tabs: [for (final tab in _visibleTabs) Tab(text: tab.label)],
        ),
        Expanded(
          child: TabBarView(
            controller: controller,
            children: [for (final tab in _visibleTabs) tab.child],
          ),
        ),
      ],
    );
  }
}

/// Backward-compatible wrapper for simple static tab lists.
class PortalTabScaffoldSimple extends StatelessWidget {
  const PortalTabScaffoldSimple({
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
    final items = <PortalTabItem>[];
    for (var i = 0; i < tabs.length; i++) {
      items.add(
        PortalTabItem(
          id: 'tab-$i',
          label: tabs[i],
          child: children[i],
        ),
      );
    }
    return PortalTabScaffold(
      tabs: items,
      initialTabId: initialIndex < tabs.length ? 'tab-$initialIndex' : null,
    );
  }
}
