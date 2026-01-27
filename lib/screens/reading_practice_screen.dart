import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import '../models/reading_sentence.dart';
import '../services/reading_sentence_service.dart';
import '../services/reading_evaluator.dart';
import '../widgets/progress_indicator_widget.dart';

class ReadingPracticeScreen extends StatefulWidget {
  const ReadingPracticeScreen({super.key});

  @override
  State<ReadingPracticeScreen> createState() => _ReadingPracticeScreenState();
}

class _ReadingPracticeScreenState extends State<ReadingPracticeScreen> {
  final ReadingSentenceService _sentenceService = ReadingSentenceService();
  final ReadingEvaluator _evaluator = ReadingEvaluator();
  late stt.SpeechToText _speech;
  final TextEditingController _testInputController = TextEditingController();

  List<ReadingSentence> _allSentences = [];
  int _currentSentenceIndex = 0;
  ReadingSentence? _currentSentence;
  bool _isLoading = true;
  bool _isListening = false;
  bool _speechAvailable = false;
  bool _speechInitializing = true;
  bool _testMode = false;
  String _spokenText = '';
  double? _similarityScore;
  String _feedback = '';
  bool _hasAttempted = false;
  int _correctAnswers = 0;
  int _incorrectAnswers = 0;
  int _totalSentences = 0;

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
    _loadAllSentences();
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

  Future<void> _initializeSpeech() async {
    _speech = stt.SpeechToText();

    setState(() => _speechInitializing = true);

    // Request microphone permission
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      setState(() {
        _speechInitializing = false;
        _speechAvailable = false;
      });
      _showError('Microphone permission is required for reading practice');
      return;
    }

