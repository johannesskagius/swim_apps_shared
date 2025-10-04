enum UserRole {
  coach,
  swimmer,
  // parent, // Add other roles as needed
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.coach:
        return 'Coach';
      case UserRole.swimmer:
        return 'Swimmer';
    // case UserRole.parent:
    //   return 'Parent';
    }
  }
}