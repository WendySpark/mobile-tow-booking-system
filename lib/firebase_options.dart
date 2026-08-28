// GENERATED PLACEHOLDER — replace by running `flutterfire configure` from
// the project root once you have created a Firebase project. That command
// overwrites this entire file with real values for your project; see
// README.md "Firebase setup" for the exact steps.
//
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web is not configured for this project.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform. '
          'Run `flutterfire configure` to generate real options.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB3aqwkYHGt3KRhvG-ZuN18f-D8s2lPOpc',
    appId: '1:274783552517:android:0a06169f79ae018ff5c86c',
    messagingSenderId: '274783552517',
    projectId: 'mobile-tow-booking-system',
    storageBucket: 'mobile-tow-booking-system.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBT8mY7HisXesvuubQyJJtzcmmTNyTVB8o',
    appId: '1:274783552517:ios:3ece7712759668c2f5c86c',
    messagingSenderId: '274783552517',
    projectId: 'mobile-tow-booking-system',
    storageBucket: 'mobile-tow-booking-system.firebasestorage.app',
    iosBundleId: 'com.towbooking.mobileTowBookingSystem',
  );
}
