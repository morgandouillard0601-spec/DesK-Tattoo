import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/secure_storage_service.dart';
import '../domain/auth_user.dart';

/// Local-first auth. Credentials are stored in secure storage for now.
/// When the remote database / API is ready, [syncPendingToRemote] will push
/// any account marked as pending so nothing is lost from the static phase.
class AuthRepository {
  AuthRepository(this._storage);

  final SecureStorageService _storage;

  Future<bool> hasLocalAccount() async {
    final String? email = await _storage.readAuthEmail();
    final String? password = await _storage.readAuthPassword();
    return email != null &&
        email.isNotEmpty &&
        password != null &&
        password.isNotEmpty;
  }

  Future<AuthUser?> restoreSession() async {
    final String? token = await _storage.readAuthToken();
    final String? email = await _storage.readAuthEmail();
    if (token == null || token.isEmpty || email == null || email.isEmpty) {
      return null;
    }
    await syncPendingToRemote();
    return AuthUser(email: email);
  }

  Future<AuthUser> register({
    required String email,
    required String password,
  }) async {
    final String normalized = email.trim().toLowerCase();
    if (normalized.isEmpty || password.length < 6) {
      throw AuthException('Email ou mot de passe invalide (6 caractères min.)');
    }

    // Local single-device account: creating a new one replaces previous credentials.
    await _storage.writeAuthEmail(normalized);
    await _storage.writeAuthPassword(password);
    await _storage.writeAuthToken('local_$normalized');
    await _storage.writePendingRemoteSync(true);

    await syncPendingToRemote();

    return AuthUser(email: normalized);
  }

  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    final String normalized = email.trim().toLowerCase();
    final String? storedEmail = await _storage.readAuthEmail();
    final String? storedPassword = await _storage.readAuthPassword();

    if (storedEmail == null || storedPassword == null) {
      throw AuthException('Aucun compte. Crée d\'abord un compte.');
    }
    if (normalized != storedEmail || password != storedPassword) {
      throw AuthException('Email ou mot de passe incorrect.');
    }

    await _storage.writeAuthToken('local_$normalized');
    await syncPendingToRemote();
    return AuthUser(email: normalized);
  }

  Future<void> logout() async {
    await _storage.clearSession();
  }

  /// Garantit le compte local historique (profil studio déjà inscrit).
  Future<void> ensureLegacyAccount({
    required String email,
    required String password,
  }) async {
    final String normalized = email.trim().toLowerCase();
    final String? existingEmail = await _storage.readAuthEmail();
    final String? existingPassword = await _storage.readAuthPassword();

    // Ne remplace un autre compte que s’il n’y a pas encore d’identifiants.
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

  /// Pushes pending local credentials to the remote DB when available.
  /// Currently a no-op until the API is wired; keeps the pending flag so
  /// the next launch / login retries automatically.
  Future<bool> syncPendingToRemote() async {
    final bool pending = await _storage.readPendingRemoteSync();
    if (!pending) return true;

    final String? email = await _storage.readAuthEmail();
    final String? password = await _storage.readAuthPassword();
    if (email == null || password == null) {
      await _storage.writePendingRemoteSync(false);
      return true;
    }

    final bool synced = await _tryRemoteUpsert(
      email: email,
      password: password,
    );
    if (synced) {
      await _storage.writePendingRemoteSync(false);
    }
    return synced;
  }

  /// Hook for the future database / Auth API.
  /// Return `true` when the remote write succeeds.
  Future<bool> _tryRemoteUpsert({
    required String email,
    required String password,
  }) async {
    // TODO(auth-remote): call API / DB upsert when backend is ready.
    // Example:
    // await dio.post('/auth/register', data: {'email': email, 'password': password});
    return false;
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
  (Ref ref) => AuthRepository(ref.watch(secureStorageServiceProvider)),
);
