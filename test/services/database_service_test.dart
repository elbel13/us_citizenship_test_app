import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:us_citizenship_test_app/services/database_service.dart';
import '../helpers/database_test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Initialize ffi for testing
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('DatabaseService', () {
    late DatabaseService databaseService;
    late String testDbPath;

    setUp(() async {
      // Generate unique database path for this test
      testDbPath = DatabaseTestHelper.getUniqueDatabasePath();
      DatabaseService.setCustomDatabasePath(testDbPath);
      databaseService = DatabaseService();

      // Initialize database and load default questions
      await databaseService.database;
      await databaseService.loadQuestionsForYear('2020', 'en');
    });

    tearDown(() async {
      // Clean up this test's database
      try {
        await databaseService.close();
      } catch (e) {
        // Ignore errors during cleanup
      }
      // Reset custom path after closing
      DatabaseService.setCustomDatabasePath(null);
      try {
        await DatabaseTestHelper.deleteDatabaseFile(testDbPath);
      } catch (e) {
        // Ignore file deletion errors
      }
    });

    test('database initializes successfully', () async {
      final db = await databaseService.database;
      expect(db, isNotNull);
      expect(db.isOpen, true);
    });

    test('creates required tables on initialization', () async {
      final db = await databaseService.database;

      // Check if question table exists
      final questionTableExists = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='question'",
      );
      expect(questionTableExists.isNotEmpty, true);

      // Check if question_text table exists
      final questionTextTableExists = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='question_text'",
      );
      expect(questionTextTableExists.isNotEmpty, true);
    });

    test('creates index on question_text language_code', () async {
      final db = await databaseService.database;

      final indexExists = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='index' AND name='idx_question_text_language'",
      );
      expect(indexExists.isNotEmpty, true);
    });

    test('populates database from assets on first access', () async {
      // This test relies on the mock asset being loaded
      final questions = await databaseService.getQuestions('en');

      expect(questions, isNotEmpty);
      expect(questions.length, greaterThan(0));
    });

    test('getQuestions returns correct language questions', () async {
      final questionsEn = await databaseService.getQuestions('en');

      expect(questionsEn, isNotEmpty);
      for (var question in questionsEn) {
        expect(question.languageCode, 'en');
      }
    });

    test('getQuestions returns questions in order', () async {
      final questions = await databaseService.getQuestions('en');

      expect(questions, isNotEmpty);

      // Check if questions are ordered by question_id
      for (int i = 0; i < questions.length - 1; i++) {
        expect(questions[i].id, lessThanOrEqualTo(questions[i + 1].id));
      }
    });

    test('getQuestions returns empty list for non-existent language', () async {
      final questions = await databaseService.getQuestions('fr');

      expect(questions, isEmpty);
    });

    test('clearDatabase removes all data', () async {
      // First, ensure database is populated
      await databaseService.database;
      var questions = await databaseService.getQuestions('en');
      expect(questions, isNotEmpty);

      // Clear the database
      await databaseService.clearDatabase();

      // Verify it's empty
      questions = await databaseService.getQuestions('en');
      expect(questions, isEmpty);
    });

    test('database only populates once', () async {
      // Access database multiple times
      await databaseService.database;
      await databaseService.database;

      final questions = await databaseService.getQuestions('en');
      final count = questions.length;

      // Access again - should not duplicate data
      await databaseService.database;
      final questionsAfter = await databaseService.getQuestions('en');

      expect(questionsAfter.length, count);
    });

    test('Question data integrity after database operations', () async {
      final questions = await databaseService.getQuestions('en');

      expect(questions, isNotEmpty);

      final firstQuestion = questions.first;
      expect(firstQuestion.id, isNotNull);
      expect(firstQuestion.questionText, isNotEmpty);
      expect(firstQuestion.answerText, isNotEmpty);
      expect(firstQuestion.languageCode, 'en');
    });
  });
}
