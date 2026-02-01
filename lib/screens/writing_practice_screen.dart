import 'package:flutter/material.dart';
import '../models/writing_sentence.dart';
import '../services/writing_sentence_service.dart';
import '../services/reading_evaluator.dart';
import '../services/tts_service.dart';
import '../widgets/progress_indicator_widget.dart';
import '../widgets/word_diff_display.dart';
import '../widgets/circular_action_button.dart';
import '../widgets/instruction_card.dart';
import '../widgets/answer_text_field.dart';
import '../theme/word_diff_colors.dart';

class WritingPracticeScreen extends StatefulWidget {
  const WritingPracticeScreen({super.key});

  @override
  State<WritingPracticeScreen> createState() => _WritingPracticeScreenState();
}

class _WritingPracticeScreenState extends State<WritingPracticeScreen> {
  final WritingSentenceService _sentenceService = WritingSentenceService();
  final ReadingEvaluator _evaluator = ReadingEvaluator();
  final TtsService _tts = TtsService();
  final TextEditingController _inputController = TextEditingController();

  List<WritingSentence> _allSentences = [];
  int _currentSentenceIndex = 0;
  WritingSentence? _currentSentence;
  bool _isLoading = true;
  double? _similarityScore;
  String _feedback = '';
  bool _hasAttempted = false;
  List<WordDiff>? _wordDiff;
  int _correctAnswers = 0;
  int _incorrectAnswers = 0;
  int _totalSentences = 0;

  @override
  void initState() {
    super.initState();
    _initializeTts();
    _loadAllSentences();
  }

  Future<void> _initializeTts() async {
    await _tts.initialize(
      language: 'en-US',
      speechRate: 0.5, // Slower for dictation
      pitch: 1.0,
    );

    _tts.onSpeakStart = () {
      if (mounted) setState(() {});
    };

    _tts.onSpeakComplete = () {
      if (mounted) setState(() {});
    };

    _tts.onError = (msg) {
      if (mounted) _showError(msg);
    };
  }

