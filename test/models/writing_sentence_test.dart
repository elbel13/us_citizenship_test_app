import 'package:flutter_test/flutter_test.dart';
import 'package:us_citizenship_test_app/models/writing_sentence.dart';

void main() {
  group('WritingSentence Model', () {
    test('creates WritingSentence with all required fields', () {
      final sentence = WritingSentence(
        id: 'ws-1',
        text: 'Washington is the capital.',
        vocabularyWords: ['Washington', 'capital'],
        category: 'Geography',
        difficulty: 1,
      );

      expect(sentence.id, 'ws-1');
      expect(sentence.text, 'Washington is the capital.');
      expect(sentence.vocabularyWords, ['Washington', 'capital']);
      expect(sentence.category, 'Geography');
      expect(sentence.difficulty, 1);
    });

    test('fromJson creates WritingSentence correctly', () {
      final json = {
        'id': 'ws-2',
        'text': 'Congress makes laws.',
        'vocabularyWords': ['Congress', 'laws'],
        'category': 'Government',
        'difficulty': 2,
      };

      final sentence = WritingSentence.fromJson(json);

      expect(sentence.id, 'ws-2');
      expect(sentence.text, 'Congress makes laws.');
      expect(sentence.vocabularyWords, ['Congress', 'laws']);
      expect(sentence.category, 'Government');
      expect(sentence.difficulty, 2);
    });

    test('toJson converts WritingSentence correctly', () {
      final sentence = WritingSentence(
        id: 'ws-3',
        text: 'The President lives in the White House.',
        vocabularyWords: ['President', 'White House'],
        category: 'Executive Branch',
        difficulty: 1,
      );

      final json = sentence.toJson();

      expect(json['id'], 'ws-3');
      expect(json['text'], 'The President lives in the White House.');
      expect(json['vocabularyWords'], ['President', 'White House']);
      expect(json['category'], 'Executive Branch');
      expect(json['difficulty'], 1);
    });

    test('fromJson and toJson round trip preserves data', () {
      final originalJson = {
        'id': 'ws-4',
        'text': 'Citizens have the right to vote.',
        'vocabularyWords': ['Citizens', 'vote', 'right'],
        'category': 'Rights',
        'difficulty': 1,
      };

      final sentence = WritingSentence.fromJson(originalJson);
      final reconstructedJson = sentence.toJson();

      expect(reconstructedJson, equals(originalJson));
    });

    test('handles empty vocabulary words list', () {
      final sentence = WritingSentence(
        id: 'ws-5',
        text: 'Test.',
        vocabularyWords: [],
        category: 'Basic',
        difficulty: 1,
      );

      final json = sentence.toJson();
      final reconstructed = WritingSentence.fromJson(json);

      expect(reconstructed.vocabularyWords, isEmpty);
    });

    test('handles multiple vocabulary words', () {
      final words = [
        'America',
        'freedom',
        'democracy',
        'Constitution',
        'liberty',
      ];
      final sentence = WritingSentence(
        id: 'ws-6',
        text:
            'America values freedom, democracy, and liberty as guaranteed by the Constitution.',
        vocabularyWords: words,
        category: 'Values',
        difficulty: 3,
      );

      final json = sentence.toJson();
      final reconstructed = WritingSentence.fromJson(json);

      expect(reconstructed.vocabularyWords, words);
      expect(reconstructed.vocabularyWords.length, 5);
    });

    test('handles long text sentences', () {
      final longText = 'B' * 400;
      final sentence = WritingSentence(
        id: 'ws-7',
        text: longText,
        vocabularyWords: ['test'],
        category: 'Test',
        difficulty: 2,
      );

      final json = sentence.toJson();
      final reconstructed = WritingSentence.fromJson(json);

      expect(reconstructed.text, longText);
      expect(reconstructed.text.length, 400);
    });

    test('handles special characters in text', () {
      final sentence = WritingSentence(
        id: 'ws-8',
        text: 'The flag has 13 stripes & 50 stars.',
        vocabularyWords: ['flag', 'stripes', 'stars'],
        category: 'Symbols',
        difficulty: 1,
      );

      final json = sentence.toJson();
      final reconstructed = WritingSentence.fromJson(json);

      expect(reconstructed.text, sentence.text);
    });

    test('handles different difficulty levels', () {
      for (var difficulty in [1, 2, 3]) {
        final sentence = WritingSentence(
          id: 'ws-diff-$difficulty',
          text: 'Difficulty test sentence.',
          vocabularyWords: ['test'],
          category: 'Test',
          difficulty: difficulty,
        );

        expect(sentence.difficulty, difficulty);
      }
    });

    test('handles vocabulary words with punctuation', () {
      final sentence = WritingSentence(
        id: 'ws-9',
        text: 'Test sentence.',
        vocabularyWords: ['U.S.', 'Washington, D.C.', "don't", 'fifty-two'],
        category: 'Test',
        difficulty: 2,
      );

      final json = sentence.toJson();
      final reconstructed = WritingSentence.fromJson(json);

      expect(reconstructed.vocabularyWords, sentence.vocabularyWords);
    });

    test('handles capitalization in text', () {
      final sentence = WritingSentence(
        id: 'ws-10',
        text: 'AMERICA is GREAT.',
        vocabularyWords: ['America', 'great'],
        category: 'Test',
        difficulty: 1,
      );

      final json = sentence.toJson();
      final reconstructed = WritingSentence.fromJson(json);

      expect(reconstructed.text, 'AMERICA is GREAT.');
    });

    test('handles numeric characters in text', () {
      final sentence = WritingSentence(
        id: 'ws-11',
        text: 'The U.S. has 50 states and 435 representatives.',
        vocabularyWords: ['states', 'representatives'],
        category: 'Numbers',
        difficulty: 2,
      );

      final json = sentence.toJson();
      final reconstructed = WritingSentence.fromJson(json);

      expect(reconstructed.text, sentence.text);
    });

    test('handles single vocabulary word', () {
      final sentence = WritingSentence(
        id: 'ws-12',
        text: 'Freedom.',
        vocabularyWords: ['Freedom'],
        category: 'Simple',
        difficulty: 1,
      );

      final json = sentence.toJson();
      final reconstructed = WritingSentence.fromJson(json);

      expect(reconstructed.vocabularyWords, ['Freedom']);
      expect(reconstructed.vocabularyWords.length, 1);
    });

    test('preserves category casing', () {
      final categories = [
        'American History',
        'GEOGRAPHY',
        'rights and freedoms',
        'Mixed Case Test',
      ];

      for (var category in categories) {
        final sentence = WritingSentence(
          id: 'ws-cat-$category',
          text: 'Test.',
          vocabularyWords: ['test'],
          category: category,
          difficulty: 1,
        );

        final json = sentence.toJson();
        final reconstructed = WritingSentence.fromJson(json);

        expect(reconstructed.category, category);
      }
    });
  });
}
