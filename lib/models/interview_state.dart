import '../models/interview_question.dart';
import '../services/reading_evaluator.dart';

/// Current phase of the interview
enum InterviewPhase {
  notStarted, // Interview hasn't begun
  greeting, // Initial greeting and small talk
  questioning, // Asking questions
  completed, // Interview finished
}

/// Result of a single question attempt
class QuestionAttempt {
  final String userResponse;
  final EvaluationResult result;
  final DateTime timestamp;

  QuestionAttempt({
    required this.userResponse,
    required this.result,
    required this.timestamp,
  });
}

/// Manages the state of a simulated interview session
class InterviewState {
  final List<InterviewQuestion> questions;

  InterviewPhase _phase = InterviewPhase.notStarted;
  int _currentQuestionIndex = 0;
  final Map<int, List<QuestionAttempt>> _attempts = {};
  final Map<int, bool> _questionPassed = {};

  // Civics-specific tracking
  int _civicsCorrect = 0;
  int _civicsAsked = 0;

  // Reading/writing tracking
  int _readingCorrect = 0;
  int _writingCorrect = 0;

  InterviewState({required this.questions});

  /// Current interview phase
  InterviewPhase get phase => _phase;

  /// Current question being asked
  InterviewQuestion? get currentQuestion {
    if (_currentQuestionIndex >= questions.length) return null;
    return questions[_currentQuestionIndex];
  }

  /// Current question index (0-based)
  int get currentQuestionIndex => _currentQuestionIndex;

  /// Total number of questions
  int get totalQuestions => questions.length;

  /// Number of attempts for current question
  int get currentQuestionAttempts {
    return _attempts[_currentQuestionIndex]?.length ?? 0;
  }

  /// Maximum retries allowed per question
  static const int maxRetries = 3;

  /// Check if current question has reached max retries
  bool get hasReachedMaxRetries {
    return currentQuestionAttempts >= maxRetries;
  }

  /// Check if current question has been passed
  bool get currentQuestionPassed {
    return _questionPassed[_currentQuestionIndex] ?? false;
  }

  /// Total civics questions correct
  int get civicsCorrect => _civicsCorrect;

  /// Total civics questions asked
  int get civicsAsked => _civicsAsked;

  /// Total reading questions correct
  int get readingCorrect => _readingCorrect;

  /// Total writing questions correct
  int get writingCorrect => _writingCorrect;

  /// Start the interview
  void startInterview() {
    _phase = InterviewPhase.greeting;
  }

  /// Move from greeting to questioning
  void startQuestioning() {
    _phase = InterviewPhase.questioning;
  }

  /// Record an attempt for the current question
  void recordAttempt(String userResponse, EvaluationResult result) {
    if (currentQuestion == null) return;

    final attempt = QuestionAttempt(
      userResponse: userResponse,
      result: result,
      timestamp: DateTime.now(),
    );

    _attempts.putIfAbsent(_currentQuestionIndex, () => []).add(attempt);

    // Track civics questions asked (only count once per question)
    if (currentQuestion!.type == InterviewQuestionType.civics &&
        (_attempts[_currentQuestionIndex]?.length ?? 0) == 1) {
      _civicsAsked++;
    }

    // Update passed status and increment counters only if passing for first time
    if (result == EvaluationResult.pass && !currentQuestionPassed) {
      _questionPassed[_currentQuestionIndex] = true;

      // Update type-specific counters
      switch (currentQuestion!.type) {
        case InterviewQuestionType.civics:
          _civicsCorrect++;
          break;
        case InterviewQuestionType.reading:
          _readingCorrect++;
          break;
        case InterviewQuestionType.writing:
          _writingCorrect++;
          break;
      }
    }
  }

  /// Move to next question
  /// Returns true if successful, false if no more questions
  bool moveToNextQuestion() {
    if (_currentQuestionIndex < questions.length - 1) {
      _currentQuestionIndex++;
      return true;
    } else {
      _phase = InterviewPhase.completed;
      return false;
    }
  }

  /// Check if interview can be short-circuited (passed civics early)
  bool canShortCircuit() {
    return _civicsCorrect >= 12;
  }

  /// Force complete the interview (e.g., when short-circuiting)
  void completeInterview() {
    _phase = InterviewPhase.completed;
  }

  /// Get all attempts for a specific question
  List<QuestionAttempt> getAttemptsForQuestion(int index) {
    return List.unmodifiable(_attempts[index] ?? []);
  }

  /// Calculate overall progress percentage
  double get progressPercentage {
    if (questions.isEmpty) return 0.0;
    return (_currentQuestionIndex / questions.length) * 100;
  }

  /// Check if user passes the civics portion
  bool passesCivics() {
    return _civicsCorrect >= 12;
  }

  /// Get interview summary
  Map<String, dynamic> getSummary() {
    final totalReading = questions
        .where((q) => q.type == InterviewQuestionType.reading)
        .length;
    final totalWriting = questions
        .where((q) => q.type == InterviewQuestionType.writing)
        .length;

    return {
      'civicsCorrect': _civicsCorrect,
      'civicsAsked': _civicsAsked,
      'civicsPassed': passesCivics(),
      'readingCorrect': _readingCorrect,
      'readingTotal': totalReading,
      'writingCorrect': _writingCorrect,
      'writingTotal': totalWriting,
      'totalQuestions': questions.length,
      'questionsAnswered':
          _currentQuestionIndex + (_phase == InterviewPhase.completed ? 1 : 0),
      'phase': _phase.toString(),
    };
  }
}
