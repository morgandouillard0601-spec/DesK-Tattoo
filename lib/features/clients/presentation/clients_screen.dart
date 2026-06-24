import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/utils/date_format.dart';
import '../../../shared/widgets/empty_state.dart';
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
    final List<Client> all = ref.watch(clientsProvider);
    final List<Client> clients = _query.trim().isEmpty
        ? List<Client>.from(all)
        : all
            .where(
              (Client c) =>
                  c.fullName.toLowerCase().contains(_query.toLowerCase()) ||
                  c.phone.toLowerCase().contains(_query.toLowerCase()) ||
                  c.email.toLowerCase().contains(_query.toLowerCase()),
            )
            .toList();
    clients.sort((Client a, Client b) => a.lastName.compareTo(b.lastName));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientèle'),
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
          if (clients.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: Icons.person_search_rounded,
                title: 'Aucun client',
                message: 'Aucun résultat ne correspond à ta recherche.',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: SliverList.separated(
                itemCount: clients.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (BuildContext context, int index) =>
                    _ClientTile(client: clients[index]),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createClient,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Client'),
      ),
    );
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
  const _ClientTile({required this.client});

  final Client client;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String lastVisit = client.lastVisit == null
        ? 'Aucune visite'
        : 'Dernière : ${AppDateFormat.relativeDay(client.lastVisit!)}';

    return Card(
      color: theme.colorScheme.surfaceContainerHigh,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: ClientAvatar(client: client),
        title: Text(
          client.fullName,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
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
