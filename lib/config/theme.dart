import 'package:flutter/material.dart';

class AppTheme {
	static const Color deepPurplePrimary = Color(0xFF522583);
	static const Color vibrantViolet = Color(0xFF9D00FF);
	static const Color brightPurple = Color(0xFFA020F0);
	static const Color lavenderLight = Color(0xFFDAB1DA);
	static const Color darkPurpleAccent = Color(0xFF660066);

	static ThemeData get lightTheme {
		const colorScheme = ColorScheme(
			brightness: Brightness.light,
			primary: deepPurplePrimary,
			onPrimary: Colors.white,
			secondary: brightPurple,
			onSecondary: Colors.white,
			error: Color(0xFFB3261E),
			onError: Colors.white,
			surface: Color(0xFFFFF9FF),
			onSurface: Color(0xFF1F1730),
		);

		return ThemeData(
			useMaterial3: true,
			colorScheme: colorScheme,
			scaffoldBackgroundColor: const Color(0xFFFAF6FF),
			appBarTheme: const AppBarTheme(
				centerTitle: true,
				backgroundColor: deepPurplePrimary,
				foregroundColor: Colors.white,
				elevation: 0,
			),
			textTheme: const TextTheme(
				headlineMedium: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1F1730)),
				titleLarge: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF27193C)),
				titleMedium: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF2B1E40)),
				bodyLarge: TextStyle(color: Color(0xFF34254A)),
				bodyMedium: TextStyle(color: Color(0xFF49325F)),
			),
			cardTheme: CardThemeData(
				elevation: 2,
				color: Colors.white,
				shadowColor: const Color(0x14000000),
				shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
			),
			inputDecorationTheme: InputDecorationTheme(
				filled: true,
				fillColor: const Color(0xFFFFFBFF),
				floatingLabelBehavior: FloatingLabelBehavior.always,
				floatingLabelStyle: const TextStyle(
					color: darkPurpleAccent,
					fontWeight: FontWeight.w700,
				),
				prefixIconColor: darkPurpleAccent,
				suffixIconColor: darkPurpleAccent,
				border: OutlineInputBorder(
					borderRadius: BorderRadius.circular(12),
					borderSide: const BorderSide(color: Color(0xFFD9C2E5)),
				),
				enabledBorder: OutlineInputBorder(
					borderRadius: BorderRadius.circular(12),
					borderSide: const BorderSide(color: Color(0xFFD9C2E5)),
				),
				focusedBorder: OutlineInputBorder(
					borderRadius: BorderRadius.circular(12),
					borderSide: const BorderSide(color: vibrantViolet, width: 2),
				),
				labelStyle: const TextStyle(color: Color(0xFF5A4570)),
			),
			chipTheme: ChipThemeData(
				shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
				selectedColor: lavenderLight,
				backgroundColor: const Color(0xFFF1E4F4),
				labelStyle: const TextStyle(fontWeight: FontWeight.w600),
			),
			filledButtonTheme: FilledButtonThemeData(
				style: FilledButton.styleFrom(
					backgroundColor: deepPurplePrimary,
					foregroundColor: Colors.white,
					shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
					padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
				),
			),
			elevatedButtonTheme: ElevatedButtonThemeData(
				style: ElevatedButton.styleFrom(
					backgroundColor: deepPurplePrimary,
					foregroundColor: Colors.white,
					shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
					padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
				),
			),
			floatingActionButtonTheme: const FloatingActionButtonThemeData(
				backgroundColor: darkPurpleAccent,
				foregroundColor: Colors.white,
			),
		);
	}
}
