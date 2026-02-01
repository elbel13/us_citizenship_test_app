import 'package:flutter_test/flutter_test.dart';
import 'package:us_citizenship_test_app/models/interview_question.dart';
import 'package:us_citizenship_test_app/services/interview_prompt_service.dart';
import 'package:us_citizenship_test_app/services/reading_evaluator.dart';

void main() {
  group('InterviewPromptService', () {
    late InterviewPromptService service;

    setUp(() {
      service = InterviewPromptService();
    });

    test('getGreetingPrompt returns professional greeting', () {
      final prompt = service.getGreetingPrompt();

      // Should return one of the greeting variations
      expect(prompt, isNotEmpty);
      expect(
        prompt.contains('Welcome') ||
            prompt.contains('Hello') ||
            prompt.contains('Good'),
        isTrue,
      );
    });

    test('getReadingQuestionPrompt returns instruction', () {
      final prompt = service.getReadingQuestionPrompt(
        'The Constitution is important',
      );

      expect(prompt, isNotEmpty);
      expect(prompt.contains('read'), isTrue);
    });

    test('getWritingQuestionPrompt includes sentence', () {
      final prompt = service.getWritingQuestionPrompt('Freedom of speech');

      expect(prompt, contains('Freedom of speech'));
      expect(prompt.contains('write') || prompt.contains('dictate'), isTrue);
    });

    test('getCivicsQuestionPrompt returns question', () {
      final prompt = service.getCivicsQuestionPrompt(
        'Who was the first President?',
      );

      expect(prompt, contains('Who was the first President?'));
    });

    group('getResponsePrompt', () {
      test('pass result returns positive acknowledgment', () {
        final prompt = service.getResponsePrompt(
          questionType: InterviewQuestionType.civics,
          result: EvaluationResult.pass,
          question: 'Who was the first President?',
          userAnswer: 'George Washington',
          attemptNumber: 1,
        );

        expect(prompt, isNotEmpty);
        expect(
          prompt.contains('correct') ||
              prompt.contains('Good') ||
              prompt.contains('Very'),
          isTrue,
        );
      });

      test('pass result is consistent across attempts', () {
        final prompt1 = service.getResponsePrompt(
          questionType: InterviewQuestionType.civics,
          result: EvaluationResult.pass,
          question: 'Who was the first President?',
          userAnswer: 'George Washington',
          attemptNumber: 1,
        );

        final prompt2 = service.getResponsePrompt(
          questionType: InterviewQuestionType.civics,
          result: EvaluationResult.pass,
          question: 'Who was the first President?',
          userAnswer: 'George Washington',
          attemptNumber: 3,
        );

        // Both should be positive responses
        expect(prompt1, isNotEmpty);
        expect(prompt2, isNotEmpty);
      });

      test('partial result on first attempt requests more information', () {
        final prompt = service.getResponsePrompt(
          questionType: InterviewQuestionType.civics,
          result: EvaluationResult.partial,
          question: 'Who was the first President?',
          userAnswer: 'Washington',
          attemptNumber: 1,
        );

        expect(
          prompt.contains('more') ||
              prompt.contains('elaborate') ||
              prompt.contains('details'),
          isTrue,
        );
      });

      test('partial result after max attempts moves on', () {
        final prompt = service.getResponsePrompt(
          questionType: InterviewQuestionType.civics,
          result: EvaluationResult.partial,
          question: 'Who was the first President?',
          userAnswer: 'Washington',
          attemptNumber: 3,
        );

        expect(
          prompt.contains('move on') ||
              prompt.contains('next question') ||
              prompt.contains('Okay'),
          isTrue,
        );
      });

      test('fail result on first attempt offers retry', () {
        final prompt = service.getResponsePrompt(
          questionType: InterviewQuestionType.civics,
          result: EvaluationResult.fail,
          question: 'Who was the first President?',
          userAnswer: 'Abraham Lincoln',
          attemptNumber: 1,
        );

        expect(prompt.contains('again') || prompt.contains('repeat'), isTrue);
      });

      test('fail result after max attempts moves on', () {
        final prompt = service.getResponsePrompt(
          questionType: InterviewQuestionType.civics,
          result: EvaluationResult.fail,
          question: 'Who was the first President?',
          userAnswer: 'Wrong answer',
          attemptNumber: 3,
        );

        expect(
          prompt.contains('Next question') || prompt.contains('continue'),
          isTrue,
        );
      });

      test('all question types use same response logic', () {
        final readingPrompt = service.getResponsePrompt(
          questionType: InterviewQuestionType.reading,
          result: EvaluationResult.pass,
          question: 'The Constitution',
          userAnswer: 'The Constitution',
          attemptNumber: 1,
        );

        final writingPrompt = service.getResponsePrompt(
          questionType: InterviewQuestionType.writing,
          result: EvaluationResult.pass,
          question: 'Freedom',
          userAnswer: 'Freedom',
          attemptNumber: 1,
        );

        final civicsPrompt = service.getResponsePrompt(
          questionType: InterviewQuestionType.civics,
          result: EvaluationResult.pass,
          question: 'First President?',
          userAnswer: 'Washington',
          attemptNumber: 1,
        );

        // All should return valid responses
        expect(readingPrompt, isNotEmpty);
        expect(writingPrompt, isNotEmpty);
        expect(civicsPrompt, isNotEmpty);
      });
    });

    test('getSectionTransitionPrompt provides transition', () {
      final prompt = service.getSectionTransitionPrompt(
        fromSection: InterviewQuestionType.reading,
        toSection: InterviewQuestionType.civics,
      );

      expect(prompt, contains('civics'));
    });

    test('getCompletionPrompt for passing includes congratulations', () {
      final prompt = service.getCompletionPrompt(
        passed: true,
        civicsCorrect: 15,
        civicsTotal: 20,
      );

      expect(
        prompt.contains('Congratulations') ||
            prompt.contains('passed') ||
            prompt.contains('completed'),
        isTrue,
      );
    });

    test('getCompletionPrompt for failing is respectful', () {
      final prompt = service.getCompletionPrompt(
        passed: false,
        civicsCorrect: 8,
        civicsTotal: 20,
      );

      expect(prompt, contains('Thank you'));
    });

    test('cleanResponse removes quotes and normalizes whitespace', () {
      expect(service.cleanResponse('"Hello   world"'), equals('Hello world'));

      expect(service.cleanResponse('  "Test"  '), equals('Test'));

      expect(
        service.cleanResponse('Multiple   spaces   here'),
        equals('Multiple spaces here'),
      );
    });
  });
}
