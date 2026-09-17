import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/utils/date_format.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../consents/data/consents_repository.dart';
import '../data/clients_repository.dart';
import '../domain/client.dart';
import 'client_form_sheet.dart';
import 'widgets/client_avatar.dart';

class ClientsScreen extends ConsumerStatefulWidget {
  const ClientsScreen({super.key});

  @override
  ConsumerState<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends ConsumerState<ClientsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Client>> clientsAsync = ref.watch(clientsProvider);
    final Map<String, DateTime> latestConsents =
        ref.watch(latestConsentDatesProvider).value ?? const <String, DateTime>{};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientèle'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Actualiser',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.read(clientsProvider.notifier).refresh();
              ref.invalidate(latestConsentDatesProvider);
            },
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                onChanged: (String v) => setState(() => _query = v),
                decoration: const InputDecoration(
                  hintText: 'Rechercher un client…',
                  prefixIcon: Icon(Icons.search_rounded),
                  isDense: true,
                ),
              ),
            ),
          ),
          ...switch (clientsAsync) {
            AsyncLoading<List<Client>>() => <Widget>[
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
            AsyncError<List<Client>>() => <Widget>[
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: Icons.cloud_off_rounded,
                    title: 'Clients indisponibles',
                    message:
                        'Impossible de charger la clientèle. Vérifie ta connexion.',
                  ),
                ),
              ],
            AsyncValue<List<Client>>(value: final List<Client>? all) =>
              _buildList(all ?? const <Client>[], latestConsents),
          },
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createClient,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Client'),
      ),
    );
  }

  List<Widget> _buildList(
    List<Client> all,
    Map<String, DateTime> latestConsents,
  ) {
    final String q = _query.trim().toLowerCase();
    final List<Client> clients = q.isEmpty
        ? List<Client>.from(all)
        : all
            .where(
              (Client c) =>
                  c.fullName.toLowerCase().contains(q) ||
                  c.phone.toLowerCase().contains(q) ||
                  c.email.toLowerCase().contains(q),
            )
            .toList();
    clients.sort((Client a, Client b) => a.lastName.compareTo(b.lastName));

    if (clients.isEmpty) {
      return <Widget>[
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyState(
            icon: Icons.person_search_rounded,
            title: all.isEmpty ? 'Aucun client' : 'Aucun résultat',
            message: all.isEmpty
                ? 'Ajoute un client, ou fais scanner ton QR fiche client.'
                : 'Aucun résultat ne correspond à ta recherche.',
          ),
        ),
      ];
    }

    return <Widget>[
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        sliver: SliverList.separated(
          itemCount: clients.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (BuildContext context, int index) => _ClientTile(
            client: clients[index],
            lastConsentAt: latestConsents[clients[index].id],
          ),
        ),
      ),
    ];
  }

  Future<void> _createClient() async {
    final Client? created = await showClientFormSheet(context);
    if (!mounted) return;
    if (created != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Client ajouté · ${created.fullName}')),
      );
    }
  }
}

class _ClientTile extends StatelessWidget {
  const _ClientTile({
    required this.client,
    this.lastConsentAt,
  });

  final Client client;
  final DateTime? lastConsentAt;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String lastVisit = client.lastVisit == null
        ? 'Aucune visite'
        : 'Dernière : ${AppDateFormat.relativeDay(client.lastVisit!)}';

    return Card(
      color: theme.colorScheme.surfaceContainerHigh,
      child: ListTile(
        isThreeLine: lastConsentAt != null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: ClientAvatar(client: client),
        title: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                client.fullName,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (client.isFromIntake)
              Tooltip(
                message: 'Fiche remplie par le client',
                child: Icon(
                  Icons.qr_code_2_rounded,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 2),
            Text(
              client.phone,
              style: theme.textTheme.bodySmall,
            ),
            Text(
              lastVisit,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (lastConsentAt != null)
              Text(
                'Décharge · ${AppDateFormat.relativeDay(lastConsentAt!)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Text(
              '${client.totalSessions} session${client.totalSessions > 1 ? 's' : ''}',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              AppDateFormat.currencyEur(client.totalSpent),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        onTap: () =>
            context.goNamed('client-detail', pathParameters: <String, String>{
          'id': client.id,
        }),
      ),
    );
  }
}
