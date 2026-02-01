import 'package:flutter_test/flutter_test.dart';
import 'package:us_citizenship_test_app/models/answer.dart';

void main() {
  group('Answer Model', () {
    test('creates Answer from constructor with all fields', () {
      final answer = Answer(
        id: 1,
        questionTextId: 100,
        answerText: 'the Constitution',
        categoryId: 5,
      );

      expect(answer.id, 1);
      expect(answer.questionTextId, 100);
      expect(answer.answerText, 'the Constitution');
      expect(answer.categoryId, 5);
    });

    test('fromMap creates Answer correctly', () {
      final map = {
        'id': 2,
        'question_text_id': 200,
        'answer_text': 'George Washington',
        'category_id': 10,
      };

      final answer = Answer.fromMap(map);

      expect(answer.id, 2);
      expect(answer.questionTextId, 200);
      expect(answer.answerText, 'George Washington');
      expect(answer.categoryId, 10);
    });

    test('toMap converts Answer to map correctly', () {
      final answer = Answer(
        id: 3,
        questionTextId: 300,
        answerText: 'freedom of speech',
        categoryId: 15,
      );

      final map = answer.toMap();

      expect(map['id'], 3);
      expect(map['question_text_id'], 300);
      expect(map['answer_text'], 'freedom of speech');
      expect(map['category_id'], 15);
    });

    test('fromMap and toMap round trip preserves data', () {
      final originalMap = {
        'id': 4,
        'question_text_id': 400,
        'answer_text': 'the Star-Spangled Banner',
        'category_id': 20,
      };

      final answer = Answer.fromMap(originalMap);
      final reconstructedMap = answer.toMap();

      expect(reconstructedMap, equals(originalMap));
    });

    test('toString provides readable representation', () {
      final answer = Answer(
        id: 5,
        questionTextId: 500,
        answerText: 'life, liberty, and the pursuit of happiness',
        categoryId: 25,
      );

      final stringRep = answer.toString();

      expect(stringRep, contains('Answer{'));
      expect(stringRep, contains('id: 5'));
      expect(stringRep, contains('questionTextId: 500'));
      expect(
        stringRep,
        contains('answerText: life, liberty, and the pursuit of happiness'),
      );
      expect(stringRep, contains('categoryId: 25'));
    });

    test('handles special characters in answer text', () {
      final answer = Answer(
        id: 6,
        questionTextId: 600,
        answerText: 'We the People of the United States, in Order to...',
        categoryId: 1,
      );

      final map = answer.toMap();
      final reconstructed = Answer.fromMap(map);

      expect(reconstructed.answerText, answer.answerText);
    });

    test('handles long answer text', () {
      final longText = 'A' * 1000;
      final answer = Answer(
        id: 7,
        questionTextId: 700,
        answerText: longText,
        categoryId: 30,
      );

      final map = answer.toMap();
      final reconstructed = Answer.fromMap(map);

      expect(reconstructed.answerText, longText);
      expect(reconstructed.answerText.length, 1000);
    });

    test('handles empty answer text', () {
      final answer = Answer(
        id: 8,
        questionTextId: 800,
        answerText: '',
        categoryId: 35,
      );

      final map = answer.toMap();
      final reconstructed = Answer.fromMap(map);

      expect(reconstructed.answerText, '');
    });
  });
}
