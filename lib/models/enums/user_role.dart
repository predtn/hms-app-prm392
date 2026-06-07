enum UserRole { frontDeskManager, receptionist, customer }

extension UserRoleExtension on UserRole {
  String get label {
    switch (this) {
      case UserRole.frontDeskManager:
        return 'FrontDeskManager';
      case UserRole.receptionist:
        return 'Receptionist';
      case UserRole.customer:
        return 'Customer';
    }
  }

  bool get canManageHotelConfig {
    return switch (this) {
      UserRole.frontDeskManager => true,
      UserRole.receptionist || UserRole.customer => false,
    };
  }

  bool get canManageHotelOperations {
    return switch (this) {
      UserRole.receptionist => true,
      UserRole.frontDeskManager || UserRole.customer => false,
    };
  }

  String get defaultRoute {
    return switch (this) {
      UserRole.receptionist => '/room-map',
      UserRole.frontDeskManager => '/settings',
      UserRole.customer => '/profile',
    };
  }
}

extension UserRoleFromString on String {
  UserRole toUserRole() {
    switch (this) {
      case 'FrontDeskManager':
      case 'FDM':
        return UserRole.frontDeskManager;
      case 'Receptionist':
      case 'REC':
        return UserRole.receptionist;
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
