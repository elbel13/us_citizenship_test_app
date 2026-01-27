import 'package:flutter/material.dart';

/// A reusable widget that displays progress and score information
/// for quiz/practice screens.
class ProgressIndicatorWidget extends StatelessWidget {
  /// The current item number (e.g., current question or sentence number).
  /// If null, will show "answered of total" format instead of "current of total".
  final int? currentIndex;

  /// The total number of items (questions, sentences, etc.)
  final int totalItems;

  /// Number of correct answers
  final int correctAnswers;

  /// Number of incorrect answers
  final int incorrectAnswers;

  /// Label for the items being counted (e.g., "Question", "Sentence", etc.)
  final String itemLabel;

  const ProgressIndicatorWidget({
    super.key,
    this.currentIndex,
    required this.totalItems,
    required this.correctAnswers,
    required this.incorrectAnswers,
    this.itemLabel = 'Item',
  });

  @override
  Widget build(BuildContext context) {
    final totalAnswered = correctAnswers + incorrectAnswers;
    final progressText = currentIndex != null
        ? '$itemLabel ${currentIndex! + 1} of $totalItems'
        : '${itemLabel}s: $totalAnswered of $totalItems';

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(progressText, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Score: $correctAnswers correct, $incorrectAnswers incorrect',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
