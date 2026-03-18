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
      await databaseService.loadQuestionsForYear('2025', 'en');
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

    group('getWrongAnswersByCategories', () {
      test('excludes answers that belong to the target question', () async {
        final questions = await databaseService.getQuestions('en');
        expect(questions, isNotEmpty);

        final targetQuestion = questions.first;
        final correctTexts = targetQuestion.answers
            .map((a) => a.answerText)
            .toSet();
        final categoryIds = targetQuestion.answers
            .map((a) => a.categoryId)
            .toSet()
            .toList();

        final wrong = await databaseService.getWrongAnswersByCategories(
          targetQuestion.id,
          categoryIds,
          10,
        );

        // None of the returned distractors should be a correct answer for
        // the target question (the SQL WHERE qt.question_id != ? guarantee).
        for (final w in wrong) {
          expect(
            correctTexts,
            isNot(contains(w)),
            reason:
                'Distractor "$w" should not appear in the target '
                "question's own answer list",
          );
        }
      });

      test('returns no more answers than requested', () async {
        final questions = await databaseService.getQuestions('en');
        expect(questions, isNotEmpty);

        final targetQuestion = questions.first;
        final categoryIds = targetQuestion.answers
            .map((a) => a.categoryId)
            .toSet()
            .toList();

        const limit = 3;
        final wrong = await databaseService.getWrongAnswersByCategories(
          targetQuestion.id,
          categoryIds,
          limit,
        );

        expect(wrong.length, lessThanOrEqualTo(limit));
      });

      test('returns empty list for empty category list', () async {
        final questions = await databaseService.getQuestions('en');
        expect(questions, isNotEmpty);

        final wrong = await databaseService.getWrongAnswersByCategories(
          questions.first.id,
          [], // no categories
          5,
        );

        expect(wrong, isEmpty);
      });

      test(
        'can return answer text that exists on a different question row '
        '(the cross-question duplicate scenario that the screen fix addresses)',
        () async {
          final db = await databaseService.database;

          // Use a dedicated isolated category so the only distractor available
          // in that category is the one we insert on the sibling question.
          // This guarantees the duplicate text is always returned by the query
          // regardless of RANDOM() ordering.
          const isolatedCategoryId = 99998;
          const siblingQuestionId = 99999;

          // Register the isolated category.
          await db.insert('answer_category', {
            'id': isolatedCategoryId,
            'category_name': 'TEST_ISOLATED_CATEGORY',
          }, conflictAlgorithm: ConflictAlgorithm.ignore);

          // Create the target question with one answer in the isolated category.
          const targetQuestionId = 99997;
          const duplicateText = 'A unique duplicate answer for this test';

          await db.insert('question', {'id': targetQuestionId});
          final targetQtId = await db.insert('question_text', {
            'question_id': targetQuestionId,
            'language_code': 'en',
            'question_text': 'Target question for duplicate-answer test?',
          });
          await db.insert('answer', {
            'question_text_id': targetQtId,
            'answer_text': duplicateText,
            'category_id': isolatedCategoryId,
          });

          // Create a sibling question whose answer text is identical to the
          // target's correct answer, in the same isolated category.
          await db.insert('question', {'id': siblingQuestionId});
          final siblingQtId = await db.insert('question_text', {
            'question_id': siblingQuestionId,
            'language_code': 'en',
            'question_text': 'Sibling question for duplicate-answer test?',
          });
          await db.insert('answer', {
            'question_text_id': siblingQtId,
            'answer_text': duplicateText,
            'category_id': isolatedCategoryId,
          });

          // Request distractors for the target question using only the
          // isolated category. The sibling's identical answer text is the
          // only available candidate — the DB query WILL return it because
          // it lives on a different question row (question_id != targetQuestionId).
          final wrong = await databaseService.getWrongAnswersByCategories(
            targetQuestionId,
            [isolatedCategoryId],
            5,
          );

          // This confirms the bug scenario: the raw query returns a text that
          // duplicates the correct answer. The screen-level filter introduced
          // by the fix is responsible for removing it.
          expect(
            wrong,
            contains(duplicateText),
            reason:
                'The DB query returns the duplicate text from the sibling '
                'question; the screen-level filter is responsible for removing it.',
          );
        },
      );
    });
  });
}
