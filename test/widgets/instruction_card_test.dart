import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:us_citizenship_test_app/widgets/instruction_card.dart';
import 'package:us_citizenship_test_app/widgets/progress_indicator_widget.dart';

void main() {
  group('InstructionCard Widget', () {
    testWidgets('renders with text', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InstructionCard(text: 'Read the following sentence aloud'),
          ),
        ),
      );

      expect(find.text('Read the following sentence aloud'), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('uses default padding when not specified', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: InstructionCard(text: 'Test text')),
        ),
      );

      final padding = tester.widget<Padding>(
        find
            .descendant(of: find.byType(Card), matching: find.byType(Padding))
            .last,
      );

      expect(padding.padding, const EdgeInsets.all(12.0));
    });

    testWidgets('uses custom padding when specified', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InstructionCard(
              text: 'Test text',
              padding: EdgeInsets.all(20.0),
            ),
          ),
        ),
      );

      final padding = tester.widget<Padding>(
        find
            .descendant(of: find.byType(Card), matching: find.byType(Padding))
            .last,
      );

      expect(padding.padding, const EdgeInsets.all(20.0));
    });

    testWidgets('uses custom text style when specified', (
      WidgetTester tester,
    ) async {
      const customStyle = TextStyle(fontSize: 20, fontWeight: FontWeight.bold);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InstructionCard(text: 'Test text', textStyle: customStyle),
          ),
        ),
      );

      final text = tester.widget<Text>(find.text('Test text'));
      expect(text.style?.fontSize, 20);
      expect(text.style?.fontWeight, FontWeight.bold);
    });

    testWidgets('text is center aligned', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: InstructionCard(text: 'Test text')),
        ),
      );

      final text = tester.widget<Text>(find.text('Test text'));
      expect(text.textAlign, TextAlign.center);
    });

    testWidgets('handles long text', (WidgetTester tester) async {
      const longText =
          'This is a very long instruction that should '
          'wrap properly within the card widget and be displayed correctly';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: InstructionCard(text: longText)),
        ),
      );

      expect(find.text(longText), findsOneWidget);
    });
  });

  group('ProgressIndicatorWidget', () {
    testWidgets('displays progress with current index', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProgressIndicatorWidget(
              currentIndex: 0,
              totalItems: 10,
              correctAnswers: 5,
              incorrectAnswers: 2,
              itemLabel: 'Question',
            ),
          ),
        ),
      );

      expect(find.text('Question 1 of 10'), findsOneWidget);
      expect(find.text('Score: 5 correct, 2 incorrect'), findsOneWidget);
    });

    testWidgets('displays progress without current index', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProgressIndicatorWidget(
              totalItems: 20,
              correctAnswers: 8,
              incorrectAnswers: 3,
              itemLabel: 'Sentence',
            ),
          ),
        ),
      );

      expect(find.text('Sentences: 11 of 20'), findsOneWidget);
      expect(find.text('Score: 8 correct, 3 incorrect'), findsOneWidget);
    });

    testWidgets('uses default itemLabel when not specified', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProgressIndicatorWidget(
              currentIndex: 5,
              totalItems: 15,
              correctAnswers: 3,
              incorrectAnswers: 1,
            ),
          ),
        ),
      );

      expect(find.text('Item 6 of 15'), findsOneWidget);
    });

    testWidgets('displays zero scores correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProgressIndicatorWidget(
              currentIndex: 0,
              totalItems: 10,
              correctAnswers: 0,
              incorrectAnswers: 0,
              itemLabel: 'Question',
            ),
          ),
        ),
      );

      expect(find.text('Score: 0 correct, 0 incorrect'), findsOneWidget);
    });

    testWidgets('displays high scores correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProgressIndicatorWidget(
              currentIndex: 99,
              totalItems: 100,
              correctAnswers: 95,
              incorrectAnswers: 4,
              itemLabel: 'Question',
            ),
          ),
        ),
      );

      expect(find.text('Question 100 of 100'), findsOneWidget);
      expect(find.text('Score: 95 correct, 4 incorrect'), findsOneWidget);
    });

    testWidgets('calculates total answered correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProgressIndicatorWidget(
              totalItems: 30,
              correctAnswers: 10,
              incorrectAnswers: 5,
              itemLabel: 'Test',
            ),
          ),
        ),
      );

      // Total answered = 10 + 5 = 15
      expect(find.text('Tests: 15 of 30'), findsOneWidget);
    });

    testWidgets('handles different item labels', (WidgetTester tester) async {
      final labels = ['Question', 'Sentence', 'Word', 'Task'];

      for (final label in labels) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ProgressIndicatorWidget(
                currentIndex: 0,
                totalItems: 5,
                correctAnswers: 1,
                incorrectAnswers: 0,
                itemLabel: label,
              ),
            ),
          ),
        );

        expect(find.text('$label 1 of 5'), findsOneWidget);
      }
    });

    testWidgets('has correct layout structure', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProgressIndicatorWidget(
              currentIndex: 0,
              totalItems: 10,
              correctAnswers: 5,
              incorrectAnswers: 2,
            ),
          ),
        ),
      );

      expect(find.byType(Container), findsOneWidget);
      expect(find.byType(Column), findsOneWidget);

      final container = tester.widget<Container>(find.byType(Container));
      expect(container.padding, const EdgeInsets.all(16.0));

      final column = tester.widget<Column>(find.byType(Column));
      expect(column.children.length, 3); // Text, SizedBox, Text
    });

    testWidgets('displays correct spacing between elements', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProgressIndicatorWidget(
              currentIndex: 0,
              totalItems: 10,
              correctAnswers: 5,
              incorrectAnswers: 2,
            ),
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox));
      expect(sizedBox.height, 8);
    });

    testWidgets('handles last item correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProgressIndicatorWidget(
              currentIndex: 9,
              totalItems: 10,
              correctAnswers: 8,
              incorrectAnswers: 1,
              itemLabel: 'Question',
            ),
          ),
        ),
      );

      expect(find.text('Question 10 of 10'), findsOneWidget);
    });
  });
}
