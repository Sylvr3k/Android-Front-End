import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/widgets/state_views.dart';
import '../../data/evaluations_repository.dart';
import '../../domain/evaluation_assignment.dart';
import '../providers/evaluations_provider.dart';
import '../widgets/rating_selector.dart';

/// The full multi-step evaluation flow: trainer/unit intro, rating
/// questions grouped by category, written feedback + anonymity, a review
/// screen, and a confirmation state after submission.
class EvaluationWizardScreen extends ConsumerStatefulWidget {
  const EvaluationWizardScreen({super.key, required this.pending});

  final PendingEvaluation pending;

  @override
  ConsumerState<EvaluationWizardScreen> createState() => _EvaluationWizardScreenState();
}

class _EvaluationWizardScreenState extends ConsumerState<EvaluationWizardScreen> {
  final _pageController = PageController();
  int _step = 0;
  bool _submitting = false;
  bool _submitted = false;
  String? _submitError;

  final Map<int, int> _ratings = {};
  bool _anonymous = false;
  final _positiveController = TextEditingController();
  final _improvementController = TextEditingController();
  final _additionalController = TextEditingController();

  @override
  void dispose() {
    _pageController.dispose();
    _positiveController.dispose();
    _improvementController.dispose();
    _additionalController.dispose();
    super.dispose();
  }

  void _goTo(int step) {
    setState(() => _step = step);
    _pageController.animateToPage(step, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  bool _allQuestionsAnswered(List<QuestionCategory> categories) {
    final allQuestionIds = categories.expand((c) => c.questions).map((q) => q.id);
    return allQuestionIds.every(_ratings.containsKey);
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _submitError = null;
    });

    try {
      await ref.read(evaluationsRepositoryProvider).submit(
            pending: widget.pending,
            anonymous: _anonymous,
            answers: _ratings.entries.map((e) => EvaluationAnswerInput(questionId: e.key, rating: e.value)).toList(),
            positiveFeedback: _positiveController.text.trim().isEmpty ? null : _positiveController.text.trim(),
            improvementFeedback: _improvementController.text.trim().isEmpty ? null : _improvementController.text.trim(),
            additionalComments: _additionalController.text.trim().isEmpty ? null : _additionalController.text.trim(),
          );

      ref.invalidate(evaluationsListProvider);

      setState(() => _submitted = true);
    } on AppFailure catch (e) {
      setState(() => _submitError = e.message);
    } finally {
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return _ConfirmationView(onDone: () => context.pop());
    }

    final questionnaire = ref.watch(evaluationQuestionnaireProvider(widget.pending));

    return Scaffold(
      appBar: AppBar(title: Text(widget.pending.trainer.name)),
      body: questionnaire.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          failure: error is AppFailure ? error : AppFailure.unknown(),
          onRetry: () => ref.invalidate(evaluationQuestionnaireProvider(widget.pending)),
        ),
        data: (detail) {
          final steps = ['Trainer', 'Questions', 'Feedback', 'Review'];

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: LinearProgressIndicator(value: (_step + 1) / steps.length),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _IntroStep(pending: widget.pending, onContinue: () => _goTo(1)),
                    _QuestionsStep(
                      categories: detail.categories,
                      ratings: _ratings,
                      onRate: (id, rating) => setState(() => _ratings[id] = rating),
                      onContinue: _allQuestionsAnswered(detail.categories) ? () => _goTo(2) : null,
                      onBack: () => _goTo(0),
                    ),
                    _FeedbackStep(
                      anonymous: _anonymous,
                      onAnonymousChanged: (v) => setState(() => _anonymous = v),
                      positiveController: _positiveController,
                      improvementController: _improvementController,
                      additionalController: _additionalController,
                      onContinue: () => _goTo(3),
                      onBack: () => _goTo(1),
                    ),
                    _ReviewStep(
                      pending: widget.pending,
                      categories: detail.categories,
                      ratings: _ratings,
                      anonymous: _anonymous,
                      submitting: _submitting,
                      error: _submitError,
                      onSubmit: _submit,
                      onBack: () => _goTo(2),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _IntroStep extends StatelessWidget {
  const _IntroStep({required this.pending, required this.onContinue});

  final PendingEvaluation pending;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          Icon(Icons.school_rounded, size: 64, color: theme.colorScheme.primary),
          const SizedBox(height: 24),
          Text('Trainer', style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.outline)),
          Text(pending.trainer.name, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Text('Unit', style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.outline)),
          Text(pending.unit.name, style: theme.textTheme.titleLarge),
          const Spacer(),
          FilledButton(onPressed: onContinue, child: const Text('Continue')),
        ],
      ),
    );
  }
}

