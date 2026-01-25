import 'answer.dart';

class Question {
  final int id;
  final String questionText;
  final String languageCode;
  final List<Answer> answers;

  Question({
    required this.id,
    required this.questionText,
    required this.languageCode,
    required this.answers,
  });

  // For backward compatibility - concatenates all answers
  String get answerText => answers.map((a) => a.answerText).join('\n');

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question_text': questionText,
      'language_code': languageCode,
      // answers are stored in separate table
    };
  }

  factory Question.fromMap(Map<String, dynamic> map, {List<Answer>? answers}) {
    return Question(
      id: map['id'],
      questionText: map['question_text'],
      languageCode: map['language_code'],
      answers: answers ?? [],
    );
  }
}
