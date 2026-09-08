import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/dashboard_summary.dart';
import '../providers/dashboard_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(dashboardProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(dashboardProvider.future),
        child: summary.when(
          loading: () => const LoadingView(),
          error: (error, _) => ErrorView(
            failure: error is AppFailure ? error : AppFailure.unknown(),
            onRetry: () => ref.invalidate(dashboardProvider),
          ),
          data: (data) => _HomeContent(greeting: _greeting(), summary: data),
        ),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({required this.greeting, required this.summary});

  final String greeting;
  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('$greeting, ${summary.studentName.split(' ').first}', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(
          [
            if (summary.levelName != null && summary.programName != null) '${summary.levelName} in ${summary.programName}',
            if (summary.intakeName != null) '${summary.intakeName} Intake',
          ].join(' · '),
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Trainer Evaluations', style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  summary.pendingEvaluations == 0
                      ? 'You have no pending evaluations.'
                      : '${summary.pendingEvaluations} Pending',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
                ),
                if (summary.pendingEvaluations > 0) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => context.go('/evaluations'),
                      child: const Text('Start Evaluation'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text('Announcements', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (summary.announcements.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text('No announcements right now.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline)),
            ),
          )
        else
          ...summary.announcements.map(
            (announcement) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(announcement.title, style: theme.textTheme.titleSmall),
                      const SizedBox(height: 4),
                      Text(announcement.message, style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: 20),
        Text('Recent Activity', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (summary.recentActivity.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text('No submitted evaluations yet.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline)),
            ),
          )
        else
          Card(
            child: Column(
              children: summary.recentActivity
                  .map(
                    (activity) => ListTile(
                      leading: Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary),
                      title: Text(activity.unit),
                      subtitle: Text('Evaluation submitted · ${DateFormat.yMMMd().format(activity.submittedAt)}'),
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }
}
