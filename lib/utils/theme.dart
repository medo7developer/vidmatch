import 'package:flutter/material.dart';

// Color Scheme Light
final lightColorScheme = ColorScheme.fromSeed(
  seedColor: const Color(0xFF1E88E5),
  brightness: Brightness.light,
  primary: const Color(0xFF1E88E5),
  onPrimary: Colors.white,
  secondary: const Color(0xFF26C6DA),
  onSecondary: Colors.white,
  error: const Color(0xFFE53935),
  onError: Colors.white,
  background: const Color(0xFFF5F5F5),
  onBackground: Colors.black,
  surface: Colors.white,
  onSurface: Colors.black,
);

// Color Scheme Dark
final darkColorScheme = ColorScheme.fromSeed(
  seedColor: const Color(0xFF1E88E5),
  brightness: Brightness.dark,
  primary: const Color(0xFF42A5F5),
  onPrimary: Colors.black,
  secondary: const Color(0xFF4DD0E1),
  onSecondary: Colors.black,
  error: const Color(0xFFEF5350),
  onError: Colors.black,
  background: const Color(0xFF121212),
  onBackground: Colors.white,
  surface: const Color(0xFF1E1E1E),
  onSurface: Colors.white,
);

// هيكل TextTheme
TextTheme appTextTheme(TextTheme base) {
  return base.copyWith(
    headlineLarge: base.headlineLarge?.copyWith(
      fontWeight: FontWeight.bold,
    ),
    headlineMedium: base.headlineMedium?.copyWith(
      fontWeight: FontWeight.bold,
    ),
    titleLarge: base.titleLarge?.copyWith(
      fontWeight: FontWeight.bold,
    ),
    titleMedium: base.titleMedium?.copyWith(
      fontWeight: FontWeight.w500,
    ),
    bodyLarge: base.bodyLarge?.copyWith(
      fontSize: 16,
    ),
    bodyMedium: base.bodyMedium?.copyWith(
      fontSize: 14,
    ),
    labelLarge: base.labelLarge?.copyWith(
      letterSpacing: 1.2,
      fontWeight: FontWeight.bold,
    ),
  );
}

// أنماط الأزرار
ButtonStyle elevatedButtonStyle = ElevatedButton.styleFrom(
  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(8),
  ),
);

ButtonStyle outlinedButtonStyle = OutlinedButton.styleFrom(
  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(8),
  ),
);

ButtonStyle textButtonStyle = TextButton.styleFrom(
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
);
