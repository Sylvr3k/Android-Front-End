import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ist_trainer_evaluation/features/evaluations/data/evaluations_repository.dart';
import 'package:ist_trainer_evaluation/features/evaluations/domain/evaluation_assignment.dart';
import 'package:ist_trainer_evaluation/features/evaluations/presentation/providers/evaluations_provider.dart';
import 'package:ist_trainer_evaluation/features/evaluations/presentation/screens/evaluations_screen.dart';

/// A stand-in for the real repository so this test never touches the
/// network — it only asserts how the screen renders whatever the API
/// (faked here) says the student is eligible to evaluate.
class _FakeEvaluationsRepository implements EvaluationsRepository {
  @override
  Future<List<EvaluationAssignment>> list() async {
    return [
      const EvaluationAssignment(
        status: 'pending',
        evaluationPeriodId: 1,
        evaluationPeriodName: 'Term 2 Trainer Evaluation',
        trainer: TrainerInfo(id: 1, name: 'Peter Mwangi'),
        unit: UnitInfo(id: 2, code: 'CS302', name: 'Ethical Hacking'),
        trainerAssignmentId: 10,
      ),
      const EvaluationAssignment(
        status: 'completed',
        evaluationPeriodId: 1,
        evaluationPeriodName: 'Term 2 Trainer Evaluation',
        trainer: TrainerInfo(id: 2, name: 'John Kamau'),
        unit: UnitInfo(id: 1, code: 'CS301', name: 'Network Security'),
        evaluationId: 99,
      ),
    ];
  }

  @override
  Future<List<EvaluationAssignment>> history() async => [];

  @override
  Future<EvaluationDetail> loadQuestionnaire(PendingEvaluation pending) => throw UnimplementedError();

  @override
  Future<void> submit({
    required PendingEvaluation pending,
    required bool anonymous,
    required List<EvaluationAnswerInput> answers,
    String? positiveFeedback,
    String? improvementFeedback,
    String? additionalComments,
  }) =>
      throw UnimplementedError();
}

void main() {
  testWidgets('only shows trainers the eligibility API actually returned', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          evaluationsRepositoryProvider.overrideWithValue(_FakeEvaluationsRepository()),
        ],
        child: const MaterialApp(home: EvaluationsScreen()),
      ),
    );

    await tester.pumpAndSettle();

    // Eligible/pending trainer is visible.
    expect(find.text('Peter Mwangi'), findsOneWidget);
    // Completed trainer is visible under "Current" too, but as completed.
    expect(find.text('John Kamau'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
    // A trainer the fake API never returned (e.g. Mary Wanjiku, who would
    // teach a different level/program) must never appear.
    expect(find.text('Mary Wanjiku'), findsNothing);
  });
}
