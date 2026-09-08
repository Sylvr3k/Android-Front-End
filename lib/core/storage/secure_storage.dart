import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Thin wrapper around encrypted on-device storage. This is the only place
/// the authentication token touches disk — it is never written to
/// SharedPreferences or any other plaintext-accessible store.
class SecureStorage {
  SecureStorage()
    : _storage = const FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
      );

  final FlutterSecureStorage _storage;

  static const _tokenKey = 'auth_token';

  Future<void> saveToken(String token) => _storage.write(key: _tokenKey, value: token);

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<void> clearToken() => _storage.delete(key: _tokenKey);
}
