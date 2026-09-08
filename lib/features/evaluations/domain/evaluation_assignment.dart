class TrainerInfo {
  const TrainerInfo({required this.id, required this.name, this.department, this.photoPath});

  final int id;
  final String name;
  final String? department;
  final String? photoPath;

  factory TrainerInfo.fromJson(Map<String, dynamic> json) {
    return TrainerInfo(
      id: json['id'] as int,
      name: json['name'] as String,
      department: json['department'] as String?,
      photoPath: json['photo_path'] as String?,
    );
  }
}

class UnitInfo {
  const UnitInfo({required this.id, required this.code, required this.name});

  final int id;
  final String code;
  final String name;

  factory UnitInfo.fromJson(Map<String, dynamic> json) {
    return UnitInfo(id: json['id'] as int, code: json['code'] as String, name: json['name'] as String);
  }
}

/// One row from GET /student/evaluations — either a trainer/unit still
/// awaiting a submission, or one the student has already completed.
class EvaluationAssignment {
  const EvaluationAssignment({
    required this.status,
    required this.evaluationPeriodId,
    required this.evaluationPeriodName,
    required this.trainer,
    required this.unit,
    this.trainerAssignmentId,
    this.evaluationId,
    this.submittedAt,
  });

  final String status; // 'pending' | 'completed'
  final int evaluationPeriodId;
  final String evaluationPeriodName;
  final TrainerInfo trainer;
  final UnitInfo unit;
  final int? trainerAssignmentId;
  final int? evaluationId;
  final DateTime? submittedAt;

  bool get isPending => status == 'pending';

  factory EvaluationAssignment.fromJson(Map<String, dynamic> json) {
    return EvaluationAssignment(
      status: json['status'] as String,
      evaluationPeriodId: json['evaluation_period_id'] as int,
      evaluationPeriodName: json['evaluation_period_name'] as String,
      trainer: TrainerInfo.fromJson(Map<String, dynamic>.from(json['trainer'] as Map)),
      unit: UnitInfo.fromJson(Map<String, dynamic>.from(json['unit'] as Map)),
      trainerAssignmentId: json['trainer_assignment_id'] as int?,
      evaluationId: json['evaluation_id'] as int?,
      submittedAt: json['submitted_at'] != null ? DateTime.parse(json['submitted_at'] as String) : null,
    );
  }

  /// Only valid for a pending item — carries what the wizard needs to load
  /// the questionnaire and submit against the right assignment.
  PendingEvaluation toPending() {
    assert(isPending && trainerAssignmentId != null);

    return PendingEvaluation(
      trainerAssignmentId: trainerAssignmentId!,
      evaluationPeriodId: evaluationPeriodId,
      evaluationPeriodName: evaluationPeriodName,
      trainer: trainer,
      unit: unit,
    );
  }
}

class PendingEvaluation {
  const PendingEvaluation({
    required this.trainerAssignmentId,
    required this.evaluationPeriodId,
    required this.evaluationPeriodName,
    required this.trainer,
    required this.unit,
  });

  final int trainerAssignmentId;
  final int evaluationPeriodId;
  final String evaluationPeriodName;
  final TrainerInfo trainer;
  final UnitInfo unit;
}

class QuestionItem {
  const QuestionItem({required this.id, required this.text});

  final int id;
  final String text;

  factory QuestionItem.fromJson(Map<String, dynamic> json) {
    return QuestionItem(id: json['id'] as int, text: json['text'] as String);
  }
}

class QuestionCategory {
  const QuestionCategory({required this.id, required this.name, required this.questions});

  final int id;
  final String name;
  final List<QuestionItem> questions;

  factory QuestionCategory.fromJson(Map<String, dynamic> json) {
    return QuestionCategory(
      id: json['id'] as int,
      name: json['name'] as String,
      questions: List<Map>.from(json['questions'] as List)
          .map((q) => QuestionItem.fromJson(Map<String, dynamic>.from(q)))
          .toList(),
    );
  }
}

class EvaluationDetail {
  const EvaluationDetail({
    required this.trainerAssignmentId,
    required this.trainer,
    required this.unit,
    required this.categories,
  });

  final int trainerAssignmentId;
  final TrainerInfo trainer;
  final UnitInfo unit;
  final List<QuestionCategory> categories;

  factory EvaluationDetail.fromJson(Map<String, dynamic> json) {
    return EvaluationDetail(
      trainerAssignmentId: json['trainer_assignment_id'] as int,
      trainer: TrainerInfo.fromJson(Map<String, dynamic>.from(json['trainer'] as Map)),
      unit: UnitInfo.fromJson(Map<String, dynamic>.from(json['unit'] as Map)),
      categories: List<Map>.from(json['categories'] as List)
          .map((c) => QuestionCategory.fromJson(Map<String, dynamic>.from(c)))
          .toList(),
    );
  }
}
