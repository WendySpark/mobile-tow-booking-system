import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_state.dart';
import 'firebase_options.dart';
import 'screens/role_router.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MobileTowBookingApp());
}

class MobileTowBookingApp extends StatelessWidget {
  const MobileTowBookingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState()..restoreSession(),
      child: MaterialApp(
        title: 'Mobile Tow Booking System',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const RoleRouter(),
      ),
    );
  }
}
