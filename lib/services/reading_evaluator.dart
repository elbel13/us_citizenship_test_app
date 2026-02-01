import 'package:string_similarity/string_similarity.dart';

/// Result of answer evaluation
enum EvaluationResult {
  pass, // Answer is correct
  partial, // Answer is partially correct or unclear
  fail, // Answer is incorrect
}

/// Service for evaluating reading accuracy using speech recognition results
class ReadingEvaluator {
  /// Minimum similarity score to pass (0.0 to 1.0)
  static const double passingThreshold = 0.80;

  /// Minimum keyword match percentage for civics questions (0.0 to 1.0)
  static const double keywordPassingThreshold = 0.70;

  /// Minimum keyword match percentage for partial credit
  static const double keywordPartialThreshold = 0.40;

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
  /// - Remove punctuation (but convert hyphens to spaces for number words)
  /// - Trim whitespace
  /// - Normalize multiple spaces to single space
  String _normalizeText(String text) {
    return text
        .toLowerCase()
        .replaceAll(
          '-',
          ' ',
        ) // Convert hyphens to spaces (e.g., "twenty-seven" -> "twenty seven")
        .replaceAll(RegExp(r'[^\w\s]'), '') // Remove remaining punctuation
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

  /// Get detailed word-level diff for display
  /// Returns a list of WordDiff objects showing the comparison
  /// Shows expected words in order (green/gray), with extra words inserted where spoken
  List<WordDiff> getWordDiff(String expectedText, String spokenText) {
    final expectedWords = _normalizeText(expectedText).split(' ');
    final spokenWords = _normalizeText(spokenText).split(' ');
    final result = <WordDiff>[];

    // Track which spoken words we've already matched
    final spokenWordUsed = List.filled(spokenWords.length, false);

    // Match spoken words to expected words (greedy left-to-right)
    final expectedToSpokenIndex = <int, int>{};
    for (var i = 0; i < expectedWords.length; i++) {
      for (var j = 0; j < spokenWords.length; j++) {
        if (!spokenWordUsed[j] && expectedWords[i] == spokenWords[j]) {
          expectedToSpokenIndex[i] = j;
          spokenWordUsed[j] = true;
          break;
        }
      }
    }

    // Build result: iterate through expected words in order
    var lastSpokenIndex = -1;
    for (var i = 0; i < expectedWords.length; i++) {
      if (expectedToSpokenIndex.containsKey(i)) {
        final spokenIndex = expectedToSpokenIndex[i]!;
        // Insert any extra words that came before this word in spoken text
        for (var j = lastSpokenIndex + 1; j < spokenIndex; j++) {
          if (!spokenWordUsed[j]) {
            result.add(
              WordDiff(word: spokenWords[j], type: WordDiffType.added),
            );
          }
        }
        // Add the correct word
        result.add(
          WordDiff(word: expectedWords[i], type: WordDiffType.correct),
        );
        lastSpokenIndex = spokenIndex;
      } else {
        // Word was not spoken - mark as missing
        result.add(
          WordDiff(word: expectedWords[i], type: WordDiffType.missing),
        );
      }
    }

    // Add any remaining extra words at the end
    for (var j = lastSpokenIndex + 1; j < spokenWords.length; j++) {
      if (!spokenWordUsed[j]) {
        result.add(WordDiff(word: spokenWords[j], type: WordDiffType.added));
      }
    }

    return result;
  }

  /// Calculate percentage score (0-100)
  int getPercentageScore(double similarityScore) {
    return (similarityScore * 100).round();
  }

  /// Evaluate civics question answer using keyword matching
  /// Supports multiple acceptable answers
  /// Returns Pass if keywords match well, Partial if some match, Fail if poor match
  EvaluationResult evaluateCivicsAnswer(
    List<String> acceptableAnswers,
    String spokenAnswer,
  ) {
    if (acceptableAnswers.isEmpty) {
      return EvaluationResult.fail;
    }

    // Normalize spoken answer
    final spokenNorm = _normalizeText(spokenAnswer);

    // Try matching against each acceptable answer
    double bestMatchScore = 0.0;

    for (final expected in acceptableAnswers) {
      final score = _evaluateKeywordMatch(expected, spokenNorm);
      if (score > bestMatchScore) {
        bestMatchScore = score;
      }
    }

    // Determine result based on best match
    if (bestMatchScore >= keywordPassingThreshold) {
      return EvaluationResult.pass;
    } else if (bestMatchScore >= keywordPartialThreshold) {
      return EvaluationResult.partial;
    } else {
      return EvaluationResult.fail;
    }
  }

  /// Extract keywords from expected answer and check presence in spoken text
  /// Returns a score from 0.0 to 1.0 representing keyword coverage
  double _evaluateKeywordMatch(String expectedAnswer, String spokenNorm) {
    final expectedNorm = _normalizeText(expectedAnswer);
    final expectedWords = expectedNorm
        .split(' ')
        .where((w) => w.isNotEmpty)
        .toList();

    if (expectedWords.isEmpty) {
      return 0.0;
    }

    // Extract keywords (remove common filler words)
    final keywords = _extractKeywords(expectedWords);

    if (keywords.isEmpty) {
      // If all words are filler, fall back to similarity comparison
      return expectedNorm.similarityTo(spokenNorm);
    }

    // Count how many keywords appear in spoken answer
    int matchedKeywords = 0;
    for (final keyword in keywords) {
      if (spokenNorm.contains(keyword)) {
        matchedKeywords++;
      }
    }

    return matchedKeywords / keywords.length;
  }

  /// Extract important keywords by filtering out common filler words
  List<String> _extractKeywords(List<String> words) {
    // Common words to ignore in civics answers
    const fillerWords = {
      'the',
      'a',
      'an',
      'and',
      'or',
      'but',
      'in',
      'on',
      'at',
      'to',
      'for',
      'of',
      'with',
      'from',
      'by',
      'is',
      'are',
      'was',
      'were',
      'be',
      'been',
      'being',
      'have',
      'has',
      'had',
      'do',
      'does',
      'did',
      'will',
      'would',
      'should',
      'could',
      'may',
      'might',
      'can',
      'must',
      'it',
      'its',
      'this',
      'that',
      'these',
      'those',
      'there',
      'here',
      'what',
      'which',
      'who',
      'when',
      'where',
      'why',
      'how',
      'all',
      'each',
      'every',
      'both',
      'few',
      'more',
      'most',
      'other',
      'some',
      'such',
      'than',
      'too',
      'very',
      'one',
    };

    return words.where((word) => !fillerWords.contains(word)).toList();
  }

  /// Get feedback for civics question based on evaluation result
  String getCivicsFeedback(EvaluationResult result) {
    switch (result) {
      case EvaluationResult.pass:
        return 'Correct!';
      case EvaluationResult.partial:
        return 'Partially correct. Can you provide more detail?';
      case EvaluationResult.fail:
        return 'Not quite right.';
    }
  }
}

/// Types of word differences
enum WordDiffType {
  correct, // Word matches expected
  wrong, // Word doesn't match expected
  missing, // Word missing from spoken text
  added, // Extra word in spoken text
}

/// Represents a word-level diff result
class WordDiff {
  final String word;
  final WordDiffType type;
  final String? spokenAs; // What was actually said (for 'wrong' type)

  WordDiff({required this.word, required this.type, this.spokenAs});
}
