import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:us_citizenship_test_app/widgets/circular_action_button.dart';

void main() {
  group('CircularActionButton Widget', () {
    testWidgets('renders with basic properties', (WidgetTester tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CircularActionButton(
              onTap: () => tapped = true,
              icon: Icons.mic,
            ),
          ),
        ),
      );

      expect(find.byType(CircularActionButton), findsOneWidget);
      expect(find.byIcon(Icons.mic), findsOneWidget);

      await tester.tap(find.byType(InkWell));
      expect(tapped, true);
    });

    testWidgets('displays custom color', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CircularActionButton(
              onTap: () {},
              icon: Icons.play_arrow,
              color: Colors.green,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(InkWell),
          matching: find.byType(Container),
        ),
      );

      expect((container.decoration as BoxDecoration).color, Colors.green);
    });

    testWidgets('has correct dimensions', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CircularActionButton(onTap: () {}, icon: Icons.mic),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(InkWell),
          matching: find.byType(Container),
        ),
      );

      expect(container.constraints?.maxWidth, 100);
      expect(container.constraints?.maxHeight, 100);
    });

    testWidgets('displays shadow when active', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CircularActionButton(
              onTap: () {},
              icon: Icons.mic,
              color: Colors.red,
              isActive: true,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(InkWell),
          matching: find.byType(Container),
        ),
      );

      final boxDecoration = container.decoration as BoxDecoration;
      expect(boxDecoration.boxShadow, isNotNull);
      expect(boxDecoration.boxShadow!.length, 1);
    });

    testWidgets('does not display shadow when inactive', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CircularActionButton(
              onTap: () {},
              icon: Icons.mic,
              isActive: false,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(InkWell),
          matching: find.byType(Container),
        ),
      );

      final boxDecoration = container.decoration as BoxDecoration;
      expect(boxDecoration.boxShadow, isNull);
    });

    testWidgets('displays progress indicator when showProgress is true', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CircularActionButton(
              onTap: () {},
              icon: Icons.mic,
              showProgress: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.mic), findsNothing);
    });

    testWidgets('displays icon when showProgress is false', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CircularActionButton(
              onTap: () {},
              icon: Icons.mic,
              showProgress: false,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.mic), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('displays status text when provided', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CircularActionButton(
              onTap: () {},
              icon: Icons.mic,
              statusText: 'Tap to record',
            ),
          ),
        ),
      );

      expect(find.text('Tap to record'), findsOneWidget);
    });

    testWidgets('does not display status text when null', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CircularActionButton(onTap: () {}, icon: Icons.mic),
          ),
        ),
      );

      // When statusText is null, there should be no Text widgets
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('handles null onTap gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CircularActionButton(onTap: null, icon: Icons.mic),
          ),
        ),
      );

      await tester.tap(find.byType(InkWell));
      await tester.pump();

      // Should not throw
      expect(find.byType(CircularActionButton), findsOneWidget);
    });

    testWidgets('different icons are displayed correctly', (
      WidgetTester tester,
    ) async {
      final icons = [Icons.mic, Icons.play_arrow, Icons.stop, Icons.pause];

      for (final icon in icons) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CircularActionButton(onTap: () {}, icon: icon),
            ),
          ),
        );

        expect(find.byIcon(icon), findsOneWidget);
      }
    });

    testWidgets('has circular shape', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CircularActionButton(onTap: () {}, icon: Icons.mic),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(InkWell),
          matching: find.byType(Container),
        ),
      );

      final boxDecoration = container.decoration as BoxDecoration;
      expect(boxDecoration.shape, BoxShape.circle);
    });

    testWidgets('icon has white color', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CircularActionButton(onTap: () {}, icon: Icons.mic),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.mic));
      expect(icon.color, Colors.white);
    });

    testWidgets('icon has correct size', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CircularActionButton(onTap: () {}, icon: Icons.mic),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.mic));
      expect(icon.size, 50);
    });

    testWidgets('status text has correct spacing', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CircularActionButton(
              onTap: () {},
              icon: Icons.mic,
              statusText: 'Test Status',
            ),
          ),
        ),
      );

      final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
      final spacingBox = sizedBoxes.firstWhere((box) => box.height == 12);

      expect(spacingBox.height, 12);
    });

    testWidgets('combines multiple states correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CircularActionButton(
              onTap: () {},
              icon: Icons.mic,
              color: Colors.purple,
              isActive: true,
              showProgress: false,
              statusText: 'Recording',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.mic), findsOneWidget);
      expect(find.text('Recording'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(InkWell),
          matching: find.byType(Container),
        ),
      );

      final boxDecoration = container.decoration as BoxDecoration;
      expect(boxDecoration.color, Colors.purple);
      expect(boxDecoration.boxShadow, isNotNull);
    });
  });
}
