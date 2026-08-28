import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';
import '../models/user_role.dart';

/// Wraps Firebase Auth + the Firestore `users` profile document.
/// Covers the "User and Insurance Agent registration and authentication"
/// key process. Admin accounts are seeded manually (see README), not
/// self-registerable.
class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentFirebaseUser => _auth.currentUser;

  CollectionReference<Map<String, dynamic>> get _usersCol => _firestore.collection('users');

  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required UserRole role,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    final uid = credential.user!.uid;
    final user = AppUser(uid: uid, name: name, email: email, phone: phone, role: role);
    await _usersCol.doc(uid).set(user.toMap());
    return user;
  }

  Future<AppUser> login({required String email, required String password}) async {
    final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
    return fetchProfile(credential.user!.uid);
  }

  Future<void> logout() => _auth.signOut();

  Future<AppUser> fetchProfile(String uid) async {
    final doc = await _usersCol.doc(uid).get();
    if (!doc.exists) {
      throw StateError('No user profile found for uid $uid');
    }
    return AppUser.fromMap(uid, doc.data()!);
  }
}
