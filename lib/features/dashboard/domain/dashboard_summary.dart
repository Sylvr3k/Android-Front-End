class RecentActivityItem {
  const RecentActivityItem({required this.unit, required this.submittedAt});

  final String unit;
  final DateTime submittedAt;

  factory RecentActivityItem.fromJson(Map<String, dynamic> json) {
    return RecentActivityItem(unit: json['unit'] as String, submittedAt: DateTime.parse(json['submitted_at'] as String));
  }
}

class AnnouncementSummary {
  const AnnouncementSummary({
    required this.id,
    required this.title,
    required this.message,
    required this.priority,
    required this.publishAt,
  });

  final int id;
  final String title;
  final String message;
  final String priority;
  final DateTime publishAt;

  factory AnnouncementSummary.fromJson(Map<String, dynamic> json) {
    return AnnouncementSummary(
      id: json['id'] as int,
      title: json['title'] as String,
      message: json['message'] as String,
      priority: json['priority'] as String,
      publishAt: DateTime.parse(json['publish_at'] as String),
    );
  }
}

class DashboardSummary {
  const DashboardSummary({
    required this.studentName,
    required this.programName,
    required this.levelName,
    required this.intakeName,
    required this.pendingEvaluations,
    required this.recentActivity,
    required this.announcements,
  });

  final String studentName;
  final String? programName;
  final String? levelName;
  final String? intakeName;
  final int pendingEvaluations;
  final List<RecentActivityItem> recentActivity;
  final List<AnnouncementSummary> announcements;

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    final student = Map<String, dynamic>.from(json['student'] as Map);

    return DashboardSummary(
      studentName: student['name'] as String,
      programName: student['program'] as String?,
      levelName: student['level'] as String?,
      intakeName: student['intake'] as String?,
      pendingEvaluations: json['pending_evaluations'] as int,
      recentActivity: List<Map>.from(json['recent_activity'] as List)
          .map((e) => RecentActivityItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      announcements: List<Map>.from(json['announcements'] as List)
          .map((e) => AnnouncementSummary.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}
