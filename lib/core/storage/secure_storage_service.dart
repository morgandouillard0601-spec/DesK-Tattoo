import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  const SecureStorageService(this._storage);

  final FlutterSecureStorage _storage;

  static const String _authTokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _authEmailKey = 'auth_email';
  static const String _authPasswordKey = 'auth_password';
  static const String _pendingRemoteSyncKey = 'auth_pending_remote_sync';

  Future<String?> readAuthToken() => _storage.read(key: _authTokenKey);

  Future<void> writeAuthToken(String token) =>
      _storage.write(key: _authTokenKey, value: token);

  Future<void> deleteAuthToken() => _storage.delete(key: _authTokenKey);

  Future<String?> readRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<void> writeRefreshToken(String token) =>
      _storage.write(key: _refreshTokenKey, value: token);

  Future<String?> readAuthEmail() => _storage.read(key: _authEmailKey);

  Future<void> writeAuthEmail(String email) =>
      _storage.write(key: _authEmailKey, value: email);

  Future<String?> readAuthPassword() => _storage.read(key: _authPasswordKey);

  Future<void> writeAuthPassword(String password) =>
      _storage.write(key: _authPasswordKey, value: password);

  Future<bool> readPendingRemoteSync() async {
    final String? value = await _storage.read(key: _pendingRemoteSyncKey);
    return value == '1';
  }

  Future<void> writePendingRemoteSync(bool pending) => _storage.write(
        key: _pendingRemoteSyncKey,
        value: pending ? '1' : '0',
      );

  Future<void> clearSession() async {
    await deleteAuthToken();
    await _storage.delete(key: _refreshTokenKey);
  }

  Future<void> clearCredentials() async {
    await clearSession();
    await _storage.delete(key: _authEmailKey);
    await _storage.delete(key: _authPasswordKey);
    await _storage.delete(key: _pendingRemoteSyncKey);
  }

  Future<void> clearAll() => _storage.deleteAll();
}

final Provider<FlutterSecureStorage> flutterSecureStorageProvider =
    Provider<FlutterSecureStorage>(
  (Ref ref) => const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  ),
);

final Provider<SecureStorageService> secureStorageServiceProvider =
    Provider<SecureStorageService>(
  (Ref ref) =>
      SecureStorageService(ref.watch(flutterSecureStorageProvider)),
);
