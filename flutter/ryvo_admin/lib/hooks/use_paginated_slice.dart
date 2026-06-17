import 'package:ryvo_admin/hooks/use_list_controls.dart';

class PaginatedSliceOptions {
  const PaginatedSliceOptions({
    required this.pageSize,
    required this.loadMode,
    required this.page,
    required this.setPage,
    required this.infinitePages,
    required this.setInfinitePages,
    this.resetDeps = const <Object?>[],
  });

  final int pageSize;
  final ListLoadMode loadMode;
  final int page;
  final void Function(int page) setPage;
  final int infinitePages;
  final void Function(int pages) setInfinitePages;
  final List<Object?> resetDeps;
}

class PaginatedSliceResult<T> {
  const PaginatedSliceResult({
    required this.visibleItems,
    required this.total,
    required this.totalPages,
    required this.page,
    required this.hasMore,
    required this.loadMode,
    required this.showingFrom,
    required this.showingTo,
  });

  final List<T> visibleItems;
  final int total;
  final int totalPages;
  final int page;
  final bool hasMore;
  final ListLoadMode loadMode;
  final int showingFrom;
  final int showingTo;
}

/// Stateful helper that mirrors reset behavior from React `usePaginatedSlice`.
class PaginatedSliceHook<T> {
  Object? _lastResetKey;

  void _defer(void Function() action) {
    Future.microtask(action);
  }

  PaginatedSliceResult<T> call(List<T> allItems, PaginatedSliceOptions options) {
    final safePageSize = options.pageSize < 1 ? 1 : options.pageSize;
    final total = allItems.length;
    final totalPages = (total / safePageSize).ceil().clamp(1, 1 << 30);

    final resetKey = Object.hashAll([safePageSize, options.loadMode, ...options.resetDeps]);
    if (_lastResetKey == null) {
      _lastResetKey = resetKey;
    } else if (_lastResetKey != resetKey) {
      _lastResetKey = resetKey;
      _defer(() {
        options.setPage(1);
        options.setInfinitePages(1);
      });
    }

    var page = options.page;
    if (page > totalPages) {
      page = totalPages;
      _defer(() => options.setPage(totalPages));
    }
    page = page.clamp(1, totalPages);
    final infinitePages = options.infinitePages < 1 ? 1 : options.infinitePages;

    final List<T> visibleItems;
    if (options.loadMode == ListLoadMode.pages) {
      final start = (page - 1) * safePageSize;
      visibleItems = allItems.skip(start).take(safePageSize).toList(growable: false);
    } else {
      visibleItems = allItems.take(infinitePages * safePageSize).toList(growable: false);
    }

    final hasMore = options.loadMode == ListLoadMode.infinite && visibleItems.length < total;
    final showingFrom = total == 0 ? 0 : options.loadMode == ListLoadMode.pages ? ((page - 1) * safePageSize) + 1 : 1;
    final showingTo = total == 0 ? 0 : options.loadMode == ListLoadMode.pages ? (page * safePageSize > total ? total : page * safePageSize) : visibleItems.length;

    return PaginatedSliceResult<T>(
      visibleItems: visibleItems,
      total: total,
      totalPages: totalPages,
      page: page,
      hasMore: hasMore,
      loadMode: options.loadMode,
      showingFrom: showingFrom,
      showingTo: showingTo,
    );
  }

  void loadMore(PaginatedSliceResult<T> result, PaginatedSliceOptions options) {
    if (options.loadMode != ListLoadMode.infinite || !result.hasMore) return;
    options.setInfinitePages(options.infinitePages + 1);
  }
}
