import 'package:flutter_test/flutter_test.dart';
import 'package:us_citizenship_test_app/models/answer.dart';
import 'package:us_citizenship_test_app/models/question.dart';

void main() {
  group('Question Model', () {
    test('fromMap creates Question correctly with answers', () {
      final map = {
        'id': 1,
        'question_id': 1,
        'question_text': 'What is the supreme law of the land?',
        'language_code': 'en',
      };

      final answers = [
        Answer(
          id: 1,
          questionTextId: 1,
          answerText: 'the Constitution',
          categoryId: 1,
        ),
        Answer(
          id: 2,
          questionTextId: 1,
          answerText: 'the U.S. Constitution',
          categoryId: 1,
        ),
      ];

      final question = Question.fromMap(map, answers: answers);

      expect(question.id, 1);
      expect(question.questionText, 'What is the supreme law of the land?');
      expect(question.answers.length, 2);
      expect(question.answers[0].answerText, 'the Constitution');
      expect(question.answers[1].answerText, 'the U.S. Constitution');
      expect(question.languageCode, 'en');
    });

    test('answerText getter concatenates all answers', () {
      final map = {
        'id': 2,
        'question_id': 2,
        'question_text': 'How many amendments does the U.S. Constitution have?',
        'language_code': 'en',
      };

      final answers = [
        Answer(
          id: 3,
          questionTextId: 2,
          answerText: 'Twenty-seven',
          categoryId: 6,
        ),
        Answer(id: 4, questionTextId: 2, answerText: '27', categoryId: 6),
      ];

      final question = Question.fromMap(map, answers: answers);

      expect(question.answerText, 'Twenty-seven\n27');
    });

    test('toMap converts Question to map correctly', () {
      final answers = [
        Answer(
          id: 5,
          questionTextId: 3,
          answerText: 'capitalism',
          categoryId: 13,
        ),
        Answer(
          id: 6,
          questionTextId: 3,
          answerText: 'free market economy',
          categoryId: 13,
        ),
      ];

      final question = Question(
        id: 3,
        questionText: 'What is the economic system of the United States?',
        answers: answers,
        languageCode: 'en',
      );

      final map = question.toMap();

      expect(map['id'], 3);
      expect(
        map['question_text'],
        'What is the economic system of the United States?',
      );
      expect(map['language_code'], 'en');
    });

    test('fromMap and toMap preserve basic question data', () {
      final originalMap = {
        'id': 4,
        'question_id': 4,
        'question_text': 'What is the economic system of the United States?',
        'language_code': 'en',
      };

      final answers = [
        Answer(
          id: 7,
          questionTextId: 4,
          answerText: 'capitalism',
          categoryId: 13,
        ),
      ];

      final question = Question.fromMap(originalMap, answers: answers);
      final resultMap = question.toMap();

      expect(resultMap['id'], originalMap['id']);
      expect(resultMap['question_text'], originalMap['question_text']);
      expect(resultMap['language_code'], originalMap['language_code']);
    });

    test('handles multiple answers from different categories', () {
      final answers = [
        Answer(
          id: 8,
          questionTextId: 5,
          answerText: 'the Revolutionary War',
          categoryId: 8, // WAR
        ),
        Answer(
          id: 9,
          questionTextId: 5,
          answerText: 'independence',
          categoryId: 13, // POLITICAL_CONCEPT
        ),
      ];

      final question = Question(
        id: 5,
        questionText: 'The Colonists fought the British because they wanted:',
        answers: answers,
        languageCode: 'en',
      );

      expect(question.answers.length, 2);
      expect(question.answers[0].categoryId, 8);
      expect(question.answers[1].categoryId, 13);
      expect(question.answerText.contains('\n'), true);
    });

    test('handles different language codes', () {
      final answersEn = [
        Answer(
          id: 10,
          questionTextId: 6,
          answerText: 'Answer in English',
          categoryId: 1,
        ),
      ];

      final answersEs = [
        Answer(
          id: 11,
          questionTextId: 7,
          answerText: 'Respuesta en español',
          categoryId: 1,
        ),
      ];

      final questionEn = Question(
        id: 6,
        questionText: 'Question in English',
        answers: answersEn,
        languageCode: 'en',
      );

      final questionEs = Question(
        id: 6,
        questionText: 'Pregunta en español',
        answers: answersEs,
        languageCode: 'es',
      );

      expect(questionEn.languageCode, 'en');
      expect(questionEs.languageCode, 'es');
    });
  });
}
