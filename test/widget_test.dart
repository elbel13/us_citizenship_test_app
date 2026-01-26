import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:us_citizenship_test_app/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Initialize ffi for testing
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  testWidgets('App loads and displays main menu', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const USCitizenshipTestApp());
    await tester.pumpAndSettle();

    // Verify that main menu title is displayed
    expect(find.text('Main Menu'), findsOneWidget);

    // Verify at least one menu option is present
    expect(find.text('Flashcards'), findsOneWidget);
  });
}
