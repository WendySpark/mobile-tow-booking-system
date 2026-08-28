import 'user_role.dart';

class AppUser {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final UserRole role;

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) => AppUser(
        uid: uid,
        name: map['name'] as String? ?? '',
        email: map['email'] as String? ?? '',
        phone: map['phone'] as String? ?? '',
        role: UserRoleX.fromValue(map['role'] as String? ?? 'user'),
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'phone': phone,
        'role': role.value,
      };
}
