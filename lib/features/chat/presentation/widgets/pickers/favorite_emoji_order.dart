/// Fork: puts favourites in the order the account stored them, the order the
/// web and desktop apps show and let people change by dragging
/// (tyne-chat/tyne#101). [keyOf] gives the key an item is stored under.
void sortByFavoriteOrder<T>(
  List<T> items,
  List<String> favoriteKeys,
  String Function(T item) keyOf,
) {
  final Map<String, int> positions = <String, int>{
    for (final (int index, String key) in favoriteKeys.indexed) key: index,
  };
  int positionOf(T item) => positions[keyOf(item)] ?? favoriteKeys.length;
  items.sort((a, b) => positionOf(a).compareTo(positionOf(b)));
}
