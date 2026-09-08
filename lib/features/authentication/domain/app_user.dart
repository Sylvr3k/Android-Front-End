class StudentProfile {
  const StudentProfile({
    required this.id,
    required this.admissionNumber,
    required this.status,
    required this.programName,
    required this.levelName,
    required this.intakeName,
    this.phone,
    this.photoUrl,
  });

  final int id;
  final String admissionNumber;
  final String status;
  final String? programName;
  final String? levelName;
  final String? intakeName;
  final String? phone;
  final String? photoUrl;

  StudentProfile copyWith({String? phone, String? photoUrl}) {
    return StudentProfile(
      id: id,
      admissionNumber: admissionNumber,
      status: status,
      programName: programName,
      levelName: levelName,
      intakeName: intakeName,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    return StudentProfile(
      id: json['id'] as int,
      admissionNumber: json['admission_number'] as String,
      status: json['status'] as String,
      programName: (json['program'] as Map?)?['name'] as String?,
      levelName: (json['level'] as Map?)?['name'] as String?,
      intakeName: (json['intake'] as Map?)?['name'] as String?,
      phone: json['phone'] as String?,
      photoUrl: json['photo_url'] as String?,
    );
  }
}

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.mustChangePassword,
    this.student,
  });

  final int id;
  final String name;
  final String email;
  final String role;
  final bool mustChangePassword;
  final StudentProfile? student;

  bool get isStudent => role == 'student';

  AppUser copyWithStudent(StudentProfile student) {
    return AppUser(
      id: id,
      name: name,
      email: email,
      role: role,
      mustChangePassword: mustChangePassword,
      student: student,
    );
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      mustChangePassword: json['must_change_password'] as bool? ?? false,
      student: json['student'] != null ? StudentProfile.fromJson(Map<String, dynamic>.from(json['student'] as Map)) : null,
    );
  }
}
