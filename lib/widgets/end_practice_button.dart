import 'package:flutter/material.dart';

/// A reusable button widget that allows users to exit practice screens early.
/// Displays a confirmation dialog with progress summary before exiting.
class EndPracticeButton extends StatelessWidget {
  /// Number of correct answers answered so far
  final int correctAnswers;

  /// Number of incorrect answers answered so far
  final int incorrectAnswers;

  /// Total number of questions/items in the practice session
  final int totalItems;

  /// Callback function when user confirms end practice (should navigate to main menu)
  final VoidCallback onEndPractice;

  const EndPracticeButton({
    super.key,
    required this.correctAnswers,
    required this.incorrectAnswers,
    required this.totalItems,
    required this.onEndPractice,
  });

  int get _totalAnswered => correctAnswers + incorrectAnswers;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.exit_to_app),
      tooltip: 'End Practice',
      onPressed: () => _showConfirmationDialog(context),
    );
  }

  Future<void> _showConfirmationDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('End Practice?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Are you sure you want to exit?'),
              const SizedBox(height: 16),
              if (_totalAnswered > 0) ...[
                const Text(
                  'Progress Summary:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Text('Correct: $correctAnswers'),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.cancel, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Text('Incorrect: $incorrectAnswers'),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.help_outline, color: Colors.grey, size: 20),
                    const SizedBox(width: 8),
                    Text('Unanswered: ${totalItems - _totalAnswered}'),
                  ],
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                onEndPractice();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('End Practice'),
            ),
          ],
        );
      },
    );
  }
}
