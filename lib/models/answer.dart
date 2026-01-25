class Answer {
  final int id;
  final int questionTextId;
  final String answerText;
  final int categoryId;

  Answer({
    required this.id,
    required this.questionTextId,
    required this.answerText,
    required this.categoryId,
  });

  // Convert Answer to a Map for database insertion
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question_text_id': questionTextId,
      'answer_text': answerText,
      'category_id': categoryId,
    };
  }

  // Create Answer from a Map (database query result)
  factory Answer.fromMap(Map<String, dynamic> map) {
    return Answer(
      id: map['id'] as int,
      questionTextId: map['question_text_id'] as int,
      answerText: map['answer_text'] as String,
      categoryId: map['category_id'] as int,
    );
  }

  @override
  String toString() {
    return 'Answer{id: $id, questionTextId: $questionTextId, answerText: $answerText, categoryId: $categoryId}';
  }
}
