import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  const SecureStorageService(this._storage);

  final FlutterSecureStorage _storage;

  static const String _authTokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';

  Future<String?> readAuthToken() => _storage.read(key: _authTokenKey);

  Future<void> writeAuthToken(String token) =>
      _storage.write(key: _authTokenKey, value: token);

  Future<void> deleteAuthToken() => _storage.delete(key: _authTokenKey);

  Future<String?> readRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<void> writeRefreshToken(String token) =>
      _storage.write(key: _refreshTokenKey, value: token);

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
