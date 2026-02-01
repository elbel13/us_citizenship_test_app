import 'dart:math';
import '../models/interview_question.dart';
import 'database_service.dart';
import 'reading_sentence_service.dart';
import 'writing_sentence_service.dart';

/// Service for generating interview question sets
class InterviewService {
  final DatabaseService _dbService = DatabaseService();
  final ReadingSentenceService _readingService = ReadingSentenceService();
  final WritingSentenceService _writingService = WritingSentenceService();
  final Random _random = Random();

  /// Generate a complete interview question set
  /// Returns questions in randomized section order
  Future<List<InterviewQuestion>> generateInterviewQuestions({
    String languageCode = 'en',
  }) async {
    // Get all question pools
    final readingSentences = await _readingService.getAllSentences();
    final writingSentences = await _writingService.getAllSentences();
    final civicsQuestions = await _dbService.getQuestions(languageCode);

    if (readingSentences.length < 3) {
      throw Exception('Not enough reading sentences available');
    }
    if (writingSentences.length < 3) {
      throw Exception('Not enough writing sentences available');
    }
    if (civicsQuestions.length < 20) {
      throw Exception('Not enough civics questions available');
    }

    // Select random questions
    final selectedReading = _selectRandom(readingSentences, 3);
    final selectedWriting = _selectRandom(writingSentences, 3);
    final selectedCivics = _selectRandom(civicsQuestions, 20);

    // Convert to InterviewQuestion format
    final List<InterviewQuestion> questions = [];

    // Add reading questions
    questions.addAll(
      selectedReading.map(
        (sentence) => InterviewQuestion.reading(
          text: sentence.text,
          vocabularyWords: sentence.vocabularyWords,
          category: sentence.category,
        ),
      ),
    );

    // Add writing questions
    questions.addAll(
      selectedWriting.map(
        (sentence) => InterviewQuestion.writing(
          text: sentence.text,
          vocabularyWords: sentence.vocabularyWords,
          category: sentence.category,
        ),
      ),
    );

    // Add civics questions
    questions.addAll(
      selectedCivics.map(
        (question) => InterviewQuestion.civics(
          question: question.questionText,
          answers: question.answers.map((a) => a.answerText).toList(),
        ),
      ),
    );

    // Randomize section order but keep questions within sections grouped
    final sections = <List<InterviewQuestion>>[
      questions.where((q) => q.type == InterviewQuestionType.reading).toList(),
      questions.where((q) => q.type == InterviewQuestionType.writing).toList(),
      questions.where((q) => q.type == InterviewQuestionType.civics).toList(),
    ];

    sections.shuffle(_random);

    return sections.expand((section) => section).toList();
  }

  /// Select N random items from a list
  List<T> _selectRandom<T>(List<T> items, int count) {
    final shuffled = List<T>.from(items)..shuffle(_random);
    return shuffled.take(count).toList();
  }

  /// Check if interview can be short-circuited (12 civics correct)
  /// Returns true if user can pass early
  bool canPassEarly({
    required int correctCivicsAnswers,
    required int totalCivicsAsked,
  }) {
    // Need 12 correct to pass
    if (correctCivicsAnswers >= 12) {
      return true;
    }

    // Check if it's mathematically possible to still pass
    final remainingQuestions = 20 - totalCivicsAsked;
    final maxPossibleCorrect = correctCivicsAnswers + remainingQuestions;

    return maxPossibleCorrect < 12; // Can't pass anymore
  }

  /// Calculate final civics score result
  bool passesCivicsTest(int correctAnswers) {
    return correctAnswers >= 12;
  }
}