  Future<void> _loadAllSentences() async {
    try {
      final sentences = await _sentenceService.getAllSentences();
      if (mounted) {
        setState(() {
          _allSentences = sentences..shuffle();
          _totalSentences = sentences.length;
          _currentSentenceIndex = 0;
          _isLoading = false;
          if (_allSentences.isNotEmpty) {
            _currentSentence = _allSentences[_currentSentenceIndex];
          }
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to load sentences: $e');
    }
  }

  void _loadSentence() {
    setState(() {
      _hasAttempted = false;
      _similarityScore = null;
      _feedback = '';
      _wordDiff = null;
      _inputController.clear();

      // Move to next sentence, or reshuffle if we've gone through all
      _currentSentenceIndex++;
      if (_currentSentenceIndex >= _allSentences.length) {
        _allSentences.shuffle();
        _currentSentenceIndex = 0;
      }

      if (_allSentences.isNotEmpty) {
        _currentSentence = _allSentences[_currentSentenceIndex];
      }
    });
  }

  Future<void> _speakSentence() async {
    if (_currentSentence == null || _tts.isSpeaking) return;

    await _tts.speak(_currentSentence!.text);
  }

  Future<void> _stopSpeaking() async {
    await _tts.stop();
  }

  void _submitAnswer() {
    final userText = _inputController.text.trim();
    if (userText.isEmpty || _currentSentence == null) return;

    final score = _evaluator.calculateSimilarity(
      _currentSentence!.text,
      userText,
    );

    final wordDiff = _evaluator.getWordDiff(_currentSentence!.text, userText);

    setState(() {
      _similarityScore = score;
      _feedback = _evaluator.getFeedback(score);
      _wordDiff = wordDiff;
      _hasAttempted = true;

      // Update tally
      if (_evaluator.isPassing(score)) {
        _correctAnswers++;
      } else {
        _incorrectAnswers++;
      }
    });
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showInstructions() {
    final colors = Theme.of(context).extension<WordDiffColors>()!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How to Use'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Writing Practice',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text('1. Press the Play button to hear the sentence'),
              const SizedBox(height: 4),
              const Text('2. Type what you hear in the text field'),
              const SizedBox(height: 4),
              const Text('3. Press Submit to check your answer'),
              const SizedBox(height: 4),
              const Text(
                '4. You can replay the sentence as many times as needed',
              ),
              const SizedBox(height: 12),
              const Text(
                'Scoring:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text('• 80% or higher: Pass'),
              const Text('• Below 80%: Try again'),
              const SizedBox(height: 16),
              const Text(
                'Word-by-word Analysis:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: colors.correctWordColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Green',
                    style: TextStyle(
                      color: colors.correctWordColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Text(' = Correct word'),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.remove_circle,
                    size: 16,
                    color: colors.missingWordColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Gray',
                    style: TextStyle(
                      color: colors.missingWordColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Text(' = Missing word'),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.add_circle,
                    size: 16,
                    color: colors.extraWordColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Orange',
                    style: TextStyle(
                      color: colors.extraWordColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Text(' = Extra word'),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 0.90) return Colors.green;
    if (score >= ReadingEvaluator.passingThreshold) return Colors.orange;
    return Colors.red;
  }

  @override
  void dispose() {
    _tts.stop();
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Writing Practice'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showInstructions(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress and score display
            if (_totalSentences > 0) ...[
              ProgressIndicatorWidget(
                totalItems: _totalSentences,
                correctAnswers: _correctAnswers,
                incorrectAnswers: _incorrectAnswers,
                itemLabel: 'Sentence',
              ),
              const SizedBox(height: 16),
            ],

            // Instructions
            const InstructionCard(
              text: 'Listen to the sentence and type what you hear.',
            ),
            const SizedBox(height: 24),

            // Audio playback button
            Center(
              child: CircularActionButton(
                onTap: _tts.isSpeaking ? _stopSpeaking : _speakSentence,
                icon: _tts.isSpeaking ? Icons.stop : Icons.play_arrow,
                color: _tts.isSpeaking ? Colors.red : Colors.blue,
                isActive: _tts.isSpeaking,
                statusText: _tts.isSpeaking ? 'Speaking...' : 'Tap to play',
              ),
            ),
            const SizedBox(height: 24),

            // Text input
            AnswerTextField(
              controller: _inputController,
              labelText: 'Type your answer here',
              hintText: 'Write what you hear...',
              enabled: !_hasAttempted,
              showSubmitButton: !_hasAttempted,
              onSubmit: _submitAnswer,
            ),

            // Display the original sentence that was read
            if (_hasAttempted && _currentSentence != null) ...[
              const SizedBox(height: 16),
              Text(
                'Sentence read:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _currentSentence!.text,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],

            // Word-by-word diff (if available)
            if (_wordDiff != null && _hasAttempted) ...[
              const SizedBox(height: 16),
              Text(
                'Word-by-word analysis:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: WordDiffDisplay(wordDiffs: _wordDiff!),
                ),
              ),
            ],

            // Results
            if (_similarityScore != null && _hasAttempted) ...[
              const SizedBox(height: 16),
              Card(
                color: _getScoreColor(_similarityScore!).withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'Score: ${_evaluator.getPercentageScore(_similarityScore!)}%',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: _getScoreColor(_similarityScore!),
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _feedback,
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      if (_evaluator.isPassing(_similarityScore!))
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 40,
                        )
                      else
                        const Icon(Icons.cancel, color: Colors.red, size: 40),
                    ],
                  ),
                ),
              ),
            ],

            // Action buttons
            if (_hasAttempted) ...[
              const SizedBox(height: 16),
              if (_similarityScore != null &&
                  !_evaluator.isPassing(_similarityScore!))
                // Show both "Try Again" and "Next" if failed
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _hasAttempted = false;
                            _similarityScore = null;
                            _feedback = '';
                            _wordDiff = null;
                            _inputController.clear();
                            _incorrectAnswers--;
                          });
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orange,
                          side: const BorderSide(color: Colors.orange),
                          minimumSize: const Size(0, 48),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _loadSentence,
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Next'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 48),
                        ),
                      ),
                    ),
                  ],
                )
              else
                // Show only "Next" if passed
                ElevatedButton.icon(
                  onPressed: _loadSentence,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Next Sentence'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
