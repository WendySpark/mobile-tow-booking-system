import 'user_role.dart';

class AppUser {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final UserRole role;

  /// The Workshop (repair center) id the User has chosen as their default —
  /// pre-selected in Request Tow instead of always defaulting to nearest.
  final String? preferredWorkshopId;

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.preferredWorkshopId,
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) => AppUser(
        uid: uid,
        name: map['name'] as String? ?? '',
        email: map['email'] as String? ?? '',
        phone: map['phone'] as String? ?? '',
        role: UserRoleX.fromValue(map['role'] as String? ?? 'user'),
        preferredWorkshopId: map['preferredWorkshopId'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'phone': phone,
        'role': role.value,
        'preferredWorkshopId': preferredWorkshopId,
      };

  AppUser copyWith({String? preferredWorkshopId}) => AppUser(
        uid: uid,
        name: name,
        email: email,
        phone: phone,
        role: role,
        preferredWorkshopId: preferredWorkshopId ?? this.preferredWorkshopId,
      );
}
