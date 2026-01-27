import 'dart:math';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/question.dart';
import '../services/database_service.dart';
import '../widgets/progress_indicator_widget.dart';

class MultipleChoiceScreen extends StatefulWidget {
  const MultipleChoiceScreen({Key? key}) : super(key: key);

  @override
  State<MultipleChoiceScreen> createState() => _MultipleChoiceScreenState();
}

class _MultipleChoiceScreenState extends State<MultipleChoiceScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<Question> _allQuestions = [];
  List<_QuizQuestion> _quizQuestions = [];
  int _currentQuestionIndex = 0;
  int _correctAnswers = 0;
  int _incorrectAnswers = 0;
  bool _isLoading = true;
  String? _error;
  bool _hasLoadedQuestions = false;
  bool _hasAnswered = false;
  Set<int> _selectedAnswerIndices = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoadedQuestions) {
      _hasLoadedQuestions = true;
      _loadQuestions();
    }
  }

  Future<void> _loadQuestions() async {
    try {
      final locale = Localizations.localeOf(context);
      final questions = await _databaseService.getQuestions(
        locale.languageCode,
      );

      if (mounted) {
        setState(() {
          _allQuestions = questions;
          _isLoading = false;
        });
        await _prepareQuiz();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _prepareQuiz() async {
    final shuffledQuestions = List<Question>.from(_allQuestions)..shuffle();

    _quizQuestions = [];
    for (var question in shuffledQuestions) {
      // Get all unique category IDs from this question's answers
      final categoryIds = question.answers
          .map((a) => a.categoryId)
          .toSet()
          .toList();

      // Detect if question requires multiple answers
      final questionTextLower = question.questionText.toLowerCase();
      final requiresMultiple =
          questionTextLower.contains('two ') ||
          questionTextLower.contains('name two') ||
          questionTextLower.contains('what are two');

      final correctAnswers = <String>[];
      if (requiresMultiple && question.answers.length >= 2) {
        // Pick 2-3 correct answers for multi-answer questions
        final shuffledCorrect = List.from(question.answers)..shuffle();
        final numCorrect = min(3, question.answers.length);
        for (var i = 0; i < numCorrect; i++) {
          correctAnswers.add(shuffledCorrect[i].answerText);
        }
      } else {
        // Pick one correct answer for single-answer questions
        final correctAnswer = question
            .answers[Random().nextInt(question.answers.length)]
            .answerText;
        correctAnswers.add(correctAnswer);
      }

      // Get wrong answers from the same categories
      final numWrong = requiresMultiple ? 2 : 3;
      final incorrectAnswers = await _databaseService
          .getWrongAnswersByCategories(question.id, categoryIds, numWrong);

      // Combine correct and incorrect answers and shuffle
      final allAnswers = [...correctAnswers, ...incorrectAnswers]..shuffle();

      // Find indices of all correct answers
      final correctIndices = <int>[];
      for (var correctAns in correctAnswers) {
        final index = allAnswers.indexOf(correctAns);
        if (index != -1) correctIndices.add(index);
      }

      _quizQuestions.add(
        _QuizQuestion(
          question: question,
          answers: allAnswers,
          correctAnswerIndices: correctIndices,
          requiresMultiple: requiresMultiple,
        ),
      );
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _selectAnswer(int index) {
    if (_hasAnswered) return;

    final currentQuestion = _quizQuestions[_currentQuestionIndex];

    setState(() {
      if (_selectedAnswerIndices.contains(index)) {
        _selectedAnswerIndices.remove(index);
      } else {
        if (currentQuestion.requiresMultiple) {
          _selectedAnswerIndices.add(index);
        } else {
          // For single answer, replace selection
          _selectedAnswerIndices = {index};
        }
      }
    });
  }

  void _submitAnswer() {
    if (_hasAnswered) return;
    final currentQuestion = _quizQuestions[_currentQuestionIndex];

    // Require at least the minimum number of selections for multi-answer questions
    if (currentQuestion.requiresMultiple && _selectedAnswerIndices.length < 2) {
      return; // Don't submit until at least 2 are selected
    }
    if (!currentQuestion.requiresMultiple && _selectedAnswerIndices.isEmpty) {
      return; // Don't submit if nothing selected
    }

    setState(() {
      _hasAnswered = true;

      // Check if answer is correct
      final selectedCorrect = _selectedAnswerIndices
          .where((i) => currentQuestion.correctAnswerIndices.contains(i))
          .length;
      final selectedWrong = _selectedAnswerIndices.length - selectedCorrect;

      // For multi-answer: need at least 2 correct and no wrong answers
      // For single-answer: need exactly the correct answer
      final isCorrect = currentQuestion.requiresMultiple
          ? (selectedCorrect >= 2 && selectedWrong == 0)
          : (selectedCorrect == 1 && selectedWrong == 0);

      if (isCorrect) {
        _correctAnswers++;
      } else {
        _incorrectAnswers++;
      }
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _quizQuestions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _hasAnswered = false;
        _selectedAnswerIndices.clear();
      });
    }
  }

  void _restartQuiz() {
    setState(() {
      _currentQuestionIndex = 0;
      _correctAnswers = 0;
      _incorrectAnswers = 0;
      _hasAnswered = false;
      _selectedAnswerIndices.clear();
    });
    _prepareQuiz();
  }

  bool get _isQuizComplete =>
      _currentQuestionIndex == _quizQuestions.length - 1 && _hasAnswered;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.multipleChoice)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text('Error: $_error'))
          : _quizQuestions.isEmpty
          ? const Center(child: Text('No questions available'))
          : _isQuizComplete
          ? _buildSummaryScreen(l10n)
          : _buildQuizScreen(),
    );
  }

  Widget _buildQuizScreen() {
    final currentQuestion = _quizQuestions[_currentQuestionIndex];

    return Column(
      children: [
        // Progress and score display
        ProgressIndicatorWidget(
          currentIndex: _currentQuestionIndex,
          totalItems: _quizQuestions.length,
          correctAnswers: _correctAnswers,
          incorrectAnswers: _incorrectAnswers,
          itemLabel: 'Question',
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Question text
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      currentQuestion.question.questionText,
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (currentQuestion.requiresMultiple && !_hasAnswered)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Select at least 2 correct answers',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 24),
                // Answer choices
                ...List.generate(
                  currentQuestion.answers.length,
                  (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _buildAnswerButton(
                      currentQuestion.answers[index],
                      index,
                      currentQuestion,
                    ),
                  ),
                ),
                if (!_hasAnswered && _selectedAnswerIndices.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _submitAnswer,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16.0),
                      backgroundColor: Colors.blue,
                    ),
                    child: Text(
                      currentQuestion.requiresMultiple
                          ? 'Submit Answers (${_selectedAnswerIndices.length} selected)'
                          : 'Submit Answer',
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ],
                if (_hasAnswered) ...[
                  const SizedBox(height: 24),
                  // Feedback message
                  _buildFeedbackMessage(currentQuestion),
                  const SizedBox(height: 16),
                  // Next button
                  ElevatedButton(
                    onPressed: _nextQuestion,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16.0),
                    ),
                    child: Text(
                      _currentQuestionIndex < _quizQuestions.length - 1
                          ? 'Next Question'
                          : 'View Results',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnswerButton(
    String answer,
    int index,
    _QuizQuestion quizQuestion,
  ) {
    Color? backgroundColor;
    Color? borderColor;
    IconData? icon;
    final isSelected = _selectedAnswerIndices.contains(index);
    final isCorrect = quizQuestion.correctAnswerIndices.contains(index);
    final theme = Theme.of(context);

    if (_hasAnswered) {
      if (isCorrect) {
        // Correct answer: use tertiary colors (typically green in Material 3)
        backgroundColor = theme.colorScheme.tertiaryContainer;
        borderColor = theme.colorScheme.tertiary;
        icon = Icons.check_circle;
      } else if (isSelected) {
        // Wrong answer: use error colors (typically red)
        backgroundColor = theme.colorScheme.errorContainer;
        borderColor = theme.colorScheme.error;
        icon = Icons.cancel;
      }
    } else if (isSelected) {
      backgroundColor = theme.colorScheme.primaryContainer;
      borderColor = theme.colorScheme.primary;
    }

    return InkWell(
      onTap: () => _selectAnswer(index),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: backgroundColor ?? theme.colorScheme.surface,
          border: Border.all(
            color: borderColor ?? theme.colorScheme.outlineVariant,
            width: borderColor != null && _hasAnswered ? 3 : 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            if (quizQuestion.requiresMultiple && !_hasAnswered)
              Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: Icon(
                  isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                  color: isSelected ? Colors.blue : Colors.grey,
                ),
              ),
            Expanded(child: Text(answer, style: const TextStyle(fontSize: 16))),
            if (icon != null) Icon(icon, color: borderColor),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackMessage(_QuizQuestion quizQuestion) {
    final selectedCorrect = _selectedAnswerIndices
        .where((i) => quizQuestion.correctAnswerIndices.contains(i))
        .length;
    final selectedWrong = _selectedAnswerIndices.length - selectedCorrect;

    final isCorrect = quizQuestion.requiresMultiple
        ? (selectedCorrect >= 2 && selectedWrong == 0)
        : (selectedCorrect == 1 && selectedWrong == 0);

    return Card(
      color: isCorrect
          ? Theme.of(context).colorScheme.tertiaryContainer
          : Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              isCorrect ? Icons.check_circle : Icons.cancel,
              color: isCorrect
                  ? Theme.of(context).colorScheme.tertiary
                  : Theme.of(context).colorScheme.error,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isCorrect ? 'Correct!' : 'Incorrect!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isCorrect
                      ? Theme.of(context).colorScheme.onTertiaryContainer
                      : Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryScreen(AppLocalizations l10n) {
    final percentage = (_correctAnswers / _quizQuestions.length * 100).round();

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events,
              size: 80,
              color: percentage >= 70 ? Colors.amber : Colors.grey,
            ),
            const SizedBox(height: 24),
            Text(
              'Quiz Complete!',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Text(
                      'Your Score',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '$_correctAnswers / ${_quizQuestions.length}',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$percentage%',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 32,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$_correctAnswers',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text('Correct'),
                          ],
                        ),
                        Column(
                          children: [
                            Icon(Icons.cancel, color: Colors.red, size: 32),
                            const SizedBox(height: 8),
                            Text(
                              '$_incorrectAnswers',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text('Incorrect'),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _restartQuiz,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.home),
              label: const Text('Back to Menu'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuizQuestion {
  final Question question;
  final List<String> answers;
  final List<int> correctAnswerIndices;
  final bool requiresMultiple;

  _QuizQuestion({
    required this.question,
    required this.answers,
    required this.correctAnswerIndices,
    required this.requiresMultiple,
  });
}
