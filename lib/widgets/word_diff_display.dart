import 'package:flutter/material.dart';
import '../services/reading_evaluator.dart';
import '../theme/word_diff_colors.dart';

/// Widget to display word-by-word diff with colors and icons
class WordDiffDisplay extends StatelessWidget {
  final List<WordDiff> wordDiffs;

  const WordDiffDisplay({super.key, required this.wordDiffs});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: wordDiffs.map((diff) => _buildWordChip(context, diff)).toList(),
    );
  }

  Widget _buildWordChip(BuildContext context, WordDiff diff) {
    final colors = Theme.of(context).extension<WordDiffColors>()!;
    Color backgroundColor;
    Color textColor;
    IconData icon;
    String tooltip;

    switch (diff.type) {
      case WordDiffType.correct:
        backgroundColor = Colors.green.withOpacity(0.2);
        textColor = colors.correctWordColor;
        icon = Icons.check_circle;
        tooltip = 'Correct';
        break;
      case WordDiffType.wrong:
        backgroundColor = Colors.red.withOpacity(0.2);
        textColor = Colors.red.shade800;
        icon = Icons.cancel;
        tooltip = 'Wrong (you said: "${diff.spokenAs}")';
        break;
      case WordDiffType.missing:
        backgroundColor = Colors.grey.withOpacity(0.2);
        textColor = colors.missingWordColor;
        icon = Icons.remove_circle;
        tooltip = 'Missing - not spoken';
        break;
      case WordDiffType.added:
        backgroundColor = Colors.orange.withOpacity(0.2);
        textColor = colors.extraWordColor;
        icon = Icons.add_circle;
        tooltip = 'Extra word added';
        break;
    }

    return Tooltip(
      message: tooltip,
      child: Chip(
        avatar: Icon(icon, size: 16, color: textColor),
        label: Text(
          diff.word,
          style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
        ),
        backgroundColor: backgroundColor,
        side: BorderSide(color: textColor.withOpacity(0.3)),
      ),
    );
  }
}
