import '../models/course_model.dart';

class StudentProfile {
  final int id;
  final String studentId;
  final String phone;
  final int? courseId;
  final String? shift;
  final String? gender;

  StudentProfile({
    required this.id,
    required this.studentId,
    required this.phone,
    this.courseId,
    this.shift,
    this.gender,
  });

  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    return StudentProfile(
      id: json['id'],
      studentId: json['studentId'],
      phone: json['phone'],
      courseId: json['courseId'],
      shift: json['shift'],
      gender: json['gender'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'phone': phone,
      'courseId': courseId,
      'shift': shift,
      'gender': gender,
    };
  }
}


class User {
  final int id;
  final String name;
  final String email;
  final String? role;
  final int? courseId;
  final StudentProfile? studentProfile;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.role,
    this.courseId,
    this.studentProfile,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    StudentProfile? profile;
    if (json['documentId'] != null || json['phone'] != null) {
      profile = StudentProfile(
        id: 0,
        studentId: json['documentId'] ?? '',
        phone: json['phone'] ?? '',
        courseId: null,
        shift: null,
        gender: null,
      );
    }
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
      courseId: json['courseId'],
      studentProfile: profile,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'courseId': courseId,
      'studentProfile': studentProfile?.toJson(),
    };
  }
}