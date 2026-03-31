import 'package:flutter/material.dart';
import 'config/theme.dart';
import 'screens/dashboard_screen.dart';
import 'screens/log_seizure_screen.dart';
import 'screens/medication_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/triggers_screen.dart';

void main() {
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
        '/onboarding': (_) => const OnboardingScreen(),
        '/dashboard': (_) => const DashboardScreen(),
        '/log-seizure': (_) => const LogSeizureScreen(),
        '/triggers': (_) => const TriggersScreen(),
        '/medication': (_) => const MedicationScreen(),
        '/profile': (_) => const ProfileScreen(),
      },
    );
  }
}
