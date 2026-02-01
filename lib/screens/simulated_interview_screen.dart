import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../l10n/app_localizations.dart';
import '../models/interview_question.dart';
import '../models/interview_state.dart';
import '../services/interview_service.dart';
import '../services/interview_prompt_service.dart';
import '../services/llm_service.dart';
import '../services/tts_service.dart';
import '../services/reading_evaluator.dart';
import '../widgets/progress_indicator_widget.dart';

class SimulatedInterviewScreen extends StatefulWidget {
  const SimulatedInterviewScreen({Key? key}) : super(key: key);

  @override
  State<SimulatedInterviewScreen> createState() =>
      _SimulatedInterviewScreenState();
}

class _SimulatedInterviewScreenState extends State<SimulatedInterviewScreen> {
  final InterviewService _interviewService = InterviewService();
  final InterviewPromptService _promptService = InterviewPromptService();
  final LlmService _llmService = LlmService();
  final TtsService _tts = TtsService();
  final ReadingEvaluator _evaluator = ReadingEvaluator();
  final stt.SpeechToText _speech = stt.SpeechToText();

  InterviewState? _state;
  bool _isLoading = true;
  bool _isListening = false;
  bool _isProcessing = false;
  String _currentTranscript = '';
  String _interviewerMessage = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Initialize services
      await _tts.initialize();
      await _speech.initialize();
      await _llmService.initialize();

      // Generate questions
      final questions = await _interviewService.generateInterviewQuestions();

