/// Bulk row selection — mirrors web `useBulkSelection`.
class BulkSelection {
  final Set<String> _selected = {};

  Set<String> get selected => Set.unmodifiable(_selected);
  int get count => _selected.length;

  bool isSelected(String id) => _selected.contains(id);

  void toggle(String id) {
    if (_selected.contains(id)) {
      _selected.remove(id);
    } else {
      _selected.add(id);
    }
  }

  void toggleAll(Iterable<String> ids) {
    final list = ids.toList(growable: false);
    if (list.isEmpty) return;
    if (isAllSelected(list)) {
      _selected.clear();
      return;
    }
    _selected
      ..clear()
      ..addAll(list);
  }

  void clear() => _selected.clear();

  bool isAllSelected(Iterable<String> ids) {
    final list = ids.toList(growable: false);
    return list.isNotEmpty && list.every(_selected.contains);
  }

  bool isSomeSelected(Iterable<String> ids) {
    final list = ids.toList(growable: false);
    return list.any(_selected.contains) && !isAllSelected(list);
  }

  List<T> pick<T>(List<T> items, String Function(T) idOf) =>
      items.where((item) => _selected.contains(idOf(item))).toList(growable: false);
}
