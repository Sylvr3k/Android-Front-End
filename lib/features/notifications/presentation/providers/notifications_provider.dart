import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers.dart';
import '../../data/notifications_repository.dart';
import '../../domain/app_notification.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  return NotificationsRepository(ref.watch(apiClientProvider));
});

// autoDispose: stays alive for as long as the authenticated shell (bottom
// nav + its unread badge) is on screen, but is torn down and rebuilt fresh
// on the next login instead of being stuck showing a stale error/empty
// state forever if it ever built while signed out.
final notificationsProvider = AsyncNotifierProvider.autoDispose<NotificationsController, List<AppNotification>>(
  NotificationsController.new,
);

final unreadNotificationsCountProvider = Provider.autoDispose<int>((ref) {
  return ref.watch(notificationsProvider).valueOrNull?.where((n) => !n.read).length ?? 0;
});

class NotificationsController extends AutoDisposeAsyncNotifier<List<AppNotification>> {
  @override
  Future<List<AppNotification>> build() {
    return ref.read(notificationsRepositoryProvider).list();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(notificationsRepositoryProvider).list());
  }

  Future<void> markRead(String id) async {
    await ref.read(notificationsRepositoryProvider).markRead(id);

    state = state.whenData((items) => [
      for (final item in items)
        if (item.id == id)
          AppNotification(
            id: item.id,
            type: item.type,
            title: item.title,
            body: item.body,
            read: true,
            createdAt: item.createdAt,
            data: item.data,
          )
        else
          item,
    ]);
  }

  Future<void> markAllRead() async {
    await ref.read(notificationsRepositoryProvider).markAllRead();
    await refresh();
  }
}
