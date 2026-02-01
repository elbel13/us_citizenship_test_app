import 'package:flutter_test/flutter_test.dart';
import 'package:us_citizenship_test_app/models/interview_question.dart';
import 'package:us_citizenship_test_app/models/interview_state.dart';
import 'package:us_citizenship_test_app/services/reading_evaluator.dart';

void main() {
  group('InterviewState', () {
    late List<InterviewQuestion> sampleQuestions;

    setUp(() {
      sampleQuestions = [
        InterviewQuestion.reading(
          text: 'The Constitution is important',
          vocabularyWords: ['Constitution', 'important'],
        ),
        InterviewQuestion.writing(
          text: 'Freedom of speech',
          vocabularyWords: ['Freedom', 'speech'],
        ),
        InterviewQuestion.civics(
          question: 'Who was the first President?',
          answers: ['George Washington'],
        ),
        InterviewQuestion.civics(
          question: 'What is the supreme law?',
          answers: ['the Constitution'],
        ),
      ];
    });

    test('initializes in notStarted phase', () {
      final state = InterviewState(questions: sampleQuestions);
      expect(state.phase, equals(InterviewPhase.notStarted));
    });

    test('startInterview moves to greeting phase', () {
      final state = InterviewState(questions: sampleQuestions);
      state.startInterview();
      expect(state.phase, equals(InterviewPhase.greeting));
    });

    test('startQuestioning moves to questioning phase', () {
      final state = InterviewState(questions: sampleQuestions);
      state.startInterview();
      state.startQuestioning();
      expect(state.phase, equals(InterviewPhase.questioning));
    });

    test('currentQuestion returns first question initially', () {
      final state = InterviewState(questions: sampleQuestions);
      expect(state.currentQuestion, equals(sampleQuestions[0]));
      expect(
        state.currentQuestion!.type,
        equals(InterviewQuestionType.reading),
      );
    });

    test('moveToNextQuestion advances through questions', () {
      final state = InterviewState(questions: sampleQuestions);

      expect(state.currentQuestionIndex, equals(0));

      final moved1 = state.moveToNextQuestion();
      expect(moved1, isTrue);
      expect(state.currentQuestionIndex, equals(1));

      final moved2 = state.moveToNextQuestion();
      expect(moved2, isTrue);
      expect(state.currentQuestionIndex, equals(2));

      final moved3 = state.moveToNextQuestion();
      expect(moved3, isTrue);
      expect(state.currentQuestionIndex, equals(3));

      // Last question - should return false and complete
      final moved4 = state.moveToNextQuestion();
      expect(moved4, isFalse);
      expect(state.phase, equals(InterviewPhase.completed));
    });

    test('recordAttempt tracks pass results', () {
      final state = InterviewState(questions: sampleQuestions);

      state.recordAttempt('George Washington', EvaluationResult.pass);

      expect(state.currentQuestionAttempts, equals(1));
      expect(state.currentQuestionPassed, isTrue);
      expect(state.readingCorrect, equals(1)); // First question is reading
    });

    test('recordAttempt allows multiple attempts', () {
      final state = InterviewState(questions: sampleQuestions);

      state.recordAttempt('Wrong answer', EvaluationResult.fail);
      expect(state.currentQuestionAttempts, equals(1));
      expect(state.currentQuestionPassed, isFalse);

      state.recordAttempt('Partial answer', EvaluationResult.partial);
      expect(state.currentQuestionAttempts, equals(2));
      expect(state.currentQuestionPassed, isFalse);

      state.recordAttempt('Correct answer', EvaluationResult.pass);
      expect(state.currentQuestionAttempts, equals(3));
      expect(state.currentQuestionPassed, isTrue);
    });

    test('hasReachedMaxRetries enforces 3-attempt limit', () {
      final state = InterviewState(questions: sampleQuestions);

      expect(state.hasReachedMaxRetries, isFalse);

      state.recordAttempt('Try 1', EvaluationResult.fail);
      expect(state.hasReachedMaxRetries, isFalse);

      state.recordAttempt('Try 2', EvaluationResult.fail);
      expect(state.hasReachedMaxRetries, isFalse);

      state.recordAttempt('Try 3', EvaluationResult.fail);
      expect(state.hasReachedMaxRetries, isTrue);
    });

    test('tracks civics questions separately', () {
      final state = InterviewState(questions: sampleQuestions);

      // Move to first civics question (index 2)
      state.moveToNextQuestion(); // Index 1
      state.moveToNextQuestion(); // Index 2 (civics)

      expect(state.currentQuestion!.type, equals(InterviewQuestionType.civics));

      state.recordAttempt('George Washington', EvaluationResult.pass);

      expect(state.civicsCorrect, equals(1));
      expect(state.civicsAsked, equals(1));
    });

    test('canShortCircuit returns true when 12 civics correct', () {
      // Create state with many civics questions
      final civicsQuestions = List.generate(
        15,
        (i) => InterviewQuestion.civics(
          question: 'Question $i',
          answers: ['Answer $i'],
        ),
      );

      final state = InterviewState(questions: civicsQuestions);

      expect(state.canShortCircuit(), isFalse);

      // Answer 12 correctly
      for (int i = 0; i < 12; i++) {
        state.recordAttempt('Correct', EvaluationResult.pass);
        state.moveToNextQuestion();
      }

      expect(state.canShortCircuit(), isTrue);
    });

    test('completeInterview sets phase to completed', () {
      final state = InterviewState(questions: sampleQuestions);
      state.startQuestioning();

      expect(state.phase, equals(InterviewPhase.questioning));

      state.completeInterview();

      expect(state.phase, equals(InterviewPhase.completed));
    });

    test('progressPercentage calculates correctly', () {
      final state = InterviewState(questions: sampleQuestions);

      expect(state.progressPercentage, equals(0.0));

      state.moveToNextQuestion();
      expect(state.progressPercentage, equals(25.0)); // 1/4

      state.moveToNextQuestion();
      expect(state.progressPercentage, equals(50.0)); // 2/4
    });

    test('passesCivics requires 12 correct', () {
      final civicsQuestions = List.generate(
        20,
        (i) => InterviewQuestion.civics(
          question: 'Question $i',
          answers: ['Answer $i'],
        ),
      );

      final state = InterviewState(questions: civicsQuestions);

      expect(state.passesCivics(), isFalse);

      // Answer 11 correctly
      for (int i = 0; i < 11; i++) {
        state.recordAttempt('Correct', EvaluationResult.pass);
        state.moveToNextQuestion();
      }

      expect(state.passesCivics(), isFalse);

      // Answer 12th correctly
      state.recordAttempt('Correct', EvaluationResult.pass);

      expect(state.passesCivics(), isTrue);
    });

    test('getSummary provides complete statistics', () {
      final state = InterviewState(questions: sampleQuestions);
      state.startQuestioning();

      // Answer first question (reading)
      state.recordAttempt('Correct', EvaluationResult.pass);
      state.moveToNextQuestion();

      // Answer second question (writing)
      state.recordAttempt('Correct', EvaluationResult.pass);
      state.moveToNextQuestion();

      final summary = state.getSummary();

      expect(summary['readingCorrect'], equals(1));
      expect(summary['readingTotal'], equals(1));
      expect(summary['writingCorrect'], equals(1));
      expect(summary['writingTotal'], equals(1));
      expect(summary['civicsCorrect'], equals(0));
      expect(summary['totalQuestions'], equals(4));
    });

    test('getAttemptsForQuestion returns attempt history', () {
      final state = InterviewState(questions: sampleQuestions);

      state.recordAttempt('Try 1', EvaluationResult.fail);
      state.recordAttempt('Try 2', EvaluationResult.partial);
      state.recordAttempt('Try 3', EvaluationResult.pass);

      final attempts = state.getAttemptsForQuestion(0);

      expect(attempts.length, equals(3));
      expect(attempts[0].userResponse, equals('Try 1'));
      expect(attempts[0].result, equals(EvaluationResult.fail));
      expect(attempts[2].userResponse, equals('Try 3'));
      expect(attempts[2].result, equals(EvaluationResult.pass));
    });
  });
}
