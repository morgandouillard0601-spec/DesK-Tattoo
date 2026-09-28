import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import '../../../core/network/supabase_client.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../profile/data/artist_repository.dart';
import '../domain/auth_user.dart';

/// Hybrid auth: Supabase when configured, otherwise local secure storage.
class AuthRepository {
  AuthRepository(this._storage, this._supabase);

  final SecureStorageService _storage;
  final SupabaseClient? _supabase;

  bool get usesSupabase => _supabase != null;

  Future<bool> hasLocalAccount() async {
    if (usesSupabase) {
      return _supabase!.auth.currentSession != null ||
          await _storage.readAuthEmail() != null;
    }
    final String? email = await _storage.readAuthEmail();
    final String? password = await _storage.readAuthPassword();
    return email != null &&
        email.isNotEmpty &&
        password != null &&
        password.isNotEmpty;
  }

  Future<AuthUser?> restoreSession() async {
    if (usesSupabase) {
      final Session? session = _supabase!.auth.currentSession;
      final User? user = session?.user ?? _supabase.auth.currentUser;
      if (user == null || user.email == null || user.email!.isEmpty) {
        return null;
      }
      return AuthUser(email: user.email!.toLowerCase(), id: user.id);
    }

    final String? token = await _storage.readAuthToken();
    final String? email = await _storage.readAuthEmail();
    if (token == null || token.isEmpty || email == null || email.isEmpty) {
      return null;
    }
    return AuthUser(email: email);
  }

  Future<AuthUser> register({
    required String email,
    required String password,
    Map<String, dynamic>? metadata,
  }) async {
    final String normalized = email.trim().toLowerCase();
    if (normalized.isEmpty || password.length < 6) {
      throw AuthException('Email ou mot de passe invalide (6 caractères min.)');
    }

    if (usesSupabase) {
      final AuthResponse res = await _supabase!.auth.signUp(
        email: normalized,
        password: password,
        data: metadata,
      );
      final User? user = res.user;
      if (user == null) {
        throw AuthException(
          'Compte créé — vérifie ton email si la confirmation est activée.',
        );
      }
      await _storage.writeAuthEmail(normalized);
      return AuthUser(email: normalized, id: user.id);
    }

    await _storage.writeAuthEmail(normalized);
    await _storage.writeAuthPassword(password);
    await _storage.writeAuthToken('local_$normalized');
    await _storage.writePendingRemoteSync(true);
    return AuthUser(email: normalized);
  }

  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    final String normalized = email.trim().toLowerCase();

    if (usesSupabase) {
      try {
        final AuthResponse res = await _supabase!.auth.signInWithPassword(
          email: normalized,
          password: password,
        );
        final User? user = res.user;
        if (user == null || user.email == null) {
          throw AuthException('Email ou mot de passe incorrect.');
        }
        await _storage.writeAuthEmail(normalized);
        await _storage.writeAuthPassword(password);
        await _storage.writeAuthToken('supabase_$normalized');
        return AuthUser(email: user.email!.toLowerCase(), id: user.id);
      } on AuthException {
        rethrow;
      } catch (e) {
        // Compte legacy / offline : si le mdp local (ou legacy) matche, on ouvre
        // une session locale admin même si Supabase Auth n’a pas l’utilisateur.
        final AuthUser? local = await _tryLocalLogin(
          email: normalized,
          password: password,
        );
        if (local != null) return local;
        throw AuthException(_mapSupabaseError(e));
      }
    }

    final AuthUser? local = await _tryLocalLogin(
      email: normalized,
      password: password,
    );
    if (local != null) return local;
    throw AuthException('Email ou mot de passe incorrect.');
  }

  /// Repli hors ligne : seuls les identifiants déjà enregistrés sur l'appareil
  /// ouvrent une session locale.
  Future<AuthUser?> _tryLocalLogin({
    required String email,
    required String password,
  }) async {
    final String? storedEmail = await _storage.readAuthEmail();
    final String? storedPassword = await _storage.readAuthPassword();
    if (storedEmail != email ||
        storedPassword == null ||
        storedPassword != password) {
      return null;
    }

    await _storage.writeAuthToken('local_$email');
    return AuthUser(email: email);
  }

  Future<void> logout() async {
    if (usesSupabase) {
      await _supabase!.auth.signOut();
    }
    await _storage.clearSession();
  }

  /// Migration unique : les versions précédentes connectaient d'office le
  /// compte studio historique sur chaque appareil. Sa session et ses
  /// identifiants sont effacés localement pour qu'aucun autre tatoueur ne
  /// retombe dessus. Le compte lui-même n'est pas modifié.
  Future<void> clearLegacyAutoSession() async {
    final String? storedEmail = await _storage.readAuthEmail();
    final String? sessionEmail =
        _supabase?.auth.currentUser?.email?.toLowerCase();
    if (storedEmail != kLegacyAccountEmail &&
        sessionEmail != kLegacyAccountEmail) {
      return;
    }

    if (usesSupabase) {
      try {
        await _supabase!.auth.signOut();
      } catch (_) {
        // Hors ligne : les identifiants locaux suffisent à couper l'accès.
      }
    }
    await _storage.clearCredentials();
  }

  /// Supprime définitivement le compte et les données du studio.
  ///
  /// Voie principale : l'Edge Function `delete-account` (elle annule aussi
  /// l'abonnement Stripe et purge les contrats stockés). Si elle n'est pas
  /// joignable, on retombe sur la RPC `delete_own_account`. Dans les deux cas
  /// les identifiants locaux sont effacés à la fin.
  Future<void> deleteAccount() async {
    if (usesSupabase && _supabase!.auth.currentUser != null) {
      Object? remoteError;
      try {
        final FunctionResponse res = await _supabase.functions.invoke(
          'delete-account',
          method: HttpMethod.post,
        );
        if (res.status >= 400) {
          remoteError = res.data is Map && (res.data as Map)['error'] != null
              ? (res.data as Map)['error']
              : 'Suppression impossible (${res.status}).';
        }
      } catch (e) {
        remoteError = e;
      }

      if (remoteError != null) {
        try {
          await _supabase.rpc<dynamic>('delete_own_account');
          remoteError = null;
        } catch (e) {
          remoteError = e;
        }
      }

      if (remoteError != null) {
        throw AuthException(
          'Suppression impossible pour le moment. Vérifie ta connexion puis réessaie.',
        );
      }

      try {
        await _supabase.auth.signOut();
      } catch (_) {
        // Le compte n'existe plus : la session locale est de toute façon morte.
      }
    }

    await _storage.clearAll();
  }

  String _mapSupabaseError(Object e) {
    final String msg = e.toString();
    if (msg.contains('Invalid login credentials')) {
      return 'Email ou mot de passe incorrect.';
    }
    if (msg.contains('Email not confirmed')) {
      return 'Confirme ton email avant de te connecter.';
    }
    return 'Une erreur est survenue. Réessaie.';
  }
}

class AuthException implements Exception {
  AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

final Provider<AuthRepository> authRepositoryProvider =
    Provider<AuthRepository>(
  (Ref ref) => AuthRepository(
    ref.watch(secureStorageServiceProvider),
    ref.watch(supabaseClientProvider),
  ),
);
