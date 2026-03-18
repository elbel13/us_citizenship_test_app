// Tests for the duplicate-answer-choice filtering logic introduced in
// _MultipleChoiceScreenState._prepareQuiz().
//
// The fix requests (numWrong + correctAnswers.length) raw candidates from the
// database and then applies:
//
//   rawIncorrect
//     .where((a) => !correctAnswers.contains(a))
//     .take(numWrong)
//     .toList()
//
// These tests verify that filter chain in isolation, without needing a widget
// tree or a database.

import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Helpers – mirror the logic extracted from _prepareQuiz for unit-testing.
// ---------------------------------------------------------------------------

/// Applies the deduplication filter introduced by the fix.
///
/// [rawIncorrect] simulates what `getWrongAnswersByCategories` returns when
/// called with the extra-padding count.
/// [correctAnswers] are the chosen correct answer strings.
/// [numWrong] is the target number of distractors.
List<String> applyDeduplicationFilter({
  required List<String> rawIncorrect,
  required List<String> correctAnswers,
  required int numWrong,
}) {
  return rawIncorrect
      .where((a) => !correctAnswers.contains(a))
      .take(numWrong)
      .toList();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('_prepareQuiz duplicate-answer deduplication filter', () {
    // -- Single-answer questions (numWrong == 3) --

    group('single-answer question (numWrong = 3)', () {
      const numWrong = 3;

      test(
        'no duplicates in raw pool → returns exactly numWrong distractors',
        () {
          final correctAnswers = ['George Washington'];
          final rawIncorrect = [
            'John Adams',
            'Thomas Jefferson',
            'James Madison',
          ];

          final result = applyDeduplicationFilter(
            rawIncorrect: rawIncorrect,
            correctAnswers: correctAnswers,
            numWrong: numWrong,
          );

          expect(result.length, numWrong);
          expect(result, isNot(contains('George Washington')));
        },
      );

      test('one duplicate at start of raw pool is removed; '
          'a clean candidate fills its slot', () {
        final correctAnswers = ['George Washington'];
        // First entry duplicates the correct answer; 4th entry is the
        // replacement that the padding provides.
        final rawIncorrect = [
          'George Washington', // duplicate – must be filtered out
          'John Adams',
          'Thomas Jefferson',
          'James Madison', // padding candidate
        ];

        final result = applyDeduplicationFilter(
          rawIncorrect: rawIncorrect,
          correctAnswers: correctAnswers,
          numWrong: numWrong,
        );

        expect(result.length, numWrong);
        expect(result, isNot(contains('George Washington')));
        expect(
          result,
          containsAll(['John Adams', 'Thomas Jefferson', 'James Madison']),
        );
      });

      test(
        'duplicate anywhere in raw pool is removed and the rest are kept',
        () {
          final correctAnswers = ['Thomas Jefferson'];
          final rawIncorrect = [
            'John Adams',
            'Thomas Jefferson', // duplicate in the middle
            'James Madison',
            'Benjamin Franklin', // padding candidate
          ];

          final result = applyDeduplicationFilter(
            rawIncorrect: rawIncorrect,
            correctAnswers: correctAnswers,
            numWrong: numWrong,
          );

          expect(result.length, numWrong);
          expect(result, isNot(contains('Thomas Jefferson')));
        },
      );

      test('result contains no duplicates when raw pool has no overlap', () {
        final correctAnswers = ['Freedom of speech'];
        final rawIncorrect = [
          'Freedom of religion',
          'Right to bear arms',
          'Right to vote',
        ];

        final result = applyDeduplicationFilter(
          rawIncorrect: rawIncorrect,
          correctAnswers: correctAnswers,
          numWrong: numWrong,
        );

        // All returned strings are unique.
        expect(result.toSet().length, result.length);
      });

      test(
        'returns fewer than numWrong when pool is exhausted after filtering',
        () {
          // Only 2 clean candidates survive after filtering.
          final correctAnswers = ['George Washington'];
          final rawIncorrect = [
            'George Washington', // duplicate
            'John Adams',
            'Thomas Jefferson',
            // no more candidates
          ];

          final result = applyDeduplicationFilter(
            rawIncorrect: rawIncorrect,
            correctAnswers: correctAnswers,
            numWrong: numWrong,
          );

          expect(result.length, 2); // only 2 clean candidates available
          expect(result, isNot(contains('George Washington')));
        },
      );

      test('empty raw pool returns empty list', () {
        final result = applyDeduplicationFilter(
          rawIncorrect: [],
          correctAnswers: ['George Washington'],
          numWrong: numWrong,
        );

        expect(result, isEmpty);
      });

      test('empty correct-answers list passes all raw candidates through', () {
        final rawIncorrect = ['A', 'B', 'C'];
        final result = applyDeduplicationFilter(
          rawIncorrect: rawIncorrect,
          correctAnswers: [],
          numWrong: numWrong,
        );

        expect(result, equals(['A', 'B', 'C']));
      });
    });

    // -- Multi-answer questions (numWrong == 2) --

    group('multi-answer question (numWrong = 2)', () {
      const numWrong = 2;

      test(
        'no duplicates in raw pool → returns exactly numWrong distractors',
        () {
          final correctAnswers = ['freedom of speech', 'freedom of religion'];
          final rawIncorrect = ['right to bear arms', 'right to vote'];

          final result = applyDeduplicationFilter(
            rawIncorrect: rawIncorrect,
            correctAnswers: correctAnswers,
            numWrong: numWrong,
          );

          expect(result.length, numWrong);
        },
      );

      test(
        'both correct answers appear in raw pool; padding fills both slots',
        () {
          final correctAnswers = ['freedom of speech', 'freedom of religion'];
          // Both correct answers are present as candidates; 2 padding entries
          // should fill both required slots.
          final rawIncorrect = [
            'freedom of speech', // duplicate
            'freedom of religion', // duplicate
            'right to bear arms', // padding
            'right to vote', // padding
          ];

          final result = applyDeduplicationFilter(
            rawIncorrect: rawIncorrect,
            correctAnswers: correctAnswers,
            numWrong: numWrong,
          );

          expect(result.length, numWrong);
          expect(result, isNot(contains('freedom of speech')));
          expect(result, isNot(contains('freedom of religion')));
        },
      );

      test('result never contains a string that is also in correctAnswers', () {
        final correctAnswers = ['A', 'B'];
        final rawIncorrect = ['A', 'C', 'B', 'D'];

        final result = applyDeduplicationFilter(
          rawIncorrect: rawIncorrect,
          correctAnswers: correctAnswers,
          numWrong: numWrong,
        );

        for (final r in result) {
          expect(
            correctAnswers,
            isNot(contains(r)),
            reason: '"$r" must not appear in the correct-answer list',
          );
        }
      });
    });

    // -- take() boundary ---

    group('take() boundary', () {
      test('extra clean candidates beyond numWrong are dropped', () {
        const numWrong = 3;
        final correctAnswers = ['X'];
        // 5 clean candidates available – only the first 3 should survive.
        final rawIncorrect = ['A', 'B', 'C', 'D', 'E'];

        final result = applyDeduplicationFilter(
          rawIncorrect: rawIncorrect,
          correctAnswers: correctAnswers,
          numWrong: numWrong,
        );

        expect(result.length, numWrong);
        expect(result, equals(['A', 'B', 'C']));
      });
    });
  });
}
