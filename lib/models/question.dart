class Question {
  final int id;
  final String questionText;
  final String answerText;
  final String languageCode;

  Question({
    required this.id,
    required this.questionText,
    required this.answerText,
    required this.languageCode,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question_text': questionText,
      'answer_text': answerText,
      'language_code': languageCode,
    };
  }

  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      id: map['id'],
      questionText: map['question_text'],
      answerText: map['answer_text'],
      languageCode: map['language_code'],
    );
  }
}
