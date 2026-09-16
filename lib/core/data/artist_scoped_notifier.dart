import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../network/supabase_client.dart';

/// Socle commun aux modules métier stockés dans Supabase.
///
/// Chaque table porte une colonne `artist_id` et le RLS limite déjà l'accès au
/// propriétaire ; on filtre malgré tout côté requête pour rester explicite.
///
/// Sans session Supabase (compte local de secours), les listes sont vides
/// plutôt qu'en erreur : les écrans affichent alors leur état vide habituel.
abstract class ArtistScopedNotifier<T> extends AsyncNotifier<List<T>> {
  /// Table Postgres correspondante.
  String get table;

  /// Colonne utilisée pour le tri par défaut.
  String get orderColumn;

  bool get orderAscending => false;

  /// Conversion d'une ligne Supabase vers le modèle de domaine.
  T fromRow(Map<String, dynamic> row);

  SupabaseClient? get client => ref.read(supabaseClientProvider);

  /// `artists.id` est l'identifiant du compte Auth.
  String? get artistId => client?.auth.currentUser?.id;

  bool get isRemoteAvailable => client != null && artistId != null;

  /// Données déjà chargées, pratiques pour les helpers synchrones appelés
  /// depuis les écrans.
  List<T> get items => state.valueOrNull ?? <T>[];

  @override
  Future<List<T>> build() => load();

  Future<List<T>> load() async {
    final SupabaseClient? db = client;
    final String? id = artistId;
    if (db == null || id == null) return <T>[];

    final List<dynamic> rows = await db
        .from(table)
        .select()
        .eq('artist_id', id)
        .order(orderColumn, ascending: orderAscending);

    return rows
        .map((dynamic row) => fromRow(row as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<void> refresh() async {
    state = AsyncValue<List<T>>.data(await load());
  }

  Future<void> insertRow(Map<String, dynamic> values) async {
    final SupabaseClient? db = client;
    final String? id = artistId;
    if (db == null || id == null) {
      throw StateError('Aucune session Supabase active');
    }
    await db.from(table).insert(<String, dynamic>{
      ...values,
      'artist_id': id,
    });
    await refresh();
  }

  Future<void> updateRow(String rowId, Map<String, dynamic> values) async {
    final SupabaseClient? db = client;
    final String? id = artistId;
    if (db == null || id == null) {
      throw StateError('Aucune session Supabase active');
    }
    await db.from(table).update(values).eq('id', rowId).eq('artist_id', id);
    await refresh();
  }

  Future<void> deleteRow(String rowId) async {
    final SupabaseClient? db = client;
    final String? id = artistId;
    if (db == null || id == null) {
      throw StateError('Aucune session Supabase active');
    }
    await db.from(table).delete().eq('id', rowId).eq('artist_id', id);
    await refresh();
  }
}

/// Helpers de lecture tolérants aux types renvoyés par PostgREST
/// (`numeric` arrive en `String` ou `num` selon les cas).
double readDouble(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int readInt(Object? value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime? readDate(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}

String readString(Object? value) => value?.toString() ?? '';
