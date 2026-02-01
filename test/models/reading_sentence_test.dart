import 'package:flutter_test/flutter_test.dart';
import 'package:us_citizenship_test_app/models/reading_sentence.dart';

void main() {
  group('ReadingSentence Model', () {
    test('creates ReadingSentence with all required fields', () {
      final sentence = ReadingSentence(
        id: 'rs-1',
        text: 'The Constitution is the supreme law of the land.',
        vocabularyWords: ['Constitution', 'supreme', 'law'],
        category: 'American Government',
        difficulty: 1,
      );

      expect(sentence.id, 'rs-1');
      expect(sentence.text, 'The Constitution is the supreme law of the land.');
      expect(sentence.vocabularyWords, ['Constitution', 'supreme', 'law']);
      expect(sentence.category, 'American Government');
      expect(sentence.difficulty, 1);
    });

    test('creates ReadingSentence with default difficulty', () {
      final sentence = ReadingSentence(
        id: 'rs-2',
        text: 'George Washington was the first President.',
        vocabularyWords: ['George Washington', 'President'],
        category: 'American History',
      );

      expect(sentence.difficulty, 1);
    });

    test('fromJson creates ReadingSentence correctly', () {
      final json = {
        'id': 'rs-3',
        'text': 'Freedom of speech is a right.',
        'vocabularyWords': ['Freedom', 'speech', 'right'],
        'category': 'Rights and Freedoms',
        'difficulty': 2,
      };

      final sentence = ReadingSentence.fromJson(json);

      expect(sentence.id, 'rs-3');
      expect(sentence.text, 'Freedom of speech is a right.');
      expect(sentence.vocabularyWords, ['Freedom', 'speech', 'right']);
      expect(sentence.category, 'Rights and Freedoms');
      expect(sentence.difficulty, 2);
    });

    test('fromJson uses default difficulty when not provided', () {
      final json = {
        'id': 'rs-4',
        'text': 'Test sentence.',
        'vocabularyWords': ['Test'],
        'category': 'Test Category',
      };

      final sentence = ReadingSentence.fromJson(json);

      expect(sentence.difficulty, 1);
    });

    test('toJson converts ReadingSentence correctly', () {
      final sentence = ReadingSentence(
        id: 'rs-5',
        text: 'We the People of the United States.',
        vocabularyWords: ['People', 'United States'],
        category: 'Constitution',
        difficulty: 3,
      );

      final json = sentence.toJson();

      expect(json['id'], 'rs-5');
      expect(json['text'], 'We the People of the United States.');
      expect(json['vocabularyWords'], ['People', 'United States']);
      expect(json['category'], 'Constitution');
      expect(json['difficulty'], 3);
    });

    test('fromJson and toJson round trip preserves data', () {
      final originalJson = {
        'id': 'rs-6',
        'text': 'The flag has 50 stars.',
        'vocabularyWords': ['flag', 'stars'],
        'category': 'Symbols',
        'difficulty': 1,
      };

      final sentence = ReadingSentence.fromJson(originalJson);
      final reconstructedJson = sentence.toJson();

      expect(reconstructedJson, equals(originalJson));
    });

    test('handles empty vocabulary words list', () {
      final sentence = ReadingSentence(
        id: 'rs-7',
        text: 'Simple sentence.',
        vocabularyWords: [],
        category: 'Basic',
        difficulty: 1,
      );

      final json = sentence.toJson();
      final reconstructed = ReadingSentence.fromJson(json);

      expect(reconstructed.vocabularyWords, isEmpty);
    });

    test('handles multiple vocabulary words', () {
      final words = [
        'Constitution',
        'amendments',
        'Bill of Rights',
        'government',
        'democracy',
      ];
      final sentence = ReadingSentence(
        id: 'rs-8',
        text:
            'The Constitution has amendments including the Bill of Rights that protects democracy in our government.',
        vocabularyWords: words,
        category: 'Government',
        difficulty: 3,
      );

      final json = sentence.toJson();
      final reconstructed = ReadingSentence.fromJson(json);

      expect(reconstructed.vocabularyWords, words);
      expect(reconstructed.vocabularyWords.length, 5);
    });

    test('handles long text sentences', () {
      final longText = 'A' * 500;
      final sentence = ReadingSentence(
        id: 'rs-9',
        text: longText,
        vocabularyWords: ['test'],
        category: 'Test',
        difficulty: 1,
      );

      final json = sentence.toJson();
      final reconstructed = ReadingSentence.fromJson(json);

      expect(reconstructed.text, longText);
      expect(reconstructed.text.length, 500);
    });

    test('handles special characters in text', () {
      final sentence = ReadingSentence(
        id: 'rs-10',
        text: 'We hold these truths to be "self-evident"...',
        vocabularyWords: ['truths', 'self-evident'],
        category: 'Declaration',
        difficulty: 2,
      );

      final json = sentence.toJson();
      final reconstructed = ReadingSentence.fromJson(json);

      expect(reconstructed.text, sentence.text);
    });

    test('toString provides readable representation', () {
      final sentence = ReadingSentence(
        id: 'rs-11',
        text: 'Test sentence for toString.',
        vocabularyWords: ['test'],
        category: 'Test',
        difficulty: 1,
      );

      final stringRep = sentence.toString();

      expect(stringRep, contains('ReadingSentence'));
      expect(stringRep, contains('id: rs-11'));
      expect(stringRep, contains('text: Test sentence for toString.'));
    });

    test('handles different difficulty levels', () {
      for (var difficulty in [1, 2, 3]) {
        final sentence = ReadingSentence(
          id: 'rs-diff-$difficulty',
          text: 'Difficulty test.',
          vocabularyWords: ['test'],
          category: 'Test',
          difficulty: difficulty,
        );

        expect(sentence.difficulty, difficulty);
      }
    });

    test('handles vocabulary words with special characters', () {
      final sentence = ReadingSentence(
        id: 'rs-12',
        text: 'Test sentence.',
        vocabularyWords: [
          "can't",
          'U.S.',
          'Washington, D.C.',
          'self-government',
        ],
        category: 'Test',
        difficulty: 1,
      );

      final json = sentence.toJson();
      final reconstructed = ReadingSentence.fromJson(json);

      expect(reconstructed.vocabularyWords, sentence.vocabularyWords);
    });
  });
}
