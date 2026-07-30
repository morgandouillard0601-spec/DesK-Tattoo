import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/stock_item.dart';

class StockNotifier extends Notifier<List<StockItem>> {
  @override
  List<StockItem> build() => List<StockItem>.from(_seed);

  static final DateTime _now = DateTime.now();

  static final List<StockItem> _seed = <StockItem>[
    StockItem(
      id: 's1',
      name: 'Cartouches 3RL',
      category: StockCategory.cartridges,
      subCategory: 'Round Liner',
      quantity: 32,
      threshold: 20,
      unit: 'pcs',
      unitPrice: 1.85,
      lastRestockAt: _now.subtract(const Duration(days: 12)),
    ),
    StockItem(
      id: 's2',
      name: 'Cartouches 7M1',
      category: StockCategory.cartridges,
      subCategory: 'Magnum',
      quantity: 8,
      threshold: 15,
      unit: 'pcs',
      unitPrice: 1.95,
      lastRestockAt: _now.subtract(const Duration(days: 30)),
    ),
    StockItem(
      id: 's3',
      name: 'Encre Noire Dynamic',
      category: StockCategory.ink,
      subCategory: 'Dynamic',
      quantity: 4,
      threshold: 3,
      unit: 'flacons',
      unitPrice: 18.50,
      lastRestockAt: _now.subtract(const Duration(days: 45)),
    ),
    StockItem(
      id: 's4',
      name: 'Encre Rouge World Famous',
      category: StockCategory.ink,
      subCategory: 'World Famous',
      quantity: 2,
      threshold: 2,
      unit: 'flacons',
      unitPrice: 14.90,
      lastRestockAt: _now.subtract(const Duration(days: 60)),
    ),
    StockItem(
      id: 's5',
      name: 'Gants nitrile noirs M',
      category: StockCategory.gloves,
      subCategory: 'Nitrile noir · Taille M',
      quantity: 320,
      threshold: 100,
      unit: 'pcs',
      unitPrice: 0.18,
      lastRestockAt: _now.subtract(const Duration(days: 10)),
    ),
    StockItem(
      id: 's6',
      name: 'Film de protection',
      category: StockCategory.hygiene,
      subCategory: 'Film protection',
      quantity: 1,
      threshold: 2,
      unit: 'rouleaux',
      unitPrice: 22.00,
      lastRestockAt: _now.subtract(const Duration(days: 90)),
    ),
    const StockItem(
      id: 's7',
      name: 'Savon vert 1L',
      category: StockCategory.hygiene,
      subCategory: 'Savon vert',
      quantity: 3,
      threshold: 2,
      unit: 'bidons',
      unitPrice: 12.40,
    ),
    const StockItem(
      id: 's8',
      name: 'Aiguilles Magnum 13',
      category: StockCategory.needles,
      subCategory: 'Magnum',
      brand: 'Kwadron',
      quantity: 50,
      threshold: 30,
      unit: 'pcs',
      unitPrice: 0.85,
    ),
    const StockItem(
      id: 's9',
      name: 'Machine rotative Cheyenne',
      category: StockCategory.machines,
      subCategory: 'Rotative',
      quantity: 2,
      threshold: 1,
      unit: 'pcs',
      unitPrice: 950,
    ),
  ];

  List<StockItem> search(String query) {
    if (query.trim().isEmpty) return state;
    final String q = query.toLowerCase();
    return state
        .where((StockItem i) => i.name.toLowerCase().contains(q))
        .toList(growable: false);
  }

  List<StockItem> lowStock() =>
      state.where((StockItem i) => i.isLow).toList(growable: false);

  /// Returns default suggestions + custom sub-categories already used in
  /// existing items for the given category (deduped, order preserved).
  List<String> subCategoriesFor(StockCategory category) {
    final List<String> defaults = category.defaultSubCategories;
    final Set<String> customs = <String>{};
    for (final StockItem i in state) {
      if (i.category == category &&
          i.subCategory != null &&
          i.subCategory!.trim().isNotEmpty &&
          !defaults.contains(i.subCategory)) {
        customs.add(i.subCategory!);
      }
    }
    return <String>[...defaults, ...customs];
  }

  /// Default brands + custom brands already used for the category.
  List<String> brandsFor(StockCategory category) {
    final List<String> defaults = category.defaultBrands;
    if (defaults.isEmpty) return const <String>[];
    final Set<String> customs = <String>{};
    for (final StockItem i in state) {
      if (i.category == category &&
          i.brand != null &&
          i.brand!.trim().isNotEmpty &&
          !defaults.contains(i.brand)) {
        customs.add(i.brand!);
      }
    }
    return <String>[...defaults, ...customs];
  }

  void add(StockItem item) {
    state = <StockItem>[...state, item];
  }

  void update(StockItem item) {
    state = <StockItem>[
      for (final StockItem i in state)
        if (i.id == item.id) item else i,
    ];
  }

  void delete(String id) {
    state = state.where((StockItem i) => i.id != id).toList(growable: false);
  }
}

final NotifierProvider<StockNotifier, List<StockItem>> stockProvider =
    NotifierProvider<StockNotifier, List<StockItem>>(StockNotifier.new);
