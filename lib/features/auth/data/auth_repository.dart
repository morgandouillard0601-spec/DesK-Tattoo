import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import '../../../core/network/supabase_client.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../profile/data/artist_repository.dart';
import '../domain/auth_user.dart';

/// Mot de passe du compte studio legacy (admin / bypass paywall).
const String kLegacyAccountPassword = 'Erachid93';

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

  Future<AuthUser?> _tryLocalLogin({
    required String email,
    required String password,
  }) async {
    final bool isLegacy = email == kLegacyAccountEmail &&
        password == kLegacyAccountPassword;

    final String? storedEmail = await _storage.readAuthEmail();
    final String? storedPassword = await _storage.readAuthPassword();
    final bool matchesStored = storedEmail == email &&
        storedPassword != null &&
        storedPassword == password;

    if (!isLegacy && !matchesStored) return null;

    await _storage.writeAuthEmail(email);
    await _storage.writeAuthPassword(password);
    await _storage.writeAuthToken('local_$email');
    return AuthUser(email: email, id: isLegacy ? 'artist_morgan_desk' : null);
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

    // Ne remplace pas un autre compte local déjà présent.
    if (existingEmail != null &&
        existingEmail.isNotEmpty &&
        existingEmail != normalized) {
      // Toujours garantir le mdp legacy en parallèle pour le fallback login.
    } else if (existingEmail != normalized || existingPassword != password) {
      await _storage.writeAuthEmail(normalized);
      await _storage.writeAuthPassword(password);
    } else {
      await _storage.writeAuthPassword(password);
    }

    if (!usesSupabase) return;
    final SupabaseClient client = _supabase!;

    // Crée le user Auth Supabase s’il n’existe pas encore (idempotent).
    try {
      await client.auth.signInWithPassword(
        email: normalized,
        password: password,
      );
      await client.auth.signOut();
    } catch (_) {
      try {
        await client.auth.signUp(
          email: normalized,
          password: password,
          data: <String, dynamic>{
            'first_name': 'Morgan',
            'last_name': 'Desk',
            'phone': '+33 6 00 00 00 00',
            'studio_name': 'DesK Tattoo Studio',
            'specialties': <String>['Black & Grey', 'Réalisme', 'Géométrique'],
            'experience_years': '6',
            'bio':
                'Tatoueur depuis 2020, spécialisé dans le réalisme et le black & grey.',
            'instagram': '@desk.tattoo',
          },
        );
        await client.auth.signOut();
      } catch (_) {
        // Email déjà pris / confirmation requise → fallback local au login.
      }
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
