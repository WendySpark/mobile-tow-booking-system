enum UserRole { user, agent, admin }

extension UserRoleX on UserRole {
  String get value => switch (this) {
        UserRole.user => 'user',
        UserRole.agent => 'agent',
        UserRole.admin => 'admin',
      };

  static UserRole fromValue(String value) => switch (value) {
        'agent' => UserRole.agent,
        'admin' => UserRole.admin,
        _ => UserRole.user,
      };
}
