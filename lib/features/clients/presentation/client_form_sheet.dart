import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/form_sheet_scaffold.dart';
import '../data/clients_repository.dart';
import '../domain/client.dart';

Future<Client?> showClientFormSheet(
  BuildContext context, {
  Client? initial,
}) {
  return showModalBottomSheet<Client>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => ClientFormSheet(initial: initial),
  );
}

class ClientFormSheet extends ConsumerStatefulWidget {
  const ClientFormSheet({this.initial, super.key});

  final Client? initial;

  @override
  ConsumerState<ClientFormSheet> createState() => _ClientFormSheetState();
}

class _ClientFormSheetState extends ConsumerState<ClientFormSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _notes;

  bool _busy = false;

  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final Client? i = widget.initial;
    _firstName = TextEditingController(text: i?.firstName ?? '');
    _lastName = TextEditingController(text: i?.lastName ?? '');
    _phone = TextEditingController(text: i?.phone ?? '');
    _email = TextEditingController(text: i?.email ?? '');
    _notes = TextEditingController(text: i?.notes ?? '');
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    _email.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);

    final Client? initial = widget.initial;
    final Client client = (initial ??
            Client(
              id: '',
              firstName: '',
              lastName: '',
              phone: '',
              email: '',
              createdAt: DateTime.now(),
            ))
        .copyWith(
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      phone: _phone.text.trim(),
      email: _email.text.trim(),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
    );

    try {
      final ClientsNotifier notifier = ref.read(clientsProvider.notifier);
      if (_isEditing) {
        await notifier.save(client);
      } else {
        await notifier.add(client);
      }
      if (!mounted) return;
      Navigator.of(context).pop(client);
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enregistrement impossible')),
      );
    }
  }

  Future<void> _confirmDelete() async {
    final Client? initial = widget.initial;
    if (initial == null) return;

    final bool confirmed = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text('Supprimer ce client ?'),
            content: Text(
              'La fiche de ${initial.fullName} et ses contrats signés seront '
              'définitivement supprimés.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Supprimer'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;
    setState(() => _busy = true);
    try {
      await ref.read(clientsProvider.notifier).delete(initial.id);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Suppression impossible')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormSheetScaffold(
      title: _isEditing ? 'Modifier le client' : 'Nouveau client',
      canSave: !_busy,
      onSave: _save,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: TextFormField(
                    controller: _firstName,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Prénom',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                    validator: _required,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _lastName,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nom',
                    ),
                    validator: _required,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Téléphone',
                prefixIcon: Icon(Icons.phone_rounded),
              ),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_rounded),
              ),
              validator: (String? v) {
                if (v == null || v.trim().isEmpty) return 'Requis';
                if (!v.contains('@')) return 'Email invalide';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notes,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Notes (optionnel)',
                alignLabelWithHint: true,
              ),
            ),
            if (_isEditing) ...<Widget>[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _busy ? null : _confirmDelete,
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Supprimer le client'),
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Requis' : null;
}
