import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/utils/date_format.dart';
import '../../../shared/widgets/empty_state.dart';
import '../data/stock_repository.dart';
import '../domain/stock_item.dart';
import 'stock_form_sheet.dart';

class StockScreen extends ConsumerStatefulWidget {
  const StockScreen({super.key});

  @override
  ConsumerState<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends ConsumerState<StockScreen> {
  String _query = '';
  bool _onlyLowStock = false;
  StockCategory? _categoryFilter;
  String? _subCategoryFilter;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<StockItem> all = ref.watch(stockProvider);

    List<StockItem> items = _query.trim().isEmpty
        ? List<StockItem>.from(all)
        : all.where((StockItem i) {
            final String q = _query.toLowerCase();
            return i.name.toLowerCase().contains(q) ||
                (i.brand?.toLowerCase().contains(q) ?? false) ||
                (i.subCategory?.toLowerCase().contains(q) ?? false);
          }).toList();
    if (_onlyLowStock) {
      items = items.where((StockItem i) => i.isLow).toList();
    }
    if (_categoryFilter != null) {
      items =
          items.where((StockItem i) => i.category == _categoryFilter).toList();
    }
    if (_subCategoryFilter != null) {
      items = items
          .where((StockItem i) => i.subCategory == _subCategoryFilter)
          .toList();
    }

    final List<StockItem> lowItems =
        all.where((StockItem i) => i.isLow).toList();
    final double totalValue =
        all.fold<double>(0, (double sum, StockItem i) => sum + i.totalValue);

    final List<String> subCategoryOptions = <String>[
      if (_categoryFilter != null)
        ...{
          for (final StockItem i in all)
            if (i.category == _categoryFilter &&
                i.subCategory != null &&
                i.subCategory!.trim().isNotEmpty)
              i.subCategory!,
        },
    ]..sort();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock'),
      ),
      body: CustomScrollView(
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: _SummaryCard(
                      icon: Icons.inventory_2_rounded,
                      label: '${all.length} articles',
                      sub: AppDateFormat.currencyEur(totalValue),
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SummaryCard(
                      icon: Icons.warning_amber_rounded,
                      label: '${lowItems.length} en alerte',
                      sub: 'Seuil atteint',
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: TextField(
                onChanged: (String v) => setState(() => _query = v),
                decoration: const InputDecoration(
                  hintText: 'Rechercher un article…',
                  prefixIcon: Icon(Icons.search_rounded),
                  isDense: true,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: <Widget>[
                    FilterChip(
                      label: const Text('Stock bas'),
                      selected: _onlyLowStock,
                      onSelected: (bool v) =>
                          setState(() => _onlyLowStock = v),
                      avatar: const Icon(Icons.warning_amber_rounded, size: 18),
                    ),
                    const SizedBox(width: 8),
                    ...StockCategory.values.map((StockCategory c) {
                      final bool selected = _categoryFilter == c;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(c.label),
                          avatar: Icon(c.icon, size: 18),
                          selected: selected,
                          onSelected: (bool v) {
                            setState(() {
                              _categoryFilter = v ? c : null;
                              _subCategoryFilter = null;
                            });
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
          if (subCategoryOptions.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: <Widget>[
                      Text(
                        'Sous-catégorie',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ...subCategoryOptions.map((String sub) {
                        final bool selected = _subCategoryFilter == sub;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(sub),
                            selected: selected,
                            onSelected: (bool v) {
                              setState(() {
                                _subCategoryFilter = v ? sub : null;
                              });
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            )
          else
            const SliverToBoxAdapter(child: SizedBox(height: 4)),
          if (items.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: Icons.inventory_2_outlined,
                title: 'Aucun article trouvé',
                message: 'Essaie un autre filtre ou ajoute un nouvel article.',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: SliverList.separated(
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (BuildContext context, int index) =>
                    _StockItemTile(
                  item: items[index],
                  onTap: () => _editItem(items[index]),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createItem,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Article'),
      ),
    );
  }

  Future<void> _createItem() async {
    final StockItem? created = await showStockFormSheet(context);
    if (!mounted) return;
    if (created != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Article ajouté · ${created.name}')),
      );
    }
  }

  Future<void> _editItem(StockItem item) async {
    final StockItem? saved =
        await showStockFormSheet(context, initial: item);
    if (!mounted) return;
    if (saved != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Article mis à jour · ${saved.name}')),
      );
    }
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.sub,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String sub;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _StockItemTile extends StatelessWidget {
  const _StockItemTile({required this.item, this.onTap});

  final StockItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color iconBg = theme.colorScheme.primaryContainer;
    final Color iconFg = theme.colorScheme.onPrimaryContainer;

    return Card(
      clipBehavior: Clip.antiAlias,
      color: theme.colorScheme.surfaceContainerHigh,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
          children: <Widget>[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.category.icon, color: iconFg),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          item.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (item.isOutOfStock)
                        _Badge(
                          label: 'Rupture',
                          color: theme.colorScheme.error,
                        )
                      else if (item.isLow)
                        _Badge(
                          label: 'Stock bas',
                          color: theme.colorScheme.tertiary,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      Text(
                        item.category.label,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (item.brand != null) ...<Widget>[
                        Text(
                          '·',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.brand!,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      if (item.subCategory != null) ...<Widget>[
                        Text(
                          '·',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.subCategory!,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSecondaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      Text(
                        '${item.quantity} ${item.unit}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '/ seuil ${item.threshold}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        AppDateFormat.currencyEur(item.totalValue),
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
