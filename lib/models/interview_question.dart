/// Type of question in the citizenship interview
enum InterviewQuestionType {
  reading, // User reads text aloud
  writing, // User writes dictated sentence
  civics, // User answers civics question verbally
}

/// Represents a question in the simulated interview
class InterviewQuestion {
  final InterviewQuestionType type;
  final String questionText;
  final List<String> acceptableAnswers;

  /// For reading questions: the text to display and read
  /// For writing questions: vocabularyWords list (for categorization)
  /// For civics questions: empty
  final Map<String, dynamic>? metadata;

  InterviewQuestion({
    required this.type,
    required this.questionText,
    required this.acceptableAnswers,
    this.metadata,
  });

  /// Create a reading question
  factory InterviewQuestion.reading({
    required String text,
    required List<String> vocabularyWords,
    String? category,
  }) {
    return InterviewQuestion(
      type: InterviewQuestionType.reading,
      questionText: text,
      acceptableAnswers: [text], // Expected answer is the text itself
      metadata: {
        'vocabularyWords': vocabularyWords,
        if (category != null) 'category': category,
      },
    );
  }

  /// Create a writing question
  factory InterviewQuestion.writing({
    required String text,
    required List<String> vocabularyWords,
    String? category,
  }) {
    return InterviewQuestion(
      type: InterviewQuestionType.writing,
      questionText: text,
      acceptableAnswers: [text], // Expected answer is the text itself
      metadata: {
        'vocabularyWords': vocabularyWords,
        if (category != null) 'category': category,
      },
    );
  }

  /// Create a civics question
  factory InterviewQuestion.civics({
    required String question,
    required List<String> answers,
  }) {
    return InterviewQuestion(
      type: InterviewQuestionType.civics,
      questionText: question,
      acceptableAnswers: answers,
    );
  }

  @override
  String toString() {
    return 'InterviewQuestion{type: $type, question: $questionText, answers: ${acceptableAnswers.length}}';
  }
}
