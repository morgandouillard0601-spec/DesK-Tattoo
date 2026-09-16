import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_client.dart';
import '../domain/client_consent.dart';

/// Lecture des contrats signés. Le RLS limite déjà chaque tatoueur à ses
/// propres lignes et à son dossier dans le bucket `consents`.
class ConsentsRepository {
  ConsentsRepository(this._client);

  final SupabaseClient? _client;

  bool get isAvailable => _client != null;

  Future<List<ClientConsent>> forClient(String clientId) async {
    final SupabaseClient? client = _client;
    if (client == null || clientId.isEmpty) return const <ClientConsent>[];

    final List<dynamic> rows = await client
        .from('client_consents')
        .select()
        .eq('client_id', clientId)
        .order('signed_at', ascending: false);

    return rows
        .map(
          (dynamic row) =>
              ClientConsent.fromSupabase(row as Map<String, dynamic>),
        )
        .toList(growable: false);
  }

  /// Télécharge le PDF archivé pour aperçu ou partage.
  Future<Uint8List> downloadPdf(String path) async {
    final SupabaseClient? client = _client;
    if (client == null) {
      throw StateError('Supabase non configuré');
    }
    return client.storage.from('consents').download(path);
  }

  /// URL temporaire, utile pour ouvrir le document hors de l'app.
  Future<String> signedUrl(String path, {int expiresInSeconds = 300}) {
    final SupabaseClient? client = _client;
    if (client == null) {
      throw StateError('Supabase non configuré');
    }
    return client.storage
        .from('consents')
        .createSignedUrl(path, expiresInSeconds);
  }
}

final Provider<ConsentsRepository> consentsRepositoryProvider =
    Provider<ConsentsRepository>(
  (Ref ref) => ConsentsRepository(ref.watch(supabaseClientProvider)),
);

/// Contrats signés d'un client donné.
final FutureProviderFamily<List<ClientConsent>, String> clientConsentsProvider =
    FutureProvider.family<List<ClientConsent>, String>(
  (Ref ref, String clientId) =>
      ref.watch(consentsRepositoryProvider).forClient(clientId),
);
