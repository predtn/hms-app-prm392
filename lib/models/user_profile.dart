import 'package:hms_app/models/enums/user_role.dart';

class UserProfile {
  final String id;
  final String? fullName;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? email;
  final UserRole role;
  final String? phone;

  UserProfile({
    required this.id,
    this.fullName,
    this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
    this.email,
    required this.role,
    this.phone,
  });

  // Manual factory from JSON (snake_case expected)
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      role: (json['role'] as String).toUserRole(), // ✅ was missing
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
      'email': email,
      'phone': phone, // ✅ was missing
      'role': role.label, // ✅ was missing
    };
  }
}
