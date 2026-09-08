import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/notifications/presentation/providers/notifications_provider.dart';
import 'push_notification_service.dart';

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  return PushNotificationService((token) {
    ref.read(notificationsRepositoryProvider).registerDeviceToken(token).catchError((_) {});
  });
});
