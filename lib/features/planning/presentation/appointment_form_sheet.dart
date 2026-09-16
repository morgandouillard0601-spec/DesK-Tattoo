import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/utils/date_format.dart';
import '../../../shared/widgets/form_sheet_scaffold.dart';
import '../../clients/data/clients_repository.dart';
import '../../clients/domain/client.dart';
import '../../clients/presentation/client_form_sheet.dart';
import '../data/planning_repository.dart';
import '../domain/appointment.dart';

Future<Appointment?> showAppointmentFormSheet(
  BuildContext context, {
  DateTime? initialDay,
  Appointment? initial,
  Client? initialClient,
}) {
  return showModalBottomSheet<Appointment>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => AppointmentFormSheet(
      initialDay: initialDay,
      initial: initial,
      initialClient: initialClient,
    ),
  );
}

class AppointmentFormSheet extends ConsumerStatefulWidget {
  const AppointmentFormSheet({
    this.initialDay,
    this.initial,
    this.initialClient,
    super.key,
  });

  final DateTime? initialDay;
  final Appointment? initial;
  final Client? initialClient;

  @override
  ConsumerState<AppointmentFormSheet> createState() =>
      _AppointmentFormSheetState();
}

class _AppointmentFormSheetState extends ConsumerState<AppointmentFormSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _price;
  late final TextEditingController _notes;

  Client? _client;
  late DateTime _date;
  late TimeOfDay _time;
  late Duration _duration;
  late AppointmentStatus _status;

  bool get _isEdit => widget.initial != null;

  static const List<Duration> _durations = <Duration>[
    Duration(minutes: 15),
    Duration(minutes: 30),
    Duration(minutes: 45),
    Duration(hours: 1),
    Duration(hours: 1, minutes: 30),
    Duration(hours: 2),
    Duration(hours: 3),
    Duration(hours: 4),
  ];

  @override
  void initState() {
    super.initState();
    final Appointment? i = widget.initial;

    _title = TextEditingController(text: i?.title ?? '');
    _price = TextEditingController(
      text: i != null && i.price != 0 ? i.price.toString() : '',
    );
    _notes = TextEditingController(text: i?.notes ?? '');

    if (i != null) {
      _date = DateTime(i.start.year, i.start.month, i.start.day);
      _time = TimeOfDay(hour: i.start.hour, minute: i.start.minute);
      _duration = i.duration;
      _status = i.status;
      _client = ref.read(clientsProvider.notifier).getById(i.clientId);
      // Fallback stub if the client was deleted but the appointment remains.
      _client ??= Client(
        id: i.clientId,
        firstName: i.clientName.split(' ').first,
        lastName: i.clientName.split(' ').skip(1).join(' '),
        phone: '',
        email: '',
        createdAt: DateTime.now(),
      );
    } else {
      final DateTime now = DateTime.now();
      _date = widget.initialDay ?? DateTime(now.year, now.month, now.day);
      _time = const TimeOfDay(hour: 10, minute: 0);
      _duration = const Duration(hours: 1);
      _status = AppointmentStatus.scheduled;
      _client = widget.initialClient;
    }
  }

  bool get _clientLocked =>
      !_isEdit && widget.initialClient != null;

  @override
  void dispose() {
    _title.dispose();
    _price.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _time,
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _pickClient() async {
    final List<Client> clients =
        ref.read(clientsProvider).valueOrNull ?? const <Client>[];
    final Client? picked = await showModalBottomSheet<Client>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ClientPickerSheet(clients: clients),
    );
    if (picked != null) setState(() => _client = picked);
  }

  Future<void> _createClient() async {
    final Client? created = await showClientFormSheet(context);
    if (created != null) setState(() => _client = created);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_client == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionne un client')),
      );
      return;
    }

    final DateTime start = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _time.hour,
      _time.minute,
    );

    final double price =
        double.tryParse(_price.text.replaceAll(',', '.')) ?? 0;

    final PlanningNotifier notifier = ref.read(planningProvider.notifier);

    final Appointment appointment = Appointment(
      id: _isEdit ? widget.initial!.id : '',
      clientId: _client!.id,
      clientName: _client!.fullName,
      title: _title.text.trim(),
      start: start,
      duration: _duration,
      price: price,
      status: _status,
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
    );

    try {
      if (_isEdit) {
        await notifier.save(appointment);
      } else {
        await notifier.add(appointment);
      }
      if (!mounted) return;
      Navigator.of(context).pop(appointment);
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
        title: const Text('Supprimer ce rendez-vous ?'),
        content: Text(
          '« ${widget.initial!.title} » avec ${widget.initial!.clientName} '
          'sera retiré du planning.',
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
      await ref.read(planningProvider.notifier).delete(widget.initial!.id);
      if (!mounted) return;
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return FormSheetScaffold(
      title: _isEdit ? 'Modifier le rendez-vous' : 'Nouveau rendez-vous',
      saveLabel: _isEdit ? 'Enregistrer' : 'Ajouter',
      onSave: _save,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const _SectionLabel(label: 'Client'),
            const SizedBox(height: 6),
            _PickerTile(
              icon: Icons.person_rounded,
              label: _client?.fullName ?? 'Choisir un client',
              onTap: _clientLocked ? null : _pickClient,
              trailing: _clientLocked
                  ? null
                  : TextButton.icon(
                      onPressed: _createClient,
                      icon: const Icon(Icons.person_add_rounded, size: 18),
                      label: const Text('Nouveau'),
                    ),
            ),
            const SizedBox(height: 16),
            const _SectionLabel(label: 'Prestation'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Titre',
                hintText: 'Ex. Lettrage avant-bras',
                prefixIcon: Icon(Icons.brush_rounded),
              ),
              validator: (String? v) =>
                  v == null || v.trim().isEmpty ? 'Requis' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: _PickerTile(
                    icon: Icons.calendar_today_rounded,
                    label: AppDateFormat.dayLong(_date),
                    onTap: _pickDate,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _PickerTile(
                    icon: Icons.access_time_rounded,
                    label: _time.format(context),
                    onTap: _pickTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const _SectionLabel(label: 'Durée'),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _durations.map((Duration d) {
                final bool selected = _duration == d;
                return ChoiceChip(
                  label: Text(AppDateFormat.duration(d)),
                  selected: selected,
                  onSelected: (_) => setState(() => _duration = d),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const _SectionLabel(label: 'Statut'),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppointmentStatus.values.map((AppointmentStatus s) {
                return ChoiceChip(
                  label: Text(s.label),
                  selected: _status == s,
                  selectedColor:
                      s.color(theme.colorScheme).withValues(alpha: 0.20),
                  onSelected: (_) => setState(() => _status = s),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const _SectionLabel(label: 'Prix'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _price,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Montant',
                hintText: '0',
                prefixIcon: Icon(Icons.euro_rounded),
                suffixText: '€',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notes,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Notes (optionnel)',
                alignLabelWithHint: true,
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
                label: const Text('Supprimer ce rendez-vous'),
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

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

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: <Widget>[
              Icon(icon, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _ClientPickerSheet extends StatefulWidget {
  const _ClientPickerSheet({required this.clients});

  final List<Client> clients;

  @override
  State<_ClientPickerSheet> createState() => _ClientPickerSheetState();
}

class _ClientPickerSheetState extends State<_ClientPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<Client> filtered = _query.trim().isEmpty
        ? widget.clients
        : widget.clients
            .where(
              (Client c) =>
                  c.fullName.toLowerCase().contains(_query.toLowerCase()) ||
                  c.phone.toLowerCase().contains(_query.toLowerCase()),
            )
            .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                onChanged: (String v) => setState(() => _query = v),
                autofocus: false,
                decoration: const InputDecoration(
                  hintText: 'Rechercher…',
                  prefixIcon: Icon(Icons.search_rounded),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                controller: controller,
                itemCount: filtered.length,
                itemBuilder: (BuildContext context, int index) {
                  final Client c = filtered[index];
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
