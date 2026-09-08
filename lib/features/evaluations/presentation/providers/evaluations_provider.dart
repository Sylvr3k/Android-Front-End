import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers.dart';
import '../../data/evaluations_repository.dart';
import '../../domain/evaluation_assignment.dart';

final evaluationsRepositoryProvider = Provider<EvaluationsRepository>((ref) {
  return EvaluationsRepository(ref.watch(apiClientProvider));
});

// autoDispose: if this ever builds while signed out (or on any other
// transient failure) and lands in an error state, it gets torn down the
// moment nothing is watching it (e.g. leaving the Evaluations tab) instead
// of being stuck showing that failure forever on every later visit.
final evaluationsListProvider =
    AsyncNotifierProvider.autoDispose<EvaluationsListController, List<EvaluationAssignment>>(
  EvaluationsListController.new,
);

class EvaluationsListController extends AutoDisposeAsyncNotifier<List<EvaluationAssignment>> {
  @override
  Future<List<EvaluationAssignment>> build() {
    return ref.read(evaluationsRepositoryProvider).list();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(evaluationsRepositoryProvider).list());
  }
}

final evaluationHistoryProvider = FutureProvider.autoDispose<List<EvaluationAssignment>>((ref) {
  return ref.read(evaluationsRepositoryProvider).history();
});

final evaluationQuestionnaireProvider =
    FutureProvider.autoDispose.family<EvaluationDetail, PendingEvaluation>((ref, pending) {
  return ref.read(evaluationsRepositoryProvider).loadQuestionnaire(pending);
});
