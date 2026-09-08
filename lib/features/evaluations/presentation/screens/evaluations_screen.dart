import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/evaluation_assignment.dart';
import '../providers/evaluations_provider.dart';

class EvaluationsScreen extends ConsumerWidget {
  const EvaluationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final evaluations = ref.watch(evaluationsListProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Your Evaluations'),
          bottom: const TabBar(tabs: [Tab(text: 'Current'), Tab(text: 'History')]),
        ),
        body: TabBarView(
          children: [
            RefreshIndicator(
              onRefresh: () => ref.read(evaluationsListProvider.notifier).refresh(),
              child: evaluations.when(
                loading: () => const LoadingView(),
                error: (error, _) => ErrorView(
                  failure: error is AppFailure ? error : AppFailure.unknown(),
                  onRetry: () => ref.read(evaluationsListProvider.notifier).refresh(),
                ),
                data: (items) => _CurrentEvaluationsList(items: items),
              ),
            ),
            const _HistoryTab(),
          ],
        ),
      ),
    );
  }
}

class _CurrentEvaluationsList extends StatelessWidget {
  const _CurrentEvaluationsList({required this.items});

  final List<EvaluationAssignment> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const EmptyView(
        icon: Icons.fact_check_outlined,
        title: 'No evaluations right now',
        message: 'Check back once your trainers and units for the current term are confirmed.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _EvaluationCard(item: items[index]),
    );
  }
}

class _EvaluationCard extends StatelessWidget {
  const _EvaluationCard({required this.item});

  final EvaluationAssignment item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.unit.name, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(item.trainer.name, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline)),
                  const SizedBox(height: 8),
                  if (item.isPending)
                    Chip(
                      label: const Text('Evaluation Pending'),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: theme.colorScheme.tertiaryContainer,
                      side: BorderSide.none,
                    )
                  else
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded, size: 16, color: theme.colorScheme.primary),
                        const SizedBox(width: 6),
                        Text('Completed', style: theme.textTheme.bodySmall),
                      ],
                    ),
                ],
              ),
            ),
            if (item.isPending)
              FilledButton(
                onPressed: () => context.push('/evaluations/wizard', extra: item.toPending()),
                child: const Text('Evaluate'),
              ),
          ],
        ),
      ),
    );
  }
}

class _HistoryTab extends ConsumerWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(evaluationHistoryProvider);

    return history.when(
      loading: () => const LoadingView(),
      error: (error, _) => ErrorView(
        failure: error is AppFailure ? error : AppFailure.unknown(),
        onRetry: () => ref.invalidate(evaluationHistoryProvider),
      ),
      data: (items) {
        if (items.isEmpty) {
          return const EmptyView(
            icon: Icons.history_rounded,
            title: 'No evaluation history yet',
            message: 'Evaluations from closed terms will appear here.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _EvaluationCard(item: items[index]),
        );
      },
    );
  }
}