      if (mounted) {
        setState(() {
          _state = InterviewState(questions: questions);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to initialize: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tts.dispose();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.simulatedInterview)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            )
          : _buildInterviewContent(context, l10n),
    );
  }

  Widget _buildInterviewContent(BuildContext context, AppLocalizations l10n) {
    if (_state == null) {
      return const Center(child: Text('No interview state'));
    }

    switch (_state!.phase) {
      case InterviewPhase.notStarted:
        return _buildIntroduction(l10n);
      case InterviewPhase.greeting:
        return _buildGreeting(l10n);
      case InterviewPhase.questioning:
        return _buildQuestionView(l10n);
      case InterviewPhase.completed:
        return _buildResults(l10n);
    }
  }

  Widget _buildIntroduction(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.account_balance, size: 80, color: Colors.blue),
          const SizedBox(height: 24),
          Text(
            l10n.simulatedInterview,
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Practice your citizenship interview with a realistic simulation. '
            'The interview includes reading, writing, and civics questions.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _startInterview,
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Start Interview', style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGreeting(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            _interviewerMessage.isEmpty
                ? 'Preparing interview...'
                : _interviewerMessage,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionView(AppLocalizations l10n) {
    final question = _state!.currentQuestion;
    if (question == null) return const SizedBox();

    return Column(
      children: [
        // Progress indicator
        LinearProgressIndicator(value: _state!.progressPercentage / 100),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Section indicator
                _buildSectionIndicator(question.type),
                const SizedBox(height: 24),

                // Question or text to read
                _buildQuestionDisplay(question),
                const SizedBox(height: 32),

                // Interviewer message
                if (_interviewerMessage.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _interviewerMessage,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Transcript display
                if (_currentTranscript.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_currentTranscript),
                  ),
                  const SizedBox(height: 16),
                ],

                const Spacer(),

                // Controls
                _buildControls(question),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionIndicator(InterviewQuestionType type) {
    String label;
    IconData icon;

    switch (type) {
      case InterviewQuestionType.reading:
        label = 'Reading Test';
        icon = Icons.menu_book;
        break;
      case InterviewQuestionType.writing:
        label = 'Writing Test';
        icon = Icons.edit;
        break;
      case InterviewQuestionType.civics:
        label = 'Civics Test';
        icon = Icons.account_balance;
        break;
    }

    return Row(
      children: [
        Icon(icon, size: 24),
        const SizedBox(width: 8),
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const Spacer(),
        Text(
          'Question ${_state!.currentQuestionIndex + 1} of ${_state!.questions.length}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildQuestionDisplay(InterviewQuestion question) {
    if (question.type == InterviewQuestionType.reading) {
      // Show text for reading questions
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          question.questionText,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      );
    } else {
      // For writing and civics, just show instruction
      final instruction = question.type == InterviewQuestionType.writing
          ? 'Listen carefully and write what you hear'
          : 'Answer the question verbally';

      return Text(
        instruction,
        style: Theme.of(context).textTheme.titleMedium,
        textAlign: TextAlign.center,
      );
    }
  }

  Widget _buildControls(InterviewQuestion question) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Microphone button
        ElevatedButton.icon(
          onPressed: _isProcessing ? null : _toggleListening,
          style: ElevatedButton.styleFrom(
            backgroundColor: _isListening ? Colors.red : Colors.blue,
            padding: const EdgeInsets.all(16),
          ),
          icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
          label: Text(
            _isListening ? 'Listening...' : 'Tap to Answer',
            style: const TextStyle(fontSize: 18),
          ),
        ),

        if (_currentTranscript.isNotEmpty) ...[
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isProcessing ? null : _submitAnswer,
            child: _isProcessing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Submit Answer', style: TextStyle(fontSize: 18)),
          ),
        ],
      ],
    );
  }

  Widget _buildResults(AppLocalizations l10n) {
    final summary = _state!.getSummary();
    final passed = _state!.passesCivics();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            passed ? Icons.check_circle : Icons.cancel,
            size: 80,
            color: passed ? Colors.green : Colors.red,
          ),
          const SizedBox(height: 24),
          Text(
            passed ? 'Interview Complete - Passed!' : 'Interview Complete',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _buildScoreSummary(
            'Reading',
            summary['readingCorrect'],
            summary['readingTotal'],
          ),
          _buildScoreSummary(
            'Writing',
            summary['writingCorrect'],
            summary['writingTotal'],
          ),
          _buildScoreSummary(
            'Civics',
            summary['civicsCorrect'],
            summary['civicsAsked'],
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Done', style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreSummary(String label, int correct, int total) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 18)),
          Text(
            '$correct / $total',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // Interview flow methods
  Future<void> _startInterview() async {
    setState(() {
      _state!.startInterview();
      _isProcessing = true;
    });

    // Generate and speak greeting
    final greetingPrompt = _promptService.getGreetingPrompt();
    final greeting = await _llmService.generate(greetingPrompt, maxTokens: 30);
    final cleanGreeting = _promptService.cleanResponse(greeting);

    setState(() {
      _interviewerMessage = cleanGreeting;
      _isProcessing = false;
    });

    await _tts.speak(cleanGreeting);

    // Short pause then start questioning
    await Future.delayed(const Duration(seconds: 1));
    _state!.startQuestioning();
    await _askCurrentQuestion();
  }

  Future<void> _askCurrentQuestion() async {
    final question = _state!.currentQuestion;
    if (question == null) return;

    setState(() {
      _isProcessing = true;
      _currentTranscript = '';
    });

    // Generate question prompt
    String questionPrompt;
    switch (question.type) {
      case InterviewQuestionType.reading:
        questionPrompt = _promptService.getReadingQuestionPrompt(
          question.questionText,
        );
        break;
      case InterviewQuestionType.writing:
        questionPrompt = _promptService.getWritingQuestionPrompt(
          question.questionText,
        );
        break;
      case InterviewQuestionType.civics:
        questionPrompt = _promptService.getCivicsQuestionPrompt(
          question.questionText,
        );
        break;
    }

    final questionText = await _llmService.generate(
      questionPrompt,
      maxTokens: 40,
    );
    final cleanQuestion = _promptService.cleanResponse(questionText);

    setState(() {
      _interviewerMessage = cleanQuestion;
      _isProcessing = false;
    });

    await _tts.speak(cleanQuestion);
  }

  void _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
    } else {
      final available = await _speech.initialize();
      if (!available) {
        setState(() => _error = 'Speech recognition not available');
        return;
      }

      setState(() {
        _isListening = true;
        _currentTranscript = '';
      });

      await _speech.listen(
        onResult: (result) {
          setState(() {
            _currentTranscript = result.recognizedWords;
          });
        },
        listenMode: stt.ListenMode.confirmation,
      );
    }
  }

  Future<void> _submitAnswer() async {
    if (_currentTranscript.isEmpty) return;

    setState(() => _isProcessing = true);

    final question = _state!.currentQuestion!;
    final attemptNumber = _state!.currentQuestionAttempts + 1;

    // Evaluate answer
    EvaluationResult result;
    if (question.type == InterviewQuestionType.civics) {
      result = _evaluator.evaluateCivicsAnswer(
        question.acceptableAnswers,
        _currentTranscript,
      );
    } else {
      final similarity = _evaluator.calculateSimilarity(
        question.questionText,
        _currentTranscript,
      );
      result = similarity >= ReadingEvaluator.passingThreshold
          ? EvaluationResult.pass
          : similarity >= 0.5
          ? EvaluationResult.partial
          : EvaluationResult.fail;
    }

    // Record attempt
    _state!.recordAttempt(_currentTranscript, result);

    // Generate response
    final responsePrompt = _promptService.getResponsePrompt(
      questionType: question.type,
      result: result,
      question: question.questionText,
      userAnswer: _currentTranscript,
      attemptNumber: attemptNumber,
    );

    final response = await _llmService.generate(responsePrompt, maxTokens: 40);
    final cleanResponse = _promptService.cleanResponse(response);

    setState(() {
      _interviewerMessage = cleanResponse;
      _currentTranscript = '';
      _isProcessing = false;
    });

    await _tts.speak(cleanResponse);

    // Determine next action
    if (result == EvaluationResult.pass || _state!.hasReachedMaxRetries) {
      // Move to next question
      await Future.delayed(const Duration(seconds: 1));

      // Check for short circuit
      if (_state!.canShortCircuit()) {
        _state!.completeInterview();
        setState(() {});
        return;
      }

      final hasNext = _state!.moveToNextQuestion();
      if (hasNext) {
        await _askCurrentQuestion();
      } else {
        // Interview complete
        final completionPrompt = _promptService.getCompletionPrompt(
          passed: _state!.passesCivics(),
          civicsCorrect: _state!.civicsCorrect,
          civicsTotal: _state!.civicsAsked,
        );
        final completion = await _llmService.generate(
          completionPrompt,
          maxTokens: 50,
        );
        final cleanCompletion = _promptService.cleanResponse(completion);

        setState(() {
          _interviewerMessage = cleanCompletion;
        });

        await _tts.speak(cleanCompletion);
      }
    }
    // Otherwise, wait for retry

    setState(() {});
  }
}
