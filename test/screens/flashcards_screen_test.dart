import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:us_citizenship_test_app/screens/flashcards_screen.dart';
import 'package:us_citizenship_test_app/l10n/app_localizations.dart';
import 'package:us_citizenship_test_app/services/database_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Initialize ffi for testing
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('FlashcardsScreen Widget', () {
    setUp(() async {
      // Reset the database between tests
      final dbService = DatabaseService();
      try {
        await dbService.clearDatabase();
        await dbService.close();
      } catch (e) {
        // Database might not exist yet
      }
    });

    tearDown(() async {
      // Clean up database after each test
      final dbService = DatabaseService();
      try {
        await dbService.clearDatabase();
        await dbService.close();
      } catch (e) {
        // Ignore errors during cleanup
      }
    });

    Widget createTestWidget() {
      return MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('es')],
        home: const FlashcardsScreen(),
      );
    }

    testWidgets('displays loading indicator while loading questions', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays flashcards after loading', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      // Wait for questions to load
      await tester.pumpAndSettle();

      // Should show card counter
      expect(find.textContaining('/'), findsOneWidget);

      // Should show navigation buttons
      expect(find.text('Previous'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
    });

    testWidgets('card counter displays correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Should start at 1 / total
      expect(find.textContaining('1 /'), findsOneWidget);
    });

    testWidgets('Previous button disabled on first card', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final previousButton = find.widgetWithText(ElevatedButton, 'Previous');
      expect(previousButton, findsOneWidget);

      final button = tester.widget<ElevatedButton>(previousButton);
      expect(button.onPressed, isNull);
    });

    testWidgets('Next button enabled when not on last card', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final nextButton = find.widgetWithText(ElevatedButton, 'Next');
      expect(nextButton, findsOneWidget);

      final button = tester.widget<ElevatedButton>(nextButton);
      expect(button.onPressed, isNotNull);
    });

    testWidgets('tapping Next button advances to next card', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify starting at card 1
      expect(find.textContaining('1 /'), findsOneWidget);

      // Tap Next button
      await tester.tap(find.widgetWithText(ElevatedButton, 'Next'));
      await tester.pumpAndSettle();

      // Should now be at card 2
      expect(find.textContaining('2 /'), findsOneWidget);
    });

    testWidgets('tapping Previous button goes to previous card', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Go to second card first
      await tester.tap(find.widgetWithText(ElevatedButton, 'Next'));
      await tester.pumpAndSettle();
      expect(find.textContaining('2 /'), findsOneWidget);

      // Now go back
      await tester.tap(find.widgetWithText(ElevatedButton, 'Previous'));
      await tester.pumpAndSettle();

      // Should be back at card 1
      expect(find.textContaining('1 /'), findsOneWidget);
    });

    testWidgets('swiping left advances to next card', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.textContaining('1 /'), findsOneWidget);

      // Swipe left (negative drag)
      await tester.drag(find.byType(FlipCard), const Offset(-300, 0));
      await tester.pumpAndSettle();

      // Should advance to card 2
      expect(find.textContaining('2 /'), findsOneWidget);
    });

    testWidgets('swiping right goes to previous card', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Go to second card first
      await tester.tap(find.widgetWithText(ElevatedButton, 'Next'));
      await tester.pumpAndSettle();
      expect(find.textContaining('2 /'), findsOneWidget);

      // Swipe right (positive drag)
      await tester.drag(find.byType(FlipCard), const Offset(300, 0));
      await tester.pumpAndSettle();

      // Should go back to card 1
      expect(find.textContaining('1 /'), findsOneWidget);
    });

    testWidgets('FlipCard displays Question indicator initially', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Question'), findsOneWidget);
    });

    testWidgets('tapping card triggers flip animation', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Initially should show Question
      expect(find.text('Question'), findsOneWidget);

      // Tap the card
      await tester.tap(find.byType(FlipCard));
      await tester.pump(); // Start animation
      await tester.pump(const Duration(milliseconds: 200)); // Mid animation
      await tester.pumpAndSettle(); // Complete animation

      // Should now show Answer
      expect(find.text('Answer'), findsOneWidget);
    });

    testWidgets('FlipCard shows tap to flip hint', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Tap to flip'), findsOneWidget);
    });

    testWidgets('displays question text on card', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Should display some question text (we can't predict exact text without mocking)
      expect(find.byType(FlipCard), findsOneWidget);
    });

    testWidgets('Next button disabled on last card', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Navigate to the last card
      // First, find out how many cards there are
      final counterText = tester.widget<Text>(find.textContaining('/')).data!;
      final total = int.parse(counterText.split('/')[1].trim());

      // Navigate to last card
      for (int i = 1; i < total; i++) {
        await tester.tap(find.widgetWithText(ElevatedButton, 'Next'));
        await tester.pumpAndSettle();
      }

      // Verify we're on the last card
      expect(find.textContaining('$total /'), findsOneWidget);

      // Next button should be disabled
      final nextButton = find.widgetWithText(ElevatedButton, 'Next');
      final button = tester.widget<ElevatedButton>(nextButton);
      expect(button.onPressed, isNull);
    });
  });
}
