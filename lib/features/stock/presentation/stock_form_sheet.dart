import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/utils/id_generator.dart';
import '../../../shared/widgets/form_sheet_scaffold.dart';
import '../data/stock_repository.dart';
import '../domain/stock_item.dart';

Future<StockItem?> showStockFormSheet(BuildContext context) {
  return showModalBottomSheet<StockItem>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const StockFormSheet(),
  );
}

class StockFormSheet extends ConsumerStatefulWidget {
  const StockFormSheet({super.key});

  @override
  ConsumerState<StockFormSheet> createState() => _StockFormSheetState();
}

class _StockFormSheetState extends ConsumerState<StockFormSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _quantity = TextEditingController(text: '1');
  final TextEditingController _threshold = TextEditingController(text: '0');
  final TextEditingController _unit = TextEditingController(text: 'pcs');
  final TextEditingController _unitPrice = TextEditingController();

  StockCategory _category = StockCategory.cartridges;

  @override
  void dispose() {
    _name.dispose();
    _quantity.dispose();
    _threshold.dispose();
    _unit.dispose();
    _unitPrice.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final StockItem item = StockItem(
      id: generateId('s'),
      name: _name.text.trim(),
      category: _category,
      quantity: int.tryParse(_quantity.text) ?? 0,
      threshold: int.tryParse(_threshold.text) ?? 0,
      unit: _unit.text.trim(),
      unitPrice: double.tryParse(_unitPrice.text.replaceAll(',', '.')) ?? 0,
      lastRestockAt: DateTime.now(),
    );

    ref.read(stockProvider.notifier).add(item);
    Navigator.of(context).pop(item);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return FormSheetScaffold(
      title: 'Nouvel article',
      onSave: _save,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Nom de l\'article',
                hintText: 'Ex. Cartouches 3RL',
                prefixIcon: Icon(Icons.label_rounded),
              ),
              validator: (String? v) =>
                  v == null || v.trim().isEmpty ? 'Requis' : null,
            ),
            const SizedBox(height: 16),
            Text(
              'Catégorie',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: StockCategory.values.map((StockCategory c) {
                final bool selected = _category == c;
                return ChoiceChip(
                  label: Text(c.label),
                  avatar: Icon(c.icon, size: 18),
                  selected: selected,
                  onSelected: (_) => setState(() => _category = c),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextFormField(
                    controller: _quantity,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Quantité',
                      prefixIcon: Icon(Icons.numbers_rounded),
                    ),
                    validator: _intValidator,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _unit,
                    decoration: const InputDecoration(
                      labelText: 'Unité',
                      hintText: 'pcs, ml, …',
                    ),
                    validator: (String? v) =>
                        v == null || v.trim().isEmpty ? 'Requis' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _threshold,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Seuil d\'alerte',
                helperText: 'En dessous, l\'article passe en stock bas',
                prefixIcon: Icon(Icons.warning_amber_rounded),
              ),
              validator: _intValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _unitPrice,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Prix unitaire',
                prefixIcon: Icon(Icons.euro_rounded),
                suffixText: '€',
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String? _intValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Requis';
    if (int.tryParse(v) == null) return 'Nombre invalide';
    return null;
  }
}
