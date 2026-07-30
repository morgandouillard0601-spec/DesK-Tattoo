import 'package:flutter/material.dart';

enum StockCategory { needles, ink, cartridges, gloves, hygiene, machines, other }

extension StockCategoryX on StockCategory {
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
}
