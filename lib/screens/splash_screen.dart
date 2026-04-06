import 'dart:async';

import 'package:flutter/material.dart';

import '../frontend/account_store.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

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
