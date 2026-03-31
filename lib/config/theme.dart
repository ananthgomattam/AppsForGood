import 'package:flutter/material.dart';

class AppTheme {
	static const Color primaryPurple = Color(0xFF6A1B9A);

	static ThemeData get lightTheme {
		final colorScheme = ColorScheme.fromSeed(
			seedColor: primaryPurple,
			brightness: Brightness.light,
		);

		return ThemeData(
			useMaterial3: true,
			colorScheme: colorScheme,
			scaffoldBackgroundColor: const Color(0xFFF8F5FB),
			appBarTheme: const AppBarTheme(centerTitle: true),
			cardTheme: CardThemeData(
				elevation: 2,
				color: Colors.white,
				shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
			),
			inputDecorationTheme: InputDecorationTheme(
				filled: true,
				fillColor: Colors.white,
				border: OutlineInputBorder(
					borderRadius: BorderRadius.circular(12),
					borderSide: BorderSide(color: Colors.grey.shade300),
				),
				enabledBorder: OutlineInputBorder(
					borderRadius: BorderRadius.circular(12),
					borderSide: BorderSide(color: Colors.grey.shade300),
				),
				focusedBorder: OutlineInputBorder(
					borderRadius: BorderRadius.circular(12),
					borderSide: const BorderSide(color: primaryPurple, width: 1.8),
				),
			),
			elevatedButtonTheme: ElevatedButtonThemeData(
				style: ElevatedButton.styleFrom(
					backgroundColor: primaryPurple,
					foregroundColor: Colors.white,
					shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
					padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
				),
			),
		);
	}
}
