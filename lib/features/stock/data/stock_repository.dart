import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/artist_scoped_notifier.dart';
import '../domain/stock_item.dart';

class StockNotifier extends ArtistScopedNotifier<StockItem> {
  @override
  String get table => 'stock_items';

  @override
  String get orderColumn => 'name';

  @override
  bool get orderAscending => true;

  @override
  StockItem fromRow(Map<String, dynamic> row) => StockItem.fromSupabase(row);

  List<StockItem> search(String query) {
    if (query.trim().isEmpty) return items;
    final String q = query.toLowerCase();
    return items
        .where((StockItem i) => i.name.toLowerCase().contains(q))
        .toList(growable: false);
  }

  List<StockItem> lowStock() =>
      items.where((StockItem i) => i.isLow).toList(growable: false);

  /// Suggestions par défaut + sous-catégories déjà utilisées pour la catégorie
  /// (dédupliquées, ordre conservé).
  List<String> subCategoriesFor(StockCategory category) {
    final List<String> defaults = category.defaultSubCategories;
    final Set<String> customs = <String>{};
    for (final StockItem i in items) {
      if (i.category == category &&
          i.subCategory != null &&
          i.subCategory!.trim().isNotEmpty &&
          !defaults.contains(i.subCategory)) {
        customs.add(i.subCategory!);
      }
    }
    return <String>[...defaults, ...customs];
  }

  /// Marques par défaut + marques déjà utilisées pour la catégorie.
  List<String> brandsFor(StockCategory category) {
    final List<String> defaults = category.defaultBrands;
    if (defaults.isEmpty) return const <String>[];
    final Set<String> customs = <String>{};
    for (final StockItem i in items) {
      if (i.category == category &&
          i.brand != null &&
          i.brand!.trim().isNotEmpty &&
          !defaults.contains(i.brand)) {
        customs.add(i.brand!);
      }
    }
    return <String>[...defaults, ...customs];
  }

  Future<void> add(StockItem item) => insertRow(item.toSupabase());

  /// Nommée `save` et non `update` : `AsyncNotifier` expose déjà `update`.
  Future<void> save(StockItem item) => updateRow(item.id, item.toSupabase());

  Future<void> delete(String id) => deleteRow(id);
}

final AsyncNotifierProvider<StockNotifier, List<StockItem>> stockProvider =
    AsyncNotifierProvider<StockNotifier, List<StockItem>>(StockNotifier.new);
