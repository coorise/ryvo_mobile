import 'package:flutter_riverpod/flutter_riverpod.dart';

const int listDefaultPageSize = 20;
const int listPageSizeMin = 5;
const int listPageSizeMax = 200;

enum ListLayout { table, grid }

enum ListLoadMode { infinite, pages }

enum SortDir { asc, desc }

class SortState {
  const SortState({required this.key, required this.dir});

  final String key;
  final SortDir dir;
}

SortState? toggleSortState(SortState? current, String key) {
  if (current?.key != key) return SortState(key: key, dir: SortDir.asc);
  if (current?.dir == SortDir.asc) return SortState(key: key, dir: SortDir.desc);
  return null;
}

int compareSortable(
  Object? a,
  Object? b,
  SortDir dir,
) {
  final av = (a ?? '').toString();
  final bv = (b ?? '').toString();
  final mul = dir == SortDir.asc ? 1 : -1;
  if (av.compareTo(bv) < 0) return -1 * mul;
  if (av.compareTo(bv) > 0) return 1 * mul;
  return 0;
}

class ListControlsState {
  const ListControlsState({
    required this.defaultSortKey,
    this.search = '',
    this.layout = ListLayout.grid,
    this.sort,
    this.gridSortValue = '',
    this.loadMode = ListLoadMode.infinite,
    this.pageSize = listDefaultPageSize,
    this.page = 1,
    this.infinitePages = 1,
  });

  factory ListControlsState.initial(String defaultSortKey) => ListControlsState(
        defaultSortKey: defaultSortKey,
        sort: SortState(key: defaultSortKey, dir: SortDir.desc),
        gridSortValue: '$defaultSortKey:desc',
      );

  final String defaultSortKey;
  final String search;
  final ListLayout layout;
  final SortState? sort;
  final String gridSortValue;
  final ListLoadMode loadMode;
  final int pageSize;
  final int page;
  final int infinitePages;

  SortState? get activeSort {
    if (layout == ListLayout.table) return sort;
    final parts = gridSortValue.split(':');
    final key = parts.isNotEmpty && parts.first.isNotEmpty ? parts.first : defaultSortKey;
    final dir = parts.length > 1 && parts[1].toLowerCase() == 'asc' ? SortDir.asc : SortDir.desc;
    return SortState(key: key, dir: dir);
  }

  ListControlsState copyWith({
    String? search,
    ListLayout? layout,
    SortState? sort,
    bool clearSort = false,
    String? gridSortValue,
    ListLoadMode? loadMode,
    int? pageSize,
    int? page,
    int? infinitePages,
  }) {
    return ListControlsState(
      defaultSortKey: defaultSortKey,
      search: search ?? this.search,
      layout: layout ?? this.layout,
      sort: clearSort ? null : sort ?? this.sort,
      gridSortValue: gridSortValue ?? this.gridSortValue,
      loadMode: loadMode ?? this.loadMode,
      pageSize: pageSize ?? this.pageSize,
      page: page ?? this.page,
      infinitePages: infinitePages ?? this.infinitePages,
    );
  }
}

class ListControlsNotifier extends StateNotifier<ListControlsState> {
  ListControlsNotifier({required String defaultSortKey}) : super(ListControlsState.initial(defaultSortKey));

  Object? _lastResetKey;

  void setSearch(String value) => state = state.copyWith(search: value);
  void setLayout(ListLayout value) => state = state.copyWith(layout: value);
  void setGridSortValue(String value) => state = state.copyWith(gridSortValue: value);
  void setLoadMode(ListLoadMode value) => state = state.copyWith(loadMode: value);
  void setPage(int value) => state = state.copyWith(page: value < 1 ? 1 : value);
  void setInfinitePages(int value) => state = state.copyWith(infinitePages: value < 1 ? 1 : value);

  void setPageSize(int value) {
    final parsed = value.floor();
    final clamped = parsed.clamp(listPageSizeMin, listPageSizeMax);
    state = state.copyWith(pageSize: clamped);
  }

  void toggleColumnSort(String key) {
    final next = toggleSortState(state.sort, key);
    if (next == null) {
      state = state.copyWith(clearSort: true);
      return;
    }
    state = state.copyWith(sort: next);
  }

  void syncReset({
    required List<Object?> resetDeps,
  }) {
    final resetKey = Object.hashAll([state.pageSize, state.loadMode, ...resetDeps]);
    if (_lastResetKey == null) {
      _lastResetKey = resetKey;
      return;
    }
    if (_lastResetKey != resetKey) {
      _lastResetKey = resetKey;
      state = state.copyWith(page: 1, infinitePages: 1);
    }
  }
}

String defaultSortKeyForListScope(String scope) {
  return switch (scope) {
    'rides' => 'created_at',
    'audit' => 'created_at',
    'messages' => 'created_at',
    'security_events' => 'created_at',
    'feedbacks' => 'created_at',
    _ => 'updated_at',
  };
}

final listControlsProvider = StateNotifierProvider.family<ListControlsNotifier, ListControlsState, String>(
  (ref, scope) => ListControlsNotifier(defaultSortKey: defaultSortKeyForListScope(scope)),
);
