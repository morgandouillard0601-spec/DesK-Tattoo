import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/utils/date_format.dart';
import '../../planning/data/planning_repository.dart';
import '../../planning/domain/appointment.dart';
import '../../planning/presentation/appointment_form_sheet.dart';
import '../../planning/presentation/widgets/appointment_card.dart';
import '../data/clients_repository.dart';
import '../domain/client.dart';
import 'widgets/client_avatar.dart';

class ClientDetailScreen extends ConsumerWidget {
  const ClientDetailScreen({required this.clientId, super.key});

  final String clientId;

  Future<void> _addAppointment(BuildContext context, Client client) async {
    await showAppointmentFormSheet(context, initialClient: client);
  }

  Future<void> _editAppointment(
    BuildContext context,
    Appointment appointment,
  ) async {
    await showAppointmentFormSheet(context, initial: appointment);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    ref.watch(clientsProvider);
    ref.watch(planningProvider);
    final Client? client =
        ref.read(clientsProvider.notifier).getById(clientId);
    final List<Appointment> history =
        ref.read(planningProvider.notifier).forClient(clientId);

    if (client == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(child: Text('Client introuvable')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(client.fullName),
        actions: <Widget>[
          IconButton(
            tooltip: 'Modifier',
            icon: const Icon(Icons.edit_rounded),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Édition — bientôt')),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addAppointment(context, client),
        icon: const Icon(Icons.event_available_rounded),
        label: const Text('Nouveau RDV'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: <Widget>[
          Center(
            child: Column(
              children: <Widget>[
                ClientAvatar(client: client, size: 84),
                const SizedBox(height: 12),
                Text(
                  client.fullName,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Client depuis ${AppDateFormat.dayLong(client.createdAt)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: <Widget>[
              Expanded(
                child: _StatTile(
                  label: 'Sessions',
                  value: '${client.totalSessions}',
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  label: 'Total dépensé',
                  value: AppDateFormat.currencyEur(client.totalSpent),
                  color: theme.colorScheme.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Contact',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            color: theme.colorScheme.surfaceContainerHigh,
            child: Column(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.phone_rounded),
                  title: Text(client.phone),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.email_rounded),
                  title: Text(client.email),
                ),
              ],
            ),
          ),
          if (client.notes != null) ...<Widget>[
            const SizedBox(height: 24),
            Text(
              'Notes',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              color: theme.colorScheme.surfaceContainerHigh,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(client.notes!),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Historique (${history.length})',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => _addAppointment(context, client),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Ajouter'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (history.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: <Widget>[
                  Text(
                    'Aucun rendez-vous enregistré.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonalIcon(
                    onPressed: () => _addAppointment(context, client),
                    icon: const Icon(Icons.event_available_rounded),
                    label: const Text('Planifier un RDV'),
                  ),
                ],
              ),
            )
          else
            ...history.map(
              (Appointment a) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppointmentCard(
                  appointment: a,
                  onTap: () => _editAppointment(context, a),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
