import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'services/favorites_service.dart';
import 'services/alarm_service.dart';
import 'services/notification_service.dart';
import 'services/firebase_service.dart' as app_firebase;
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );
  try {
    final firebaseService = app_firebase.FirebaseService();
    await firebaseService.seedSampleDataIfEmpty();
    await firebaseService.ensurePopularRoutes();
  } on FirebaseException catch (error) {
    debugPrint(
      'Sample Firestore data could not be created (${error.code}): '
      '${error.message ?? 'unknown Firestore error'}',
    );
  }
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
