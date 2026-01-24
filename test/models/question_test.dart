import 'package:flutter_test/flutter_test.dart';
import 'package:us_citizenship_test_app/models/question.dart';

void main() {
  group('Question Model', () {
    test('fromMap creates Question correctly', () {
      final map = {
        'id': 1,
        'question_text': 'What is the supreme law of the land?',
        'answer_text': '(U.S.) Constitution',
        'language_code': 'en',
      };

      final question = Question.fromMap(map);

      expect(question.id, 1);
      expect(question.questionText, 'What is the supreme law of the land?');
      expect(question.answerText, '(U.S.) Constitution');
      expect(question.languageCode, 'en');
    });

    test('toMap converts Question to map correctly', () {
      final question = Question(
        id: 2,
        questionText: 'How many amendments does the U.S. Constitution have?',
        answerText: 'Twenty-seven (27)',
        languageCode: 'en',
      );

      final map = question.toMap();

      expect(map['id'], 2);
      expect(
        map['question_text'],
        'How many amendments does the U.S. Constitution have?',
      );
      expect(map['answer_text'], 'Twenty-seven (27)');
      expect(map['language_code'], 'en');
    });

    test('fromMap and toMap are inverse operations', () {
      final originalMap = {
        'id': 3,
        'question_text': 'What is the economic system of the United States?',
        'answer_text': 'Capitalism\nFree market economy',
        'language_code': 'en',
      };

      final question = Question.fromMap(originalMap);
      final resultMap = question.toMap();

      expect(resultMap, originalMap);
    });

    test('handles multi-line answers correctly', () {
      final question = Question(
        id: 4,
        questionText: 'Name the three branches of government.',
        answerText:
            'Legislative, executive, and judicial\nCongress, president, and the courts',
        languageCode: 'en',
      );

      expect(question.answerText.contains('\n'), true);
      expect(question.answerText.split('\n').length, 2);
    });

    test('handles different language codes', () {
      final questionEn = Question(
        id: 5,
        questionText: 'Question in English',
        answerText: 'Answer in English',
        languageCode: 'en',
      );

      final questionEs = Question(
        id: 5,
        questionText: 'Pregunta en español',
        answerText: 'Respuesta en español',
        languageCode: 'es',
      );

      expect(questionEn.languageCode, 'en');
      expect(questionEs.languageCode, 'es');
    });
  });
}
