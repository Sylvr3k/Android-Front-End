import '../../../core/api/api_client.dart';
import '../domain/app_notification.dart';

class NotificationsRepository {
  NotificationsRepository(this._api);

  final ApiClient _api;

  Future<List<AppNotification>> list() async {
    final response = await _api.get('/student/notifications');
    final data = Map<String, dynamic>.from(response['data'] as Map);
    final items = List<Map>.from(data['data'] as List? ?? []);

    return items.map((item) => AppNotification.fromJson(Map<String, dynamic>.from(item))).toList();
  }

  Future<void> markRead(String id) => _api.post('/student/notifications/$id/read');

  Future<void> markAllRead() => _api.post('/student/notifications/mark-all-read');

  Future<void> registerDeviceToken(String token, {String platform = 'android'}) {
    return _api.post('/student/device-token', data: {'token': token, 'platform': platform});
  }

  Future<void> unregisterDeviceToken(String token) {
    return _api.delete('/student/device-token', data: {'token': token});
  }
}
