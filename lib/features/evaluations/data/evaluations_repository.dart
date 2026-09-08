import '../../../core/api/api_client.dart';
import '../domain/evaluation_assignment.dart';

class EvaluationAnswerInput {
  const EvaluationAnswerInput({required this.questionId, required this.rating});

  final int questionId;
  final int rating;

  Map<String, dynamic> toJson() => {'question_id': questionId, 'rating': rating};
}

class EvaluationsRepository {
  EvaluationsRepository(this._api);

  final ApiClient _api;

  Future<List<EvaluationAssignment>> list() async {
    final response = await _api.get('/student/evaluations');
    final items = List<Map>.from(response['data'] as List);

    return items.map((item) => EvaluationAssignment.fromJson(Map<String, dynamic>.from(item))).toList();
  }

  Future<List<EvaluationAssignment>> history() async {
    final response = await _api.get('/student/evaluations/history');
    final items = List<Map>.from(response['data'] as List);

    return items.map((item) => EvaluationAssignment.fromJson(Map<String, dynamic>.from(item))).toList();
  }

  Future<EvaluationDetail> loadQuestionnaire(PendingEvaluation pending) async {
    final response = await _api.get(
      '/student/evaluations/${pending.evaluationPeriodId}/${pending.trainerAssignmentId}',
    );

    return EvaluationDetail.fromJson(Map<String, dynamic>.from(response['data'] as Map));
  }

  Future<void> submit({
    required PendingEvaluation pending,
    required bool anonymous,
    required List<EvaluationAnswerInput> answers,
    String? positiveFeedback,
    String? improvementFeedback,
    String? additionalComments,
  }) {
    return _api.post('/student/evaluations', data: {
      'trainer_assignment_id': pending.trainerAssignmentId,
      'evaluation_period_id': pending.evaluationPeriodId,
      'anonymous': anonymous,
      'answers': answers.map((a) => a.toJson()).toList(),
      'positive_feedback': positiveFeedback,
      'improvement_feedback': improvementFeedback,
      'additional_comments': additionalComments,
    });
  }
}
