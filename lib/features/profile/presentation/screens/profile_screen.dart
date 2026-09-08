import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../authentication/presentation/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    final theme = Theme.of(context);

    if (user == null) return const SizedBox.shrink();

    final photoUrl = user.student?.photoUrl;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: theme.colorScheme.primaryContainer,
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
            child: photoUrl == null
                ? Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: theme.textTheme.headlineMedium,
                  )
                : null,
          ),
          const SizedBox(height: 12),
          Text(user.name, style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
          Text(user.email, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          if (user.student != null) ...[
            Card(
              child: Column(
                children: [
                  ListTile(leading: const Icon(Icons.badge_outlined), title: const Text('Admission Number'), trailing: Text(user.student!.admissionNumber)),
                  const Divider(height: 1),
                  ListTile(leading: const Icon(Icons.school_outlined), title: const Text('Program'), trailing: Text(user.student!.programName ?? '—')),
                  const Divider(height: 1),
                  ListTile(leading: const Icon(Icons.stairs_outlined), title: const Text('Level'), trailing: Text(user.student!.levelName ?? '—')),
                  const Divider(height: 1),
                  ListTile(leading: const Icon(Icons.event_outlined), title: const Text('Intake'), trailing: Text(user.student!.intakeName ?? '—')),
                  const Divider(height: 1),
                  ListTile(leading: const Icon(Icons.phone_outlined), title: const Text('Phone'), trailing: Text(user.student!.phone ?? '—')),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('Edit Profile'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/profile/edit'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: const Text('Change Password'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/profile/change-password'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
