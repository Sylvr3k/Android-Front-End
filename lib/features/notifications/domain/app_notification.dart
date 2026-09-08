class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.read,
    required this.createdAt,
    this.data = const {},
  });

  final String id;
  final String type;
  final String? title;
  final String? body;
  final bool read;
  final DateTime createdAt;
  final Map<String, dynamic> data;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      type: json['type'] as String? ?? 'system_notification',
      title: json['title'] as String?,
      body: json['body'] as String?,
      read: json['read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      data: Map<String, dynamic>.from(json['data'] as Map? ?? {}),
    );
  }
}
