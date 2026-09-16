import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/form_sheet_scaffold.dart';
import '../data/stock_repository.dart';
import '../domain/stock_item.dart';

Future<StockItem?> showStockFormSheet(
  BuildContext context, {
  StockItem? initial,
}) {
  return showModalBottomSheet<StockItem>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => StockFormSheet(initial: initial),
  );
}

class StockFormSheet extends ConsumerStatefulWidget {
  const StockFormSheet({this.initial, super.key});

  final StockItem? initial;

  @override
  ConsumerState<StockFormSheet> createState() => _StockFormSheetState();
}

class _StockFormSheetState extends ConsumerState<StockFormSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _quantity;
  late final TextEditingController _threshold;
  late final TextEditingController _unit;
  late final TextEditingController _unitPrice;
  final TextEditingController _customSub = TextEditingController();
  final TextEditingController _customBrand = TextEditingController();

  late StockCategory _category;
  String? _subCategory;
  String? _brand;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final StockItem? i = widget.initial;
    _name = TextEditingController(text: i?.name ?? '');
    _quantity = TextEditingController(text: i?.quantity.toString() ?? '1');
    _threshold = TextEditingController(text: i?.threshold.toString() ?? '0');
    _unit = TextEditingController(text: i?.unit ?? 'pcs');
    _unitPrice = TextEditingController(
      text: i?.unitPrice != null && i!.unitPrice != 0
          ? i.unitPrice.toString()
          : '',
    );
    _category = i?.category ?? StockCategory.cartridges;
    _subCategory = i?.subCategory;
    _brand = i?.brand;
  }

  @override
  void dispose() {
    _name.dispose();
    _quantity.dispose();
    _threshold.dispose();
    _unit.dispose();
    _unitPrice.dispose();
    _customSub.dispose();
    _customBrand.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final String? sub = _customSub.text.trim().isNotEmpty
        ? _customSub.text.trim()
        : _subCategory;
    final String? brand = _customBrand.text.trim().isNotEmpty
        ? _customBrand.text.trim()
        : _brand;

    final StockNotifier notifier = ref.read(stockProvider.notifier);

    final StockItem item = StockItem(
      id: _isEdit ? widget.initial!.id : '',
      name: _name.text.trim(),
      category: _category,
      subCategory: sub,
      brand: brand,
      quantity: int.tryParse(_quantity.text) ?? 0,
      threshold: int.tryParse(_threshold.text) ?? 0,
      unit: _unit.text.trim(),
      unitPrice: double.tryParse(_unitPrice.text.replaceAll(',', '.')) ?? 0,
      lastRestockAt:
          _isEdit ? widget.initial!.lastRestockAt : DateTime.now(),
    );

    try {
      if (_isEdit) {
        await notifier.save(item);
      } else {
        await notifier.add(item);
      }
      if (!mounted) return;
      Navigator.of(context).pop(item);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enregistrement impossible')),
      );
    }
  }

  Future<void> _confirmDelete() async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Supprimer cet article ?'),
        content: Text(
          '« ${widget.initial!.name} » sera retiré définitivement du stock.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.errorContainer,
              foregroundColor: Theme.of(ctx).colorScheme.onErrorContainer,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (ok == true && mounted) {
      await ref.read(stockProvider.notifier).delete(widget.initial!.id);
      if (!mounted) return;
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<String> suggestions =
        ref.read(stockProvider.notifier).subCategoriesFor(_category);
    final List<String> brandSuggestions =
        ref.read(stockProvider.notifier).brandsFor(_category);
    final bool showBrand = brandSuggestions.isNotEmpty ||
        _category.defaultBrands.isNotEmpty ||
        _category == StockCategory.needles;

    return FormSheetScaffold(
      title: _isEdit ? 'Modifier l\'article' : 'Nouvel article',
      saveLabel: _isEdit ? 'Enregistrer' : 'Ajouter',
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
            const _SectionLabel('Catégorie'),
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
                  onSelected: (_) => setState(() {
                    _category = c;
                    _subCategory = null;
                    _brand = null;
                    _customSub.clear();
                    _customBrand.clear();
                  }),
                );
              }).toList(),
            ),
            if (showBrand) ...<Widget>[
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  const _SectionLabel('Marque'),
                  const SizedBox(width: 6),
                  Text(
                    '(optionnel)',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (brandSuggestions.isNotEmpty) ...<Widget>[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: brandSuggestions.map((String b) {
                    final bool selected = _brand == b;
                    return ChoiceChip(
                      label: Text(b),
                      selected: selected,
                      onSelected: (_) => setState(() {
                        _brand = selected ? null : b;
                        _customBrand.clear();
                      }),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
              ],
              TextFormField(
                controller: _customBrand,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Autre marque',
                  hintText: _brand == null
                      ? 'Saisis une marque personnalisée'
                      : 'Remplace : $_brand',
                  prefixIcon: const Icon(Icons.storefront_rounded),
                  isDense: true,
                ),
                onChanged: (String v) {
                  if (v.trim().isNotEmpty && _brand != null) {
                    setState(() => _brand = null);
                  }
                },
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                const _SectionLabel('Sous-catégorie'),
                const SizedBox(width: 6),
                Text(
                  '(optionnel)',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (suggestions.isNotEmpty) ...<Widget>[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: suggestions.map((String s) {
                  final bool selected = _subCategory == s;
                  return ChoiceChip(
                    label: Text(s),
                    selected: selected,
                    onSelected: (_) => setState(() {
                      _subCategory = selected ? null : s;
                      _customSub.clear();
                    }),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
            ],
            TextFormField(
              controller: _customSub,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Nouvelle sous-catégorie',
                hintText: _subCategory == null
                    ? 'Saisis une valeur personnalisée'
                    : 'Remplace : $_subCategory',
                prefixIcon: const Icon(Icons.add_rounded),
                isDense: true,
                helperText:
                    'Elle apparaîtra ensuite comme suggestion pour cette catégorie',
              ),
              onChanged: (String v) {
                if (v.trim().isNotEmpty && _subCategory != null) {
                  setState(() => _subCategory = null);
                }
              },
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
            if (_isEdit) ...<Widget>[
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _confirmDelete,
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  side: BorderSide(color: theme.colorScheme.error),
                ),
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Supprimer cet article'),
              ),
            ],
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Text(
      label,
      style: theme.textTheme.labelLarge?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
