import 'package:flutter_test/flutter_test.dart';
import 'package:us_citizenship_test_app/services/reading_evaluator.dart';

void main() {
  group('ReadingEvaluator', () {
    late ReadingEvaluator evaluator;

    setUp(() {
      evaluator = ReadingEvaluator();
    });

    group('Similarity-based evaluation (reading/writing)', () {
      test('identical text returns 1.0 similarity', () {
        const text = 'The Constitution is the supreme law of the land.';
        final score = evaluator.calculateSimilarity(text, text);
        expect(score, equals(1.0));
      });

      test('completely different text returns low similarity', () {
        const expected = 'The Constitution is the supreme law.';
        const spoken = 'Elephants like peanuts.';
        final score = evaluator.calculateSimilarity(expected, spoken);
        expect(score, lessThan(0.3));
      });

      test('case insensitive comparison', () {
        const expected = 'The Constitution';
        const spoken = 'THE CONSTITUTION';
        final score = evaluator.calculateSimilarity(expected, spoken);
        expect(score, equals(1.0));
      });

      test('punctuation is ignored', () {
        const expected = 'The Constitution, is the supreme law!';
        const spoken = 'The Constitution is the supreme law';
        final score = evaluator.calculateSimilarity(expected, spoken);
        expect(score, equals(1.0));
      });

      test('passing threshold at 0.80', () {
        expect(evaluator.isPassing(0.85), isTrue);
        expect(evaluator.isPassing(0.80), isTrue);
        expect(evaluator.isPassing(0.79), isFalse);
      });

      test('getFeedback returns appropriate messages', () {
        expect(evaluator.getFeedback(0.96), contains('Excellent'));
        expect(evaluator.getFeedback(0.91), contains('Great'));
        expect(evaluator.getFeedback(0.82), contains('Good'));
        expect(evaluator.getFeedback(0.65), contains('Almost'));
        expect(evaluator.getFeedback(0.40), contains('Keep practicing'));
      });

      test('getPercentageScore converts to 0-100', () {
        expect(evaluator.getPercentageScore(1.0), equals(100));
        expect(evaluator.getPercentageScore(0.85), equals(85));
        expect(evaluator.getPercentageScore(0.0), equals(0));
      });
    });

    group('Keyword-based evaluation (civics questions)', () {
      test('exact match returns Pass', () {
        final result = evaluator.evaluateCivicsAnswer([
          'the Constitution',
        ], 'the Constitution');
        expect(result, equals(EvaluationResult.pass));
      });

      test('all keywords present returns Pass', () {
        final result = evaluator.evaluateCivicsAnswer([
          'George Washington',
        ], 'It was George Washington');
        expect(result, equals(EvaluationResult.pass));
      });

      test('keywords with extra words returns Pass', () {
        final result = evaluator.evaluateCivicsAnswer([
          'freedom of speech',
        ], 'the freedom of speech is important');
        expect(result, equals(EvaluationResult.pass));
      });

      test('partial keyword match returns Partial', () {
        final result = evaluator.evaluateCivicsAnswer([
          'George Washington',
        ], 'Washington');
        expect(result, equals(EvaluationResult.partial));
      });

      test('missing important keywords returns Fail', () {
        final result = evaluator.evaluateCivicsAnswer([
          'the Bill of Rights',
        ], 'the Constitution');
        expect(result, equals(EvaluationResult.fail));
      });

      test('supports multiple acceptable answers', () {
        // Question: What is the supreme law of the land?
        final result1 = evaluator.evaluateCivicsAnswer([
          'the Constitution',
          'the U.S. Constitution',
        ], 'the Constitution');
        expect(result1, equals(EvaluationResult.pass));

        final result2 = evaluator.evaluateCivicsAnswer([
          'the Constitution',
          'the U.S. Constitution',
        ], 'the U.S. Constitution');
        expect(result2, equals(EvaluationResult.pass));

        final result3 = evaluator.evaluateCivicsAnswer([
          'the Constitution',
          'the U.S. Constitution',
        ], 'U.S. Constitution');
        expect(result3, equals(EvaluationResult.pass));
      });

      test('ignores filler words in keyword extraction', () {
        // "the", "of", "is" should be filtered out
        final result = evaluator.evaluateCivicsAnswer(
          ['freedom of speech'],
          'freedom speech', // Missing "of" but has key words
        );
        expect(result, equals(EvaluationResult.pass));
      });

      test('case insensitive keyword matching', () {
        final result = evaluator.evaluateCivicsAnswer([
          'Bill of Rights',
        ], 'bill of rights');
        expect(result, equals(EvaluationResult.pass));
      });

      test('handles punctuation in answers', () {
        final result = evaluator.evaluateCivicsAnswer([
          'freedom of speech, religion, and press',
        ], 'freedom of speech religion and press');
        expect(result, equals(EvaluationResult.pass));
      });

      test('realistic civics answers', () {
        // Question: Who was the first President?
        final result1 = evaluator.evaluateCivicsAnswer([
          'George Washington',
        ], 'George Washington was the first president');
        expect(result1, equals(EvaluationResult.pass));

        // Question: What are two rights in the Declaration of Independence?
        final result2 = evaluator.evaluateCivicsAnswer([
          'life and liberty',
          'life and the pursuit of happiness',
        ], 'life liberty and pursuit of happiness');
        expect(result2, equals(EvaluationResult.pass));

        // Question: How many amendments does the Constitution have?
        final result3 = evaluator.evaluateCivicsAnswer([
          'twenty-seven',
          '27',
        ], 'twenty seven');
        expect(result3, equals(EvaluationResult.pass));
      });

      test('getCivicsFeedback returns appropriate messages', () {
        expect(
          evaluator.getCivicsFeedback(EvaluationResult.pass),
          equals('Correct!'),
        );
        expect(
          evaluator.getCivicsFeedback(EvaluationResult.partial),
          contains('more detail'),
        );
        expect(
          evaluator.getCivicsFeedback(EvaluationResult.fail),
          contains('Not quite'),
        );
      });

      test('empty acceptable answers returns Fail', () {
        final result = evaluator.evaluateCivicsAnswer([], 'any answer');
        expect(result, equals(EvaluationResult.fail));
      });
    });

    group('Word diff functionality', () {
      test('identifies correct words', () {
        final diff = evaluator.getWordDiff('hello world', 'hello world');
        expect(diff.length, equals(2));
        expect(diff.every((d) => d.type == WordDiffType.correct), isTrue);
      });

      test('identifies missing words', () {
        final diff = evaluator.getWordDiff('hello world', 'hello');
        expect(diff.length, equals(2));
        expect(diff[0].type, equals(WordDiffType.correct));
        expect(diff[1].type, equals(WordDiffType.missing));
      });

      test('identifies added words', () {
        final diff = evaluator.getWordDiff('hello world', 'hello big world');
        expect(diff.any((d) => d.type == WordDiffType.added), isTrue);
      });
    });
  });
}
