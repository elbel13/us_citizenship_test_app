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
import '../widgets/circular_action_button.dart';
import '../widgets/instruction_card.dart';
import '../widgets/answer_text_field.dart';

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
  bool _isSpeaking = false;
  bool _useTextInput = false;
  String _currentTranscript = '';
  String _interviewerMessage = '';
  String? _error;
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Initialize services
      await _tts.initialize();
      // Setup TTS callbacks to track speaking state
      _tts.onSpeakStart = () {
        if (mounted) {
          debugPrint('TTS: Started speaking');
          setState(() => _isSpeaking = true);
        }
      };

      _tts.onSpeakComplete = () {
        if (mounted) {
          debugPrint('TTS: Finished speaking');
          setState(() => _isSpeaking = false);
        }
      };
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
                  Card(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        _interviewerMessage,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Transcript display
                if (_currentTranscript.isNotEmpty) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        _currentTranscript,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
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
      return Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            question.questionText,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else {
      // For writing and civics, show instruction in a Card
      final instruction = question.type == InterviewQuestionType.writing
          ? 'Listen carefully and write what you hear'
          : 'Answer the question verbally';

      return InstructionCard(text: instruction);
    }
  }

  Widget _buildControls(InterviewQuestion question) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Input mode toggle
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Voice', style: TextStyle(fontSize: 14)),
            Switch(
              value: _useTextInput,
              onChanged: (value) {
                setState(() => _useTextInput = value);
                if (!value) {
                  _textController.clear();
                }
              },
            ),
            const Text('Text', style: TextStyle(fontSize: 14)),
          ],
        ),
        const SizedBox(height: 16),

        if (_useTextInput)
          // Text input mode
          Column(
            children: [
              AnswerTextField(
                controller: _textController,
                labelText: 'Type your answer here',
                hintText: 'Enter your answer...',
                onChanged: (value) {
                  setState(() => _currentTranscript = value);
                },
                showSubmitButton: _currentTranscript.isNotEmpty,
                onSubmit: _submitAnswer,
                submitButtonText: 'Submit Answer',
                isSubmitting: _isProcessing,
              ),
            ],
          )
        else
          // Voice input mode - circular button like reading/writing
          Center(
            child: Column(
              children: [
                CircularActionButton(
                  onTap: _isProcessing ? null : _toggleListening,
                  icon: _isListening ? Icons.mic : Icons.mic_none,
                  color: _isProcessing
                      ? Colors.grey
                      : (_isListening ? Colors.red : Colors.blue),
                  isActive: _isListening,
                  showProgress: _isProcessing,
                  statusText: _isListening ? 'Listening...' : 'Tap to Answer',
                ),
                if (_currentTranscript.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _submitAnswer,
                    icon: const Icon(Icons.check),
                    label: const Text('Submit Answer'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 32,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
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

    // Get greeting (no LLM - instant response)
    final greeting = _promptService.getGreetingPrompt();

    setState(() {
      _interviewerMessage = greeting;
      _isProcessing = false;
      _isSpeaking = true; // Pre-set to ensure wait loop catches it
    });

    await _tts.speak(greeting);

    // Wait for TTS to finish speaking (with timeout)
    debugPrint('Waiting for greeting TTS to complete...');
    int waitCount = 0;
    while (_isSpeaking && waitCount < 100) {
      // Max 10 seconds
      await Future.delayed(const Duration(milliseconds: 100));
      waitCount++;
    }
    debugPrint('Greeting TTS complete (waited ${waitCount * 100}ms)');

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

    // Generate question prompt (no LLM - instant response)
    String questionText;
    switch (question.type) {
      case InterviewQuestionType.reading:
        questionText = _promptService.getReadingQuestionPrompt(
          question.questionText,
        );
        break;
      case InterviewQuestionType.writing:
        questionText = _promptService.getWritingQuestionPrompt(
          question.questionText,
        );
        break;
      case InterviewQuestionType.civics:
        questionText = _promptService.getCivicsQuestionPrompt(
          question.questionText,
        );
        break;
    }

    setState(() {
      _interviewerMessage = questionText;
      _isProcessing = false;
      _isSpeaking = true; // Pre-set to ensure wait loop catches it
    });

    await _tts.speak(questionText);

    // Wait for TTS to finish speaking (with timeout)
    int waitCount = 0;
    while (_isSpeaking && waitCount < 100) {
      // Max 10 seconds
      await Future.delayed(const Duration(milliseconds: 100));
      waitCount++;
    }
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

    // Clear text input if in text mode
    if (_useTextInput) {
      _textController.clear();
    }

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

    // Get response (no LLM - instant response)
    final response = _promptService.getResponsePrompt(
      questionType: question.type,
      result: result,
      question: question.questionText,
      userAnswer: _currentTranscript,
      attemptNumber: attemptNumber,
    );

    setState(() {
      _interviewerMessage = response;
      _currentTranscript = '';
      _isProcessing = false;
      _isSpeaking = true; // Pre-set to ensure wait loop catches it
    });

    await _tts.speak(response);

    // Wait for TTS to finish speaking (with timeout)
    int waitCount = 0;
    while (_isSpeaking && waitCount < 100) {
      // Max 10 seconds
      await Future.delayed(const Duration(milliseconds: 100));
      waitCount++;
    }

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
        final completion = _promptService.getCompletionPrompt(
          passed: _state!.passesCivics(),
          civicsCorrect: _state!.civicsCorrect,
          civicsTotal: _state!.civicsAsked,
        );

        setState(() {
          _interviewerMessage = completion;
          _isSpeaking = true; // Pre-set to ensure wait loop catches it
        });

        await _tts.speak(completion);

        // Wait for TTS to finish speaking (with timeout)
        int waitCount = 0;
        while (_isSpeaking && waitCount < 100) {
          // Max 10 seconds
          await Future.delayed(const Duration(milliseconds: 100));
          waitCount++;
        }
      }
    }
    // Otherwise, wait for retry

    setState(() {});
  }
}
