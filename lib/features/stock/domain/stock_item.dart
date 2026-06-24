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
    this.lastRestockAt,
  });

  final String id;
  final String name;
  final StockCategory category;
  final int quantity;
  final int threshold;
  final String unit;
  final double unitPrice;
  final DateTime? lastRestockAt;

  bool get isLow => quantity <= threshold;
  bool get isOutOfStock => quantity <= 0;
  double get totalValue => quantity * unitPrice;
}
