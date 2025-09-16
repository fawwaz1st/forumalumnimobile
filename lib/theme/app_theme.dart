import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const _radius = 12.0; // Reduced radius for better performance

  static ThemeData light = _base(Brightness.light);
  static ThemeData dark = _base(Brightness.dark);

  static ThemeData _base(Brightness b) {
    final cs = ColorScheme.fromSeed(
      seedColor: Colors.indigo, 
      brightness: b,
      // Reduced color variations for better performance
    );
    
    // Simplified typography for better performance
    final textTheme = Typography.material2021(platform: TargetPlatform.android).black.copyWith(
          titleLarge: const TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
          titleMedium: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
          titleSmall: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          bodyLarge: const TextStyle(fontSize: 16),
          bodyMedium: const TextStyle(fontSize: 14),
          labelLarge: const TextStyle(fontWeight: FontWeight.w500),
        );

    return ThemeData(
      colorScheme: cs,
      useMaterial3: true,
      brightness: b,
      textTheme: textTheme,
      // Simplified app bar theme
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
      ),
      // Simplified card theme
      cardTheme: CardThemeData(
        elevation: 1.0,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radius)),
      ),
      // Simplified input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
      ),
      // Simplified chip theme
      chipTheme: ChipThemeData(
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      // Simplified snackbar theme
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      // Simplified navigation bar theme
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: cs.primary.withOpacity(0.1),
        elevation: 0.5,
        height: 60,
      ),
      // Simplified button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}