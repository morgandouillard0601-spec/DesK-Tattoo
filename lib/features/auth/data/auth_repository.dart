import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import '../../../core/network/supabase_client.dart';
import '../../../core/storage/secure_storage_service.dart';
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
        return AuthUser(email: user.email!.toLowerCase(), id: user.id);
      } on AuthException {
        rethrow;
      } catch (e) {
        throw AuthException(_mapSupabaseError(e));
      }
    }

    final String? storedEmail = await _storage.readAuthEmail();
    final String? storedPassword = await _storage.readAuthPassword();

    if (storedEmail == null || storedPassword == null) {
      throw AuthException('Aucun compte. Crée d\'abord un compte.');
    }
    if (normalized != storedEmail || password != storedPassword) {
      throw AuthException('Email ou mot de passe incorrect.');
    }

    await _storage.writeAuthToken('local_$normalized');
    return AuthUser(email: normalized);
  }

  Future<void> logout() async {
    if (usesSupabase) {
      await _supabase!.auth.signOut();
    }
    await _storage.clearSession();
  }

  Future<void> ensureLegacyAccount({
    required String email,
    required String password,
  }) async {
    final String normalized = email.trim().toLowerCase();
    final String? existingEmail = await _storage.readAuthEmail();
    final String? existingPassword = await _storage.readAuthPassword();

    if (existingEmail != null &&
        existingEmail.isNotEmpty &&
        existingEmail != normalized) {
      return;
    }

    if (existingEmail != normalized || existingPassword != password) {
      await _storage.writeAuthEmail(normalized);
      await _storage.writeAuthPassword(password);
    }
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
