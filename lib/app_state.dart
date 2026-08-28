import 'package:flutter/foundation.dart';

import 'models/app_user.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';

/// Holds the signed-in user's profile for the lifetime of the app session.
/// Screens read `AppState.currentUser` (via Provider) to branch by role and
/// to scope their Firestore queries (e.g. "my vehicles", "my policies").
class AppState extends ChangeNotifier {
  AppState({AuthService? authService, FirestoreService? firestoreService})
      : authService = authService ?? AuthService(),
        firestoreService = firestoreService ?? FirestoreService();

  final AuthService authService;
  final FirestoreService firestoreService;

  AppUser? currentUser;
  bool isLoading = false;

  Future<void> restoreSession() async {
    final firebaseUser = authService.currentFirebaseUser;
    if (firebaseUser == null) return;
    isLoading = true;
    notifyListeners();
    try {
      currentUser = await authService.fetchProfile(firebaseUser.uid);
    } catch (_) {
      currentUser = null;
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> setUser(AppUser user) async {
    currentUser = user;
    notifyListeners();
  }

  Future<void> setPreferredWorkshop(String workshopId) async {
    if (currentUser == null) return;
    await firestoreService.setPreferredWorkshop(currentUser!.uid, workshopId);
    currentUser = currentUser!.copyWith(preferredWorkshopId: workshopId);
    notifyListeners();
  }

  Future<void> logout() async {
    await authService.logout();
    currentUser = null;
    notifyListeners();
  }
}
