import '../../../core/api/api_client.dart';
import '../../../core/storage/secure_storage.dart';
import '../domain/app_user.dart';

class AuthRepository {
  AuthRepository(this._api, this._storage);

  final ApiClient _api;
  final SecureStorage _storage;

  Future<AppUser> login({required String login, required String password}) async {
    final response = await _api.post('/auth/login', data: {
      'login': login,
      'password': password,
      'device_name': 'flutter-android',
    });

    final data = Map<String, dynamic>.from(response['data'] as Map);
    final token = data['token'] as String;

    await _storage.saveToken(token);

    return AppUser.fromJson(Map<String, dynamic>.from(data['user'] as Map));
  }

  Future<AppUser?> currentUser() async {
    final token = await _storage.readToken();
    if (token == null) return null;

    final response = await _api.get('/me');
    return AppUser.fromJson(Map<String, dynamic>.from(response['data'] as Map));
  }

  Future<void> logout() async {
    try {
      await _api.post('/auth/logout');
    } finally {
      await _storage.clearToken();
    }
  }

  Future<void> forgotPassword(String login) {
    return _api.post('/auth/forgot-password', data: {'login': login});
  }

  Future<void> changePassword({required String currentPassword, required String password}) {
    return _api.put('/me/password', data: {
      'current_password': currentPassword,
      'password': password,
      'password_confirmation': password,
    });
  }

  Future<void> clearSession() => _storage.clearToken();
}
