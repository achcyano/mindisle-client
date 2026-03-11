final class PagedList<T> {
  const PagedList({required this.items, this.nextCursor});

  final List<T> items;
  final String? nextCursor;
}
