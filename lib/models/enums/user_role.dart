enum UserRole { admin, customer }

extension UserRoleExtension on UserRole {
  String get label {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.customer:
        return 'Customer';
    }
  }
}

extension UserRoleFromString on String {
  UserRole toUserRole() {
    switch (this) {
      case 'Admin':
        return UserRole.admin;
      case 'Customer':
        return UserRole.customer;
      default:
        throw Exception('Invalid user role: $this');
    }
  }
}

UserRole? userRoleFromNullableString(String? value) {
  if (value == null) return null;
  return value.toUserRole();
}
