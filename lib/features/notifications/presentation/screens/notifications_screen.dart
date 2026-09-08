import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/widgets/state_views.dart';
import '../providers/notifications_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  IconData _iconFor(String type) {
    return switch (type) {
      'evaluation_opened' || 'evaluation_reminder' => Icons.fact_check_rounded,
      'announcement' => Icons.campaign_rounded,
      _ => Icons.notifications_rounded,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () => ref.read(notificationsProvider.notifier).markAllRead(),
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(notificationsProvider.notifier).refresh(),
        child: notifications.when(
          loading: () => const LoadingView(),
          error: (error, _) => ErrorView(
            failure: error is AppFailure ? error : AppFailure.unknown(),
            onRetry: () => ref.read(notificationsProvider.notifier).refresh(),
          ),
          data: (items) {
            if (items.isEmpty) {
              return const EmptyView(
                icon: Icons.notifications_none_rounded,
                title: 'No notifications yet',
                message: 'Evaluation and announcement updates will show up here.',
              );
            }

            return ListView.separated(
              itemCount: items.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = items[index];

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: item.read
                        ? Theme.of(context).colorScheme.surfaceContainerHighest
                        : Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(_iconFor(item.type)),
                  ),
                  title: Text(item.title ?? 'Notification', style: TextStyle(fontWeight: item.read ? FontWeight.normal : FontWeight.bold)),
                  subtitle: Text('${item.body ?? ''}\n${DateFormat.yMMMd().add_jm().format(item.createdAt)}'),
                  isThreeLine: true,
                  onTap: () {
                    if (!item.read) ref.read(notificationsProvider.notifier).markRead(item.id);
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