class _QuestionsStep extends StatelessWidget {
  const _QuestionsStep({
    required this.categories,
    required this.ratings,
    required this.onRate,
    required this.onContinue,
    required this.onBack,
  });

  final List<QuestionCategory> categories;
  final Map<int, int> ratings;
  final void Function(int questionId, int rating) onRate;
  final VoidCallback? onContinue;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text('Rate Your Trainer', style: theme.textTheme.titleLarge),
              Text('1 = Very Poor · 5 = Excellent', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
              const SizedBox(height: 12),
              for (final category in categories) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 6),
                  child: Text(category.name, style: theme.textTheme.titleMedium),
                ),
                for (final question in category.questions)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(question.text, style: theme.textTheme.bodyMedium),
                        const SizedBox(height: 8),
                        RatingSelector(
                          value: ratings[question.id],
                          onChanged: (rating) => onRate(question.id, rating),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
        _StepFooter(onBack: onBack, onContinue: onContinue),
      ],
    );
  }
}

class _FeedbackStep extends StatelessWidget {
  const _FeedbackStep({
    required this.anonymous,
    required this.onAnonymousChanged,
    required this.positiveController,
    required this.improvementController,
    required this.additionalController,
    required this.onContinue,
    required this.onBack,
  });

  final bool anonymous;
  final ValueChanged<bool> onAnonymousChanged;
  final TextEditingController positiveController;
  final TextEditingController improvementController;
  final TextEditingController additionalController;
  final VoidCallback onContinue;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text('Written Feedback', style: theme.textTheme.titleLarge),
              const SizedBox(height: 4),
              Text('Optional, but very helpful for your trainer and IST.', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
              const SizedBox(height: 16),
              TextField(
                controller: positiveController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'What went well?'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: improvementController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'What could be improved?'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: additionalController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Additional comments'),
              ),
              const SizedBox(height: 16),
              Card(
                child: SwitchListTile(
                  value: anonymous,
                  onChanged: onAnonymousChanged,
                  title: const Text('Submit anonymously'),
                  subtitle: const Text('Your trainer will see "Anonymous Student" instead of your name.'),
                ),
              ),
            ],
          ),
        ),
        _StepFooter(onBack: onBack, onContinue: onContinue),
      ],
    );
  }
}

class _ReviewStep extends StatelessWidget {
  const _ReviewStep({
    required this.pending,
    required this.categories,
    required this.ratings,
    required this.anonymous,
    required this.submitting,
    required this.error,
    required this.onSubmit,
    required this.onBack,
  });

  final PendingEvaluation pending;
  final List<QuestionCategory> categories;
  final Map<int, int> ratings;
  final bool anonymous;
  final bool submitting;
  final String? error;
  final VoidCallback onSubmit;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final average = ratings.values.isEmpty ? 0 : ratings.values.reduce((a, b) => a + b) / ratings.values.length;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text('Review Your Evaluation', style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${pending.trainer.name} · ${pending.unit.name}', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text('Average rating: ${average.toStringAsFixed(1)} / 5'),
                      const SizedBox(height: 4),
                      Text(anonymous ? 'Submitting anonymously' : 'Submitting under your name'),
                    ],
                  ),
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(error!, style: TextStyle(color: theme.colorScheme.onErrorContainer)),
                ),
              ],
            ],
          ),
        ),
        _StepFooter(
          onBack: onBack,
          onContinue: submitting ? null : onSubmit,
          continueLabel: submitting ? 'Submitting…' : 'Submit Evaluation',
        ),
      ],
    );
  }
}

class _StepFooter extends StatelessWidget {
  const _StepFooter({required this.onBack, required this.onContinue, this.continueLabel = 'Continue'});

  final VoidCallback onBack;
  final VoidCallback? onContinue;
  final String continueLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(child: OutlinedButton(onPressed: onBack, child: const Text('Back'))),
          const SizedBox(width: 12),
          Expanded(flex: 2, child: FilledButton(onPressed: onContinue, child: Text(continueLabel))),
        ],
      ),
    );
  }
}

class _ConfirmationView extends StatelessWidget {
  const _ConfirmationView({required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_rounded, size: 72, color: theme.colorScheme.primary),
              const SizedBox(height: 20),
              Text('Evaluation Submitted', style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                'Thank you for helping us improve the quality of training.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(onPressed: onDone, child: const Text('Back to Evaluations')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
