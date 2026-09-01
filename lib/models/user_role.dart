enum UserRole { user, agent, admin, workshop }

extension UserRoleX on UserRole {
  String get value => switch (this) {
    UserRole.user => 'user',
    UserRole.agent => 'agent',
    UserRole.admin => 'admin',
    UserRole.workshop => 'workshop',
  };

  static UserRole fromValue(String value) => switch (value) {
    'agent' => UserRole.agent,
    'admin' => UserRole.admin,
    'workshop' => UserRole.workshop,
    _ => UserRole.user,
  };
}