    try {
      final available = await _speech.initialize(
        onError: (error) {
          if (mounted) {
            // Handle timeout errors more gracefully - don't show error since it's expected
            if (error.errorMsg.contains('timeout')) {
              if (_isListening) {
                setState(() => _isListening = false);
                // Only show message if we have some text
                if (_spokenText.isNotEmpty) {
                  _showInfo('Stopped listening. Review your result below.');
                }
              }
            } else if (error.errorMsg.contains('network')) {
              setState(() => _isListening = false);
              _showInfo(
                'Network issue detected. Speech recognition works best with internet connection.',
              );
            } else if (!error.errorMsg.contains('error_audio')) {
              // Ignore audio errors which are often false positives
              _showError('Speech error: ${error.errorMsg}');
            }
          }
        },
        onStatus: (status) {
          if (mounted) {
            if (status == 'notListening' && _isListening) {
              setState(() => _isListening = false);
              // Auto-evaluate if we have text
              if (_spokenText.isNotEmpty && !_hasAttempted) {
                _evaluateReading();
              }
            }
          }
        },
      );

      setState(() {
        _speechAvailable = available;
        _speechInitializing = false;
      });

      if (!available) {
        _showError('Speech recognition is not available on this device');
      }
    } catch (e) {
      setState(() {
        _speechAvailable = false;
        _speechInitializing = false;
      });
      _showError('Failed to initialize speech recognition: $e');
    }
  }

  void _loadSentence() {
    setState(() {
      _hasAttempted = false;
      _spokenText = '';
      _similarityScore = null;
      _feedback = '';
      _testInputController.clear();

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

  Future<void> _startListening() async {
    if (!_speechAvailable) {
      _showError(
        'Speech recognition is not available. Please check permissions.',
      );
      return;
    }

    if (!_speech.isAvailable) {
      _showError(
        'Speech recognition initialization failed. Please restart the app.',
      );
      return;
    }

    setState(() {
      _isListening = true;
      _spokenText = '';
      _similarityScore = null;
      _feedback = '';
    });

    try {
      await _speech.listen(
        onResult: (result) {
          if (mounted) {
            setState(() {
              _spokenText = result.recognizedWords;

              // Only evaluate when speech is finalized
              if (result.finalResult) {
                _evaluateReading();
              }
            });
          }
        },
        localeId: 'en_US',
        listenFor: const Duration(seconds: 60),
        pauseFor: const Duration(seconds: 10),
        cancelOnError: false,
        listenMode: stt.ListenMode.confirmation,
        partialResults: true,
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isListening = false);
        _showError('Failed to start listening: $e');
      }
    }
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);

    if (_spokenText.isNotEmpty && !_hasAttempted) {
      _evaluateReading();
    } else if (_spokenText.isEmpty) {
      _showInfo('No speech detected. Please try again and speak clearly.');
    }
  }

  void _evaluateReading() {
    if (_currentSentence == null || _spokenText.isEmpty) return;

    final score = _evaluator.calculateSimilarity(
      _currentSentence!.text,
      _spokenText,
    );

    setState(() {
      _similarityScore = score;
      _feedback = _evaluator.getFeedback(score);
      _hasAttempted = true;
      _isListening = false;

      // Update tally on first attempt only
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

  void _showInfo(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 4),
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
    _speech.stop();
    _testInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reading Practice'),
        actions: [
          IconButton(
            icon: Icon(_testMode ? Icons.keyboard : Icons.mic),
            tooltip: _testMode
                ? 'Switch to Speech Mode'
                : 'Switch to Test Mode',
            onPressed: () {
              setState(() {
                _testMode = !_testMode;
                _spokenText = '';
                _similarityScore = null;
                _hasAttempted = false;
                _testInputController.clear();
              });
            },
          ),
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
            color: _testMode
                ? Theme.of(context).colorScheme.secondaryContainer
                : Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                _testMode
                    ? 'TEST MODE: Type what you would say, then press "Submit" to test the evaluation.'
                    : 'Read the sentence below aloud when you press the microphone button.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Sentence to read
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                _currentSentence?.text ?? '',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Microphone button OR Test input
          if (_testMode) ...[
            // Test mode: Text input
            TextField(
              controller: _testInputController,
              decoration: InputDecoration(
                labelText: 'Type your answer here',
                hintText: 'Enter the sentence as you would say it',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => _testInputController.clear(),
                ),
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _spokenText = _testInputController.text;
                  _hasAttempted = false;
                });
                if (_spokenText.isNotEmpty) {
                  _evaluateReading();
                } else {
                  _showInfo('Please type something to evaluate');
                }
              },
              icon: const Icon(Icons.check),
              label: const Text('Submit & Evaluate'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ] else ...[
            // Speech mode: Microphone button
            Center(
              child: Column(
                children: [
                  InkWell(
                    onTap: _speechInitializing || !_speechAvailable
                        ? null
                        : (_isListening ? _stopListening : _startListening),
                    borderRadius: BorderRadius.circular(50),
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: _speechInitializing
                            ? Colors.grey
                            : (!_speechAvailable
                                  ? Colors.grey.shade400
                                  : (_isListening ? Colors.red : Colors.blue)),
                        shape: BoxShape.circle,
                        boxShadow: [
                          if (_isListening)
                            BoxShadow(
                              color: Colors.red.withOpacity(0.5),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                        ],
                      ),
                      child: _speechInitializing
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Icon(
                              !_speechAvailable
                                  ? Icons.mic_off
                                  : (_isListening ? Icons.mic : Icons.mic_none),
                              size: 50,
                              color: Colors.white,
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _speechInitializing
                        ? 'Initializing...'
                        : (!_speechAvailable
                              ? 'Not available'
                              : (_isListening
                                    ? 'Listening...'
                                    : 'Tap to speak')),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),

          // Spoken text
          if (_spokenText.isNotEmpty) ...[
            Text('You said:', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _spokenText,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Results
          if (_similarityScore != null && _hasAttempted) ...[
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
                          _spokenText = '';
                          _similarityScore = null;
                          _feedback = '';
                          _testInputController.clear();
                          // Decrement incorrect counter when retrying
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

  void _showInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How to Practice'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('1. Read the sentence displayed on screen'),
              SizedBox(height: 8),
              Text('2. Press the microphone button'),
              SizedBox(height: 8),
              Text('3. Read the sentence aloud clearly'),
              SizedBox(height: 8),
              Text('4. The app will evaluate your pronunciation'),
              SizedBox(height: 8),
              Text('5. You need 80% or higher to pass'),
              SizedBox(height: 16),
              Text('Tips:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('• Speak clearly and at a normal pace'),
              SizedBox(height: 4),
              Text('• Read in a quiet environment'),
              SizedBox(height: 4),
              Text('• Small pronunciation mistakes are okay'),
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
}
