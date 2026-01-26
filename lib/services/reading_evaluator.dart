import 'package:string_similarity/string_similarity.dart';

/// Service for evaluating reading accuracy using speech recognition results
class ReadingEvaluator {
  /// Minimum similarity score to pass (0.0 to 1.0)
  static const double passingThreshold = 0.80;

  /// Calculate similarity between expected text and spoken text
  /// Returns a score from 0.0 (completely different) to 1.0 (identical)
  double calculateSimilarity(String expectedText, String spokenText) {
    final expectedNorm = _normalizeText(expectedText);
    final spokenNorm = _normalizeText(spokenText);

    return expectedNorm.similarityTo(spokenNorm);
  }

  /// Check if the spoken text passes the reading test
  bool isPassing(double similarityScore) {
    return similarityScore >= passingThreshold;
  }

  /// Get feedback message based on similarity score
  String getFeedback(double similarityScore) {
    if (similarityScore >= 0.95) {
      return 'Excellent! Perfect reading.';
    } else if (similarityScore >= 0.90) {
      return 'Great job! Very good reading.';
    } else if (similarityScore >= passingThreshold) {
      return 'Good! You passed.';
    } else if (similarityScore >= 0.60) {
      return 'Almost there. Try again.';
    } else {
      return 'Keep practicing. Try reading more slowly.';
    }
  }

  /// Normalize text for comparison
  /// - Convert to lowercase
  /// - Remove punctuation
  /// - Trim whitespace
  /// - Normalize multiple spaces to single space
  String _normalizeText(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '') // Remove punctuation
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize whitespace
        .trim();
  }

  /// Get word-level differences between expected and spoken text
  /// Returns a list of words that differ
  List<String> getWordDifferences(String expectedText, String spokenText) {
    final expectedWords = _normalizeText(expectedText).split(' ');
    final spokenWords = _normalizeText(spokenText).split(' ');
    final differences = <String>[];

    // Find words in expected that are missing or different in spoken
    for (var i = 0; i < expectedWords.length; i++) {
      if (i >= spokenWords.length || expectedWords[i] != spokenWords[i]) {
        differences.add(expectedWords[i]);
      }
    }

    return differences;
  }

  /// Calculate percentage score (0-100)
  int getPercentageScore(double similarityScore) {
    return (similarityScore * 100).round();
  }
}
