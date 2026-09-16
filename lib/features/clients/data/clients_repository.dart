import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/artist_scoped_notifier.dart';
import '../domain/client.dart';

class ClientsNotifier extends ArtistScopedNotifier<Client> {
  @override
  String get table => 'clients';

  @override
  String get orderColumn => 'last_name';

  @override
  bool get orderAscending => true;

  @override
  Client fromRow(Map<String, dynamic> row) => Client.fromSupabase(row);

  Client? getById(String id) {
    for (final Client c in items) {
      if (c.id == id) return c;
    }
    return null;
  }

  List<Client> search(String query) {
    if (query.trim().isEmpty) return items;
    final String q = query.toLowerCase();
    return items
        .where(
          (Client c) =>
              c.fullName.toLowerCase().contains(q) ||
              c.phone.toLowerCase().contains(q) ||
              c.email.toLowerCase().contains(q),
        )
        .toList(growable: false);
  }

  Future<void> add(Client client) => insertRow(client.toSupabase());

  /// Nommée `save` et non `update` : `AsyncNotifier` expose déjà `update`.
  Future<void> save(Client client) =>
      updateRow(client.id, client.toSupabase());

  Future<void> delete(String id) => deleteRow(id);
}

final AsyncNotifierProvider<ClientsNotifier, List<Client>> clientsProvider =
    AsyncNotifierProvider<ClientsNotifier, List<Client>>(ClientsNotifier.new);
