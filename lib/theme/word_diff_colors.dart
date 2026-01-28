import 'package:flutter/material.dart';

/// Theme extension for word diff visualization colors.
/// Provides consistent colors for correct, missing, and extra words
/// across light and dark themes.
@immutable
class WordDiffColors extends ThemeExtension<WordDiffColors> {
  const WordDiffColors({
    required this.correctWordColor,
    required this.missingWordColor,
    required this.extraWordColor,
  });

  final Color correctWordColor;
  final Color missingWordColor;
  final Color extraWordColor;

  @override
  WordDiffColors copyWith({
    Color? correctWordColor,
    Color? missingWordColor,
    Color? extraWordColor,
  }) {
    return WordDiffColors(
      correctWordColor: correctWordColor ?? this.correctWordColor,
      missingWordColor: missingWordColor ?? this.missingWordColor,
      extraWordColor: extraWordColor ?? this.extraWordColor,
    );
  }

  @override
  WordDiffColors lerp(WordDiffColors? other, double t) {
    if (other is! WordDiffColors) {
      return this;
    }
    return WordDiffColors(
      correctWordColor: Color.lerp(
        correctWordColor,
        other.correctWordColor,
        t,
      )!,
      missingWordColor: Color.lerp(
        missingWordColor,
        other.missingWordColor,
        t,
      )!,
      extraWordColor: Color.lerp(extraWordColor, other.extraWordColor, t)!,
    );
  }

  /// Light theme word diff colors
  static const WordDiffColors light = WordDiffColors(
    correctWordColor: Color(0xFF2E7D32), // Colors.green.shade800
    missingWordColor: Color(0xFF616161), // Colors.grey.shade700
    extraWordColor: Color(0xFFEF6C00), // Colors.orange.shade800
  );

  /// Dark theme word diff colors
  static const WordDiffColors dark = WordDiffColors(
    correctWordColor: Color(0xFF66BB6A), // Colors.green.shade400
    missingWordColor: Color(0xFF9E9E9E), // Colors.grey.shade400
    extraWordColor: Color(0xFFFFB74D), // Colors.orange.shade400
  );
}
