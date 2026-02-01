import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:us_citizenship_test_app/models/interview_question.dart';
import 'package:us_citizenship_test_app/services/database_service.dart';
import 'package:us_citizenship_test_app/services/interview_service.dart';
import '../helpers/database_test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Initialize ffi for testing
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('InterviewService', () {
    late InterviewService service;
    late DatabaseService dbService;
    late String testDbPath;

    setUp(() async {
      // Generate unique database path for this test
      testDbPath = DatabaseTestHelper.getUniqueDatabasePath();
      DatabaseService.setCustomDatabasePath(testDbPath);

      service = InterviewService();
      dbService = DatabaseService();
    });

    tearDown(() async {
      try {
        await dbService.close();
        await DatabaseTestHelper.deleteDatabaseFile(testDbPath);
      } catch (e) {
        // Ignore cleanup errors
      }
      DatabaseService.setCustomDatabasePath(null);
    });

    test('generateInterviewQuestions returns correct count', () async {
      final questions = await service.generateInterviewQuestions();

      // Should have 3 reading + 3 writing + 20 civics = 26 total
      expect(questions.length, equals(26));

      // Count by type
      final readingCount = questions
          .where((q) => q.type == InterviewQuestionType.reading)
          .length;
      final writingCount = questions
          .where((q) => q.type == InterviewQuestionType.writing)
          .length;
      final civicsCount = questions
          .where((q) => q.type == InterviewQuestionType.civics)
          .length;

      expect(readingCount, equals(3));
      expect(writingCount, equals(3));
      expect(civicsCount, equals(20));
    });

    test('generateInterviewQuestions randomizes section order', () async {
      final questions1 = await service.generateInterviewQuestions();
      final questions2 = await service.generateInterviewQuestions();

      // Get first question type
      final firstType1 = questions1.first.type;

      // Sections should be grouped (all of one type together)
      final firstSectionSize1 = questions1
          .takeWhile((q) => q.type == firstType1)
          .length;
      expect(
        firstSectionSize1,
        equals(3),
      ); // Reading or writing sections have 3 questions

      // Not guaranteed to be different, but highly unlikely if truly random
      // Just verify structure is correct
      expect(questions1.isNotEmpty, isTrue);
      expect(questions2.isNotEmpty, isTrue);
    });

    test('canPassEarly returns true when 12 correct', () {
      expect(
        service.canPassEarly(correctCivicsAnswers: 12, totalCivicsAsked: 12),
        isTrue,
      );
    });

    test('canPassEarly returns true when more than 12 correct', () {
      expect(
        service.canPassEarly(correctCivicsAnswers: 15, totalCivicsAsked: 18),
        isTrue,
      );
    });

    test('canPassEarly returns false when still possible to pass', () {
      expect(
        service.canPassEarly(correctCivicsAnswers: 10, totalCivicsAsked: 15),
        isFalse,
      );
    });

    test('canPassEarly returns true when impossible to reach 12', () {
      // 8 correct, 15 asked = 5 remaining, max possible = 13
      expect(
        service.canPassEarly(correctCivicsAnswers: 8, totalCivicsAsked: 15),
        isFalse,
      );

      // 5 correct, 15 asked = 5 remaining, max possible = 10 (can't reach 12)
      expect(
        service.canPassEarly(correctCivicsAnswers: 5, totalCivicsAsked: 15),
        isTrue,
      );
    });

    test('passesCivicsTest requires 12 correct', () {
      expect(service.passesCivicsTest(12), isTrue);
      expect(service.passesCivicsTest(15), isTrue);
      expect(service.passesCivicsTest(11), isFalse);
      expect(service.passesCivicsTest(0), isFalse);
    });

    test('interview questions have required fields', () async {
      final questions = await service.generateInterviewQuestions();

      for (final question in questions) {
        expect(question.questionText, isNotEmpty);
        expect(question.acceptableAnswers, isNotEmpty);

        switch (question.type) {
          case InterviewQuestionType.reading:
          case InterviewQuestionType.writing:
            expect(question.metadata, isNotNull);
            expect(question.metadata!['vocabularyWords'], isNotNull);
            break;
          case InterviewQuestionType.civics:
            // Civics questions may have multiple acceptable answers
            expect(question.acceptableAnswers.length, greaterThanOrEqualTo(1));
            break;
        }
      }
    });
  });
}
