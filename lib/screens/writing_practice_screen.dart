import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/writing_sentence.dart';
import '../services/writing_sentence_service.dart';
import '../services/reading_evaluator.dart';
import '../widgets/progress_indicator_widget.dart';

class WritingPracticeScreen extends StatefulWidget {
  const WritingPracticeScreen({super.key});

  @override
  State<WritingPracticeScreen> createState() => _WritingPracticeScreenState();
}

class _WritingPracticeScreenState extends State<WritingPracticeScreen> {
  final WritingSentenceService _sentenceService = WritingSentenceService();
  final ReadingEvaluator _evaluator = ReadingEvaluator();
  final FlutterTts _tts = FlutterTts();
  final TextEditingController _inputController = TextEditingController();

  List<WritingSentence> _allSentences = [];
  int _currentSentenceIndex = 0;
  WritingSentence? _currentSentence;
  bool _isLoading = true;
  bool _isSpeaking = false;
  double? _similarityScore;
  String _feedback = '';
  bool _hasAttempted = false;
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
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5); // Slower for dictation
    await _tts.setPitch(1.0);

    _tts.setStartHandler(() {
      if (mounted) {
        setState(() => _isSpeaking = true);
      }
    });

    _tts.setCompletionHandler(() {
      if (mounted) {
        setState(() => _isSpeaking = false);
      }
    });

    _tts.setErrorHandler((msg) {
      if (mounted) {
        setState(() => _isSpeaking = false);
        _showError('Speech error: $msg');
      }
    });
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
    if (_currentSentence == null || _isSpeaking) return;

    await _tts.speak(_currentSentence!.text);
  }

  Future<void> _stopSpeaking() async {
    await _tts.stop();
    setState(() => _isSpeaking = false);
  }

  void _submitAnswer() {
    final userText = _inputController.text.trim();
    if (userText.isEmpty || _currentSentence == null) return;

    final score = _evaluator.calculateSimilarity(
      _currentSentence!.text,
      userText,
    );

    setState(() {
      _similarityScore = score;
      _feedback = _evaluator.getFeedback(score);
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How to Use'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Writing Practice',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text('1. Press the Play button to hear the sentence'),
              SizedBox(height: 4),
              Text('2. Type what you hear in the text field'),
              SizedBox(height: 4),
              Text('3. Press Submit to check your answer'),
              SizedBox(height: 4),
              Text('4. You can replay the sentence as many times as needed'),
              SizedBox(height: 12),
              Text('Scoring:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('• 80% or higher: Pass'),
              Text('• Below 80%: Try again'),
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
    return SingleChildScrollView(
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
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: const Padding(
              padding: EdgeInsets.all(12.0),
              child: Text(
                'Listen to the sentence and type what you hear.',
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Audio playback button
          Center(
            child: Column(
              children: [
                InkWell(
                  onTap: _isSpeaking ? _stopSpeaking : _speakSentence,
                  borderRadius: BorderRadius.circular(50),
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: _isSpeaking ? Colors.red : Colors.blue,
                      shape: BoxShape.circle,
                      boxShadow: [
                        if (_isSpeaking)
                          BoxShadow(
                            color: Colors.red.withOpacity(0.5),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                      ],
                    ),
                    child: Icon(
                      _isSpeaking ? Icons.stop : Icons.play_arrow,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _isSpeaking ? 'Speaking...' : 'Tap to play',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Text input
          TextField(
            controller: _inputController,
            decoration: InputDecoration(
              labelText: 'Type your answer here',
              hintText: 'Write what you hear...',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => _inputController.clear(),
              ),
            ),
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            enabled: !_hasAttempted,
          ),
          const SizedBox(height: 16),

          // Submit button
          if (!_hasAttempted)
            ElevatedButton.icon(
              onPressed: _submitAnswer,
              icon: const Icon(Icons.check),
              label: const Text('Submit & Evaluate'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
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
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                ),
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
    );
  }
}
