import 'dart:async';

import 'package:flutter/material.dart';

import '../frontend/account_store.dart';
//Copilot: "Explain the key Flutter patterns for implementing a splash screen with Timer delays, async auth checks, pushReplacementNamed navigation, and mounted state validation"
// The SplashScreen is a stateful widget that serves as the initial screen of the app. It displays a logo and app name while performing an asynchronous check to determine if the user is already authenticated. The screen uses a Timer to delay the navigation to the next screen, allowing for a brief display of the splash content. The navigation logic checks if the widget is still mounted before attempting to navigate, ensuring that it does not try to update the UI after the widget has been disposed.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}
// The _SplashScreenState class manages the state of the SplashScreen. It uses the initState method to set up a Timer that delays the execution of an asynchronous function. This function checks if there is a current user logged in using the FrontendAccountStore. Based on whether a user is found, it navigates to either the login screen or the dashboard screen using Navigator.pushReplacementNamed. The navigation is wrapped in a check for mounted to ensure that it only attempts to navigate if the widget is still part of the widget tree, preventing potential errors from trying to update the UI after disposal.
class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 1200), () async {
      if (!mounted) return;
      final user = await FrontendAccountStore.instance.getCurrentUsername();
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        user == null ? '/login' : '/dashboard',
      );
    });
  }
// The build method of the _SplashScreenState class defines the
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF522583), Color(0xFF9D00FF), Color(0xFFA020F0)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(
                Icons.health_and_safety,
                size: 84,
                color: Colors.white,
              ),
              SizedBox(height: 12),
              Text(
                'ForSeizure',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8),
              Text('Track triggers. Stay prepared.', style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }
}
