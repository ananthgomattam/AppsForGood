import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'config/theme.dart';
import 'screens/dashboard_screen.dart';
import 'screens/entries_screen.dart';
import 'screens/login_screen.dart';
import 'screens/log_seizure_screen.dart';
import 'screens/medication_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/triggers_screen.dart';
import 'screens/med_info_screen.dart';
import 'services/medication_notification_service.dart';

// The main entry point of the app. It initializes the database for desktop platforms, sets up medication notifications, and runs the app with the defined routes and theme.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await MedicationNotificationService.instance.initialize();
  await MedicationNotificationService.instance.syncMedicationReminders();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ForSeizure',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/onboarding': (_) => const OnboardingScreen(),
        '/dashboard': (_) => const DashboardScreen(),
        '/entries': (_) => const EntriesScreen(),
        '/log-seizure': (_) => const LogSeizureScreen(),
        '/triggers': (_) => const TriggersScreen(),
        '/medication': (_) => const MedicationScreen(),
        '/medication-safety': (_) => const MedicationSafetyScreen(),
        '/profile': (_) => const ProfileScreen(),
      },
    );
  }
}
