import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/utils/date_format.dart';
import '../../../shared/widgets/form_sheet_scaffold.dart';
import '../../clients/data/clients_repository.dart';
import '../../clients/domain/client.dart';
import '../data/accounting_repository.dart';
import '../domain/transaction.dart';

Future<Transaction?> showTransactionFormSheet(BuildContext context) {
  return showModalBottomSheet<Transaction>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const TransactionFormSheet(),
  );
}

class TransactionFormSheet extends ConsumerStatefulWidget {
  const TransactionFormSheet({super.key});

  @override
  ConsumerState<TransactionFormSheet> createState() =>
      _TransactionFormSheetState();
}

class _TransactionFormSheetState extends ConsumerState<TransactionFormSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _label = TextEditingController();
  final TextEditingController _amount = TextEditingController();
  final TextEditingController _category = TextEditingController();

  TransactionType _type = TransactionType.income;
  PaymentMethod _method = PaymentMethod.card;
  DateTime _date = DateTime.now();
  Client? _client;

  static const List<String> _incomeCategories = <String>[
    'Tatouage',
    'Acompte',
    'Consultation',
    'Autre',
  ];
  static const List<String> _expenseCategories = <String>[
    'Fournitures',
    'Loyer',
    'Assurance',
    'Matériel',
    'Marketing',
    'Autre',
  ];

  @override
  void dispose() {
    _label.dispose();
    _amount.dispose();
    _category.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickClient() async {
    final List<Client> clients =
        ref.read(clientsProvider).valueOrNull ?? const <Client>[];
    final Client? picked = await showModalBottomSheet<Client>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _SimpleClientPicker(clients: clients),
    );
    if (picked != null) {
      setState(() {
        _client = picked;
        if (_label.text.trim().isEmpty) {
          _label.text = picked.fullName;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final Transaction tx = Transaction(
      id: '',
      type: _type,
      label: _label.text.trim(),
      amount: double.tryParse(_amount.text.replaceAll(',', '.')) ?? 0,
      date: _date,
      method: _method,
      clientId: _client?.id,
      clientName: _client?.fullName,
      category:
          _category.text.trim().isEmpty ? null : _category.text.trim(),
    );

    try {
      await ref.read(accountingProvider.notifier).add(tx);
      if (!mounted) return;
      Navigator.of(context).pop(tx);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enregistrement impossible')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isIncome = _type == TransactionType.income;
    final List<String> categories =
        isIncome ? _incomeCategories : _expenseCategories;

    return FormSheetScaffold(
      title: 'Nouvelle transaction',
      onSave: _save,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SegmentedButton<TransactionType>(
              segments: const <ButtonSegment<TransactionType>>[
                ButtonSegment<TransactionType>(
                  value: TransactionType.income,
                  label: Text('Revenu'),
                  icon: Icon(Icons.trending_up_rounded),
                ),
                ButtonSegment<TransactionType>(
                  value: TransactionType.expense,
                  label: Text('Dépense'),
                  icon: Icon(Icons.trending_down_rounded),
                ),
              ],
              selected: <TransactionType>{_type},
              onSelectionChanged: (Set<TransactionType> s) {
                setState(() {
                  _type = s.first;
                  _category.clear();
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _label,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Libellé',
                prefixIcon: Icon(Icons.label_rounded),
              ),
              validator: (String? v) =>
                  v == null || v.trim().isEmpty ? 'Requis' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Montant',
                prefixIcon: Icon(Icons.euro_rounded),
                suffixText: '€',
              ),
              validator: (String? v) {
                final double? value =
                    double.tryParse((v ?? '').replaceAll(',', '.'));
                if (value == null || value <= 0) return 'Montant invalide';
                return null;
              },
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date',
                  prefixIcon: Icon(Icons.calendar_today_rounded),
                ),
                child: Text(AppDateFormat.dayLong(_date)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Méthode de paiement',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: PaymentMethod.values.map((PaymentMethod m) {
                return ChoiceChip(
                  label: Text(m.label),
                  avatar: Icon(m.icon, size: 18),
                  selected: _method == m,
                  onSelected: (_) => setState(() => _method = m),
                );
              }).toList(),
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
              children: categories.map((String c) {
                return ChoiceChip(
                  label: Text(c),
                  selected: _category.text == c,
                  onSelected: (_) => setState(() => _category.text = c),
                );
              }).toList(),
            ),
            if (isIncome) ...<Widget>[
              const SizedBox(height: 16),
              Text(
                'Client (optionnel)',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Material(
                color: theme.colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: _pickClient,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    child: Row(
                      children: <Widget>[
                        Icon(
                          Icons.person_rounded,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _client?.fullName ?? 'Associer un client',
                            style: theme.textTheme.bodyLarge,
                          ),
                        ),
                        if (_client != null)
                          IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () =>
                                setState(() => _client = null),
                          )
                        else
                          const Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _SimpleClientPicker extends StatelessWidget {
  const _SimpleClientPicker({required this.clients});

  final List<Client> clients;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      expand: false,
      builder: (BuildContext context, ScrollController controller) {
        return Column(
          children: <Widget>[
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Text(
                'Choisir un client',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: controller,
                itemCount: clients.length,
                itemBuilder: (BuildContext context, int index) {
                  final Client c = clients[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        c.initials,
                        style: TextStyle(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    title: Text(c.fullName),
                    subtitle: Text(c.phone),
                    onTap: () => Navigator.of(context).pop(c),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
