import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue).copyWith(
        // Override tertiary colors to be green for success states
        tertiary: Colors.green.shade700,
        tertiaryContainer: Colors.green.shade100,
        onTertiaryContainer: Colors.green.shade900,
      ),
      useMaterial3: true,
      // Add more theme customizations here as needed
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: Colors.lightBlue,
            brightness: Brightness.dark,
          ).copyWith(
            // Override tertiary colors to be green for success states in dark mode
            tertiary: Colors.green.shade400,
            tertiaryContainer: Colors.green.shade900,
            onTertiaryContainer: Colors.green.shade200,
          ),
      useMaterial3: true,
      // Add more dark theme customizations here as needed
    );
  }
}
