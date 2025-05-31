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
  final String cpf;
  final String? avatar;
  final Course? course;
  final bool isEmailVerified;
  final bool isDeleted;
  final String role;
  final String token;
  final String refreshToken;
  final DateTime createdAt;
  final DateTime updatedAt;
  final StudentProfile? studentProfile;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.cpf,
    this.avatar,
    this.course,
    required this.isEmailVerified,
    required this.isDeleted,
    required this.role,
    required this.token,
    required this.refreshToken,
    required this.createdAt,
    required this.updatedAt,
    this.studentProfile,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      cpf: json['cpf'],      avatar: json['avatar'],
      course: json['course'] != null ? Course.fromJson(json['course']) : null,
      isEmailVerified: json['isEmailVerified'],
      isDeleted: json['isDeleted'],
      role: json['role'],
      token: json['token'],
      refreshToken: json['refreshToken'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      studentProfile: json['studentProfile'] != null 
          ? StudentProfile.fromJson(json['studentProfile'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'cpf': cpf,      'avatar': avatar,
      'course': course?.toJson(),
      'isEmailVerified': isEmailVerified,
      'isDeleted': isDeleted,
      'role': role,
      'token': token,
      'refreshToken': refreshToken,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'studentProfile': studentProfile?.toJson(),
    };
  }
}