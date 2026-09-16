import 'package:flutter/material.dart';

import '../../../core/data/artist_scoped_notifier.dart';

enum StockCategory { needles, ink, cartridges, gloves, hygiene, machines, other }

StockCategory stockCategoryFromWire(String? value) {
  for (final StockCategory c in StockCategory.values) {
    if (c.name == value) return c;
  }
  return StockCategory.other;
}

extension StockCategoryX on StockCategory {
  /// Valeur attendue par la contrainte CHECK de `public.stock_items`.
  String get wire => name;

  String get label => switch (this) {
        StockCategory.needles => 'Aiguilles',
        StockCategory.ink => 'Encres',
        StockCategory.cartridges => 'Cartouches',
        StockCategory.gloves => 'Gants',
        StockCategory.hygiene => 'Hygiène',
        StockCategory.machines => 'Machines',
        StockCategory.other => 'Autre',
      };

  IconData get icon => switch (this) {
        StockCategory.needles => Icons.colorize_rounded,
        StockCategory.ink => Icons.water_drop_rounded,
        StockCategory.cartridges => Icons.battery_full_rounded,
        StockCategory.gloves => Icons.back_hand_rounded,
        StockCategory.hygiene => Icons.sanitizer_rounded,
        StockCategory.machines => Icons.precision_manufacturing_rounded,
        StockCategory.other => Icons.inventory_2_rounded,
      };

  /// Suggested sub-categories shown as chips in the form. The user can also
  /// type a custom value.
  List<String> get defaultSubCategories => switch (this) {
        StockCategory.needles => const <String>[
            'Round Liner',
            'Round Shader',
            'Magnum',
            'Curved Magnum',
            'Flat',
            'Bugpin',
          ],
        StockCategory.cartridges => const <String>[
            'Round Liner',
            'Round Shader',
            'Magnum',
            'Curved Magnum',
            'Flat',
            'Bugpin',
            'Textured',
          ],
        StockCategory.ink => const <String>[
            'Noir',
            'Grey wash',
            'Blanc',
            'Couleur',
            'Dynamic',
            'World Famous',
            'Eternal',
            'Intenze',
          ],
        StockCategory.gloves => const <String>[
            'Nitrile noir',
            'Nitrile bleu',
            'Latex',
            'Vinyle',
            'Taille S',
            'Taille M',
            'Taille L',
            'Taille XL',
          ],
        StockCategory.hygiene => const <String>[
            'Savon vert',
            'Désinfectant',
            'Film protection',
            'Papier absorbant',
            'Vaseline',
            'Cotons-tiges',
            'Serviettes',
          ],
        StockCategory.machines => const <String>[
            'Rotative',
            'Bobine',
            'Pen',
            'Wireless',
            'Pédale',
            'Alimentation',
            'Câble RCA',
          ],
        StockCategory.other => const <String>[],
      };

  /// Suggested brands for categories that use them (needles).
  List<String> get defaultBrands => switch (this) {
        StockCategory.needles => const <String>[
            'Kwadron',
            'Cheyenne',
            'Bishop',
            'Emalla',
            'Stigma',
            'Mast',
            'Dragonhawk',
            'EZ',
            'Peak',
            'Critical',
          ],
        _ => const <String>[],
      };
}

class StockItem {
  const StockItem({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.threshold,
    required this.unit,
    required this.unitPrice,
    this.subCategory,
    this.brand,
    this.lastRestockAt,
  });

  factory StockItem.fromSupabase(Map<String, dynamic> row) {
    return StockItem(
      id: readString(row['id']),
      name: readString(row['name']),
      category: stockCategoryFromWire(row['category'] as String?),
      quantity: readInt(row['quantity']),
      threshold: readInt(row['threshold']),
      unit: readString(row['unit']),
      unitPrice: readDouble(row['unit_price']),
      subCategory: row['sub_category'] as String?,
      brand: row['brand'] as String?,
      lastRestockAt: readDate(row['last_restock_at']),
    );
  }

  final String id;
  final String name;
  final StockCategory category;
  final String? subCategory;
  final String? brand;
  final int quantity;
  final int threshold;
  final String unit;
  final double unitPrice;
  final DateTime? lastRestockAt;

  bool get isLow => quantity <= threshold;
  bool get isOutOfStock => quantity <= 0;
  double get totalValue => quantity * unitPrice;

  /// Payload d'écriture (l'`artist_id` est ajouté par le repository).
  Map<String, dynamic> toSupabase() => <String, dynamic>{
        'name': name,
        'category': category.wire,
        'sub_category': subCategory,
        'brand': brand,
        'quantity': quantity,
        'threshold': threshold,
        'unit': unit,
        'unit_price': unitPrice,
        'last_restock_at': lastRestockAt?.toIso8601String(),
      };

  StockItem copyWith({
    String? id,
    String? name,
    StockCategory? category,
    int? quantity,
    int? threshold,
    String? unit,
    double? unitPrice,
    String? subCategory,
    String? brand,
    DateTime? lastRestockAt,
  }) {
    return StockItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      threshold: threshold ?? this.threshold,
      unit: unit ?? this.unit,
      unitPrice: unitPrice ?? this.unitPrice,
      subCategory: subCategory ?? this.subCategory,
      brand: brand ?? this.brand,
      lastRestockAt: lastRestockAt ?? this.lastRestockAt,
    );
  }
}
