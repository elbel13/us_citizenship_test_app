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

      expect(prompt, contains('USCIS'));
      expect(prompt, contains('citizenship interview'));
      expect(prompt, contains('brief'));
    });

    test('getReadingQuestionPrompt includes sentence', () {
      final prompt = service.getReadingQuestionPrompt(
        'The Constitution is important',
      );

      expect(prompt, contains('read'));
      expect(prompt, contains('The Constitution is important'));
      expect(prompt, contains('professional'));
    });

    test('getWritingQuestionPrompt includes dictation instruction', () {
      final prompt = service.getWritingQuestionPrompt('Freedom of speech');

      expect(prompt, contains('Dictate'));
      expect(prompt, contains('Freedom of speech'));
      expect(prompt, contains('write'));
    });

    test('getCivicsQuestionPrompt includes question', () {
      final prompt = service.getCivicsQuestionPrompt(
        'Who was the first President?',
      );

      expect(prompt, contains('Who was the first President?'));
      expect(prompt, contains('citizenship question'));
    });

    group('getResponsePrompt', () {
      test('pass result on first attempt gives positive acknowledgment', () {
        final prompt = service.getResponsePrompt(
          questionType: InterviewQuestionType.civics,
          result: EvaluationResult.pass,
          question: 'Who was the first President?',
          userAnswer: 'George Washington',
          attemptNumber: 1,
        );

        expect(prompt, contains('correctly'));
        expect(prompt, contains('first try'));
        expect(prompt, contains('Next question'));
      });

      test('pass result after multiple attempts acknowledges persistence', () {
        final prompt = service.getResponsePrompt(
          questionType: InterviewQuestionType.civics,
          result: EvaluationResult.pass,
          question: 'Who was the first President?',
          userAnswer: 'George Washington',
          attemptNumber: 3,
        );

        expect(prompt, contains('correctly'));
        expect(prompt, contains('3 attempts'));
        expect(prompt, contains('Next question'));
      });

      test('partial result requests clarification', () {
        final prompt = service.getResponsePrompt(
          questionType: InterviewQuestionType.civics,
          result: EvaluationResult.partial,
          question: 'Who was the first President?',
          userAnswer: 'Washington',
          attemptNumber: 1,
        );

        expect(
          prompt.contains('more detail') ||
              prompt.contains('clarify') ||
              prompt.contains('elaborate'),
          isTrue,
        );
        expect(prompt, contains('Washington'));
      });

      test('partial result after max attempts moves on', () {
        final prompt = service.getResponsePrompt(
          questionType: InterviewQuestionType.civics,
          result: EvaluationResult.partial,
          question: 'Who was the first President?',
          userAnswer: 'Washington',
          attemptNumber: 3,
        );

        expect(prompt, contains('Next question'));
        expect(prompt, contains('3 attempts'));
      });

      test('fail result encourages retry', () {
        final prompt = service.getResponsePrompt(
          questionType: InterviewQuestionType.civics,
          result: EvaluationResult.fail,
          question: 'Who was the first President?',
          userAnswer: 'Abraham Lincoln',
          attemptNumber: 1,
        );

        expect(
          prompt.contains('not quite right') ||
              prompt.contains('try again') ||
              prompt.contains('encouraging'),
          isTrue,
        );
      });

      test('fail result after max attempts moves on professionally', () {
        final prompt = service.getResponsePrompt(
          questionType: InterviewQuestionType.civics,
          result: EvaluationResult.fail,
          question: 'Who was the first President?',
          userAnswer: 'Wrong answer',
          attemptNumber: 3,
        );

        expect(prompt, contains('Next question'));
        expect(prompt, contains('3 attempts'));
        expect(prompt, contains('professionally'));
      });

      test('handles different question types in context', () {
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

        expect(readingPrompt, contains('reading'));
        expect(writingPrompt, contains('writing'));
      });
    });

    test('getSectionTransitionPrompt transitions between sections', () {
      final prompt = service.getSectionTransitionPrompt(
        fromSection: InterviewQuestionType.reading,
        toSection: InterviewQuestionType.civics,
      );

      expect(prompt, contains('civics test'));
      expect(prompt, contains('transition'));
      expect(prompt, contains('brief'));
    });

    test('getCompletionPrompt for passing includes congratulations', () {
      final prompt = service.getCompletionPrompt(
        passed: true,
        civicsCorrect: 15,
        civicsTotal: 20,
      );

      expect(prompt, contains('passed'));
      expect(prompt, contains('15 out of 20'));
      expect(prompt, contains('Thank'));
    });

    test('getCompletionPrompt for failing is respectful', () {
      final prompt = service.getCompletionPrompt(
        passed: false,
        civicsCorrect: 8,
        civicsTotal: 20,
      );

      expect(prompt, contains('retake'));
      expect(prompt, contains('Thank'));
      expect(
        prompt.contains('respectful') || prompt.contains('encouraging'),
        isTrue,
      );
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
