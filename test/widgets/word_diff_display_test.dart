import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:us_citizenship_test_app/services/reading_evaluator.dart';
import 'package:us_citizenship_test_app/theme/word_diff_colors.dart';
import 'package:us_citizenship_test_app/widgets/word_diff_display.dart';

void main() {
  group('WordDiffDisplay Widget', () {
    // Helper to create a test theme with word diff colors
    ThemeData createTestTheme() {
      return ThemeData(
        extensions: const [
          WordDiffColors(
            correctWordColor: Colors.green,
            missingWordColor: Colors.grey,
            extraWordColor: Colors.orange,
          ),
        ],
      );
    }

    testWidgets('renders correct word with green styling', (
      WidgetTester tester,
    ) async {
      final wordDiffs = [
        WordDiff(word: 'Constitution', type: WordDiffType.correct),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: createTestTheme(),
          home: Scaffold(body: WordDiffDisplay(wordDiffs: wordDiffs)),
        ),
      );

      expect(find.text('Constitution'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byType(Chip), findsOneWidget);
    });

    testWidgets('renders wrong word with red styling', (
      WidgetTester tester,
    ) async {
      final wordDiffs = [
        WordDiff(word: 'freedom', type: WordDiffType.wrong, spokenAs: 'fredom'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: createTestTheme(),
          home: Scaffold(body: WordDiffDisplay(wordDiffs: wordDiffs)),
        ),
      );

      expect(find.text('freedom'), findsOneWidget);
      expect(find.byIcon(Icons.cancel), findsOneWidget);

      // Check tooltip
      final chip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(chip.message, contains('Wrong'));
      expect(chip.message, contains('fredom'));
    });

    testWidgets('renders missing word with grey styling', (
      WidgetTester tester,
    ) async {
      final wordDiffs = [WordDiff(word: 'supreme', type: WordDiffType.missing)];

      await tester.pumpWidget(
        MaterialApp(
          theme: createTestTheme(),
          home: Scaffold(body: WordDiffDisplay(wordDiffs: wordDiffs)),
        ),
      );

      expect(find.text('supreme'), findsOneWidget);
      expect(find.byIcon(Icons.remove_circle), findsOneWidget);

      final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tooltip.message, contains('Missing'));
    });

    testWidgets('renders added word with orange styling', (
      WidgetTester tester,
    ) async {
      final wordDiffs = [WordDiff(word: 'extra', type: WordDiffType.added)];

      await tester.pumpWidget(
        MaterialApp(
          theme: createTestTheme(),
          home: Scaffold(body: WordDiffDisplay(wordDiffs: wordDiffs)),
        ),
      );

      expect(find.text('extra'), findsOneWidget);
      expect(find.byIcon(Icons.add_circle), findsOneWidget);

      final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tooltip.message, contains('Extra word'));
    });

    testWidgets('renders multiple word diffs', (WidgetTester tester) async {
      final wordDiffs = [
        WordDiff(word: 'The', type: WordDiffType.correct),
        WordDiff(word: 'Constitution', type: WordDiffType.correct),
        WordDiff(word: 'is', type: WordDiffType.missing),
        WordDiff(word: 'supreme', type: WordDiffType.correct),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: createTestTheme(),
          home: Scaffold(body: WordDiffDisplay(wordDiffs: wordDiffs)),
        ),
      );

      expect(find.text('The'), findsOneWidget);
      expect(find.text('Constitution'), findsOneWidget);
      expect(find.text('is'), findsOneWidget);
      expect(find.text('supreme'), findsOneWidget);
      expect(find.byType(Chip), findsNWidgets(4));
    });

    testWidgets('uses Wrap layout for responsive display', (
      WidgetTester tester,
    ) async {
      final wordDiffs = [
        WordDiff(word: 'word1', type: WordDiffType.correct),
        WordDiff(word: 'word2', type: WordDiffType.correct),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: createTestTheme(),
          home: Scaffold(body: WordDiffDisplay(wordDiffs: wordDiffs)),
        ),
      );

      final wrap = tester.widget<Wrap>(find.byType(Wrap));
      expect(wrap.spacing, 8.0);
      expect(wrap.runSpacing, 8.0);
    });

    testWidgets('handles empty word diffs list', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: createTestTheme(),
          home: const Scaffold(body: WordDiffDisplay(wordDiffs: [])),
        ),
      );

      expect(find.byType(Chip), findsNothing);
      expect(find.byType(Wrap), findsOneWidget);
    });

    testWidgets('all correct words show check icons', (
      WidgetTester tester,
    ) async {
      final wordDiffs = [
        WordDiff(word: 'All', type: WordDiffType.correct),
        WordDiff(word: 'words', type: WordDiffType.correct),
        WordDiff(word: 'correct', type: WordDiffType.correct),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: createTestTheme(),
          home: Scaffold(body: WordDiffDisplay(wordDiffs: wordDiffs)),
        ),
      );

      expect(find.byIcon(Icons.check_circle), findsNWidgets(3));
    });

    testWidgets('mixed word types display different icons', (
      WidgetTester tester,
    ) async {
      final wordDiffs = [
        WordDiff(word: 'correct', type: WordDiffType.correct),
        WordDiff(word: 'wrong', type: WordDiffType.wrong, spokenAs: 'rong'),
        WordDiff(word: 'missing', type: WordDiffType.missing),
        WordDiff(word: 'added', type: WordDiffType.added),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: createTestTheme(),
          home: Scaffold(body: WordDiffDisplay(wordDiffs: wordDiffs)),
        ),
      );

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byIcon(Icons.cancel), findsOneWidget);
      expect(find.byIcon(Icons.remove_circle), findsOneWidget);
      expect(find.byIcon(Icons.add_circle), findsOneWidget);
    });

    testWidgets('tooltips show appropriate messages', (
      WidgetTester tester,
    ) async {
      final wordDiffs = [WordDiff(word: 'correct', type: WordDiffType.correct)];

      await tester.pumpWidget(
        MaterialApp(
          theme: createTestTheme(),
          home: Scaffold(body: WordDiffDisplay(wordDiffs: wordDiffs)),
        ),
      );

      final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tooltip.message, 'Correct');
    });

    testWidgets('handles long words correctly', (WidgetTester tester) async {
      final wordDiffs = [
        WordDiff(word: 'uncharacteristically', type: WordDiffType.correct),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: createTestTheme(),
          home: Scaffold(body: WordDiffDisplay(wordDiffs: wordDiffs)),
        ),
      );

      expect(find.text('uncharacteristically'), findsOneWidget);
    });

    testWidgets('each chip has an avatar icon', (WidgetTester tester) async {
      final wordDiffs = [WordDiff(word: 'test', type: WordDiffType.correct)];

      await tester.pumpWidget(
        MaterialApp(
          theme: createTestTheme(),
          home: Scaffold(body: WordDiffDisplay(wordDiffs: wordDiffs)),
        ),
      );

      final chip = tester.widget<Chip>(find.byType(Chip));
      expect(chip.avatar, isNotNull);
      expect(chip.avatar, isA<Icon>());
    });

    testWidgets('chips have colored borders', (WidgetTester tester) async {
      final wordDiffs = [WordDiff(word: 'test', type: WordDiffType.correct)];

      await tester.pumpWidget(
        MaterialApp(
          theme: createTestTheme(),
          home: Scaffold(body: WordDiffDisplay(wordDiffs: wordDiffs)),
        ),
      );

      final chip = tester.widget<Chip>(find.byType(Chip));
      expect(chip.side, isNotNull);
      expect(chip.side, isA<BorderSide>());
    });

    testWidgets('handles special characters in words', (
      WidgetTester tester,
    ) async {
      final wordDiffs = [
        WordDiff(word: "can't", type: WordDiffType.correct),
        WordDiff(word: 'U.S.', type: WordDiffType.correct),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: createTestTheme(),
          home: Scaffold(body: WordDiffDisplay(wordDiffs: wordDiffs)),
        ),
      );

      expect(find.text("can't"), findsOneWidget);
      expect(find.text('U.S.'), findsOneWidget);
    });
  });
}
