import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'services/favorites_service.dart';
import 'services/alarm_service.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );
  final authService = AuthService();
  FirebaseAuth.instance.authStateChanges().listen((user) {
    if (user != null) {
      authService.ensureCurrentUserProfile().catchError((Object error) {
        debugPrint('Unable to create user profile: $error');
      });
    }
  });
  await FavoritesService.initialize();
  await NotificationService.instance.initialize();
  await AlarmService.instance.initialize();

  runApp(const CommuteAlertApp());
}

class CommuteAlertApp extends StatelessWidget {
  const CommuteAlertApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CommuteAlert',

      // App Theme
      theme: AppTheme.lightTheme,

      // Starting Screen
      home: const SplashScreen(),
    );
  }
}
