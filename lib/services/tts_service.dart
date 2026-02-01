import 'package:flutter_tts/flutter_tts.dart';

/// Shared Text-to-Speech service for consistent voice configuration
/// across the app (writing practice, simulated interview, etc.)
class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _isSpeaking = false;

  /// Callback when speaking starts
  Function()? onSpeakStart;

  /// Callback when speaking completes
  Function()? onSpeakComplete;

  /// Callback when an error occurs
  Function(String message)? onError;

  /// Initialize TTS with default settings
  Future<void> initialize({
    String language = 'en-US',
    double speechRate = 0.5,
    double pitch = 1.0,
  }) async {
    await _tts.setLanguage(language);
    await _tts.setSpeechRate(speechRate);
    await _tts.setPitch(pitch);

    _tts.setStartHandler(() {
      _isSpeaking = true;
      onSpeakStart?.call();
    });

    _tts.setCompletionHandler(() {
      _isSpeaking = false;
      onSpeakComplete?.call();
    });

    _tts.setErrorHandler((msg) {
      _isSpeaking = false;
      onError?.call('Speech error: $msg');
    });
  }

  /// Speak the given text
  Future<void> speak(String text) async {
    if (_isSpeaking) {
      await stop();
    }
    await _tts.speak(text);
  }

  /// Stop current speech
  Future<void> stop() async {
    await _tts.stop();
    _isSpeaking = false;
  }

  /// Check if currently speaking
  bool get isSpeaking => _isSpeaking;

  /// Set speech rate (0.0 to 1.0, default 0.5)
  Future<void> setSpeechRate(double rate) async {
    await _tts.setSpeechRate(rate);
  }

  /// Set pitch (0.5 to 2.0, default 1.0)
  Future<void> setPitch(double pitch) async {
    await _tts.setPitch(pitch);
  }

  /// Set language
  Future<void> setLanguage(String language) async {
    await _tts.setLanguage(language);
  }

  /// Dispose of TTS resources
  void dispose() {
    _tts.stop();
  }
}
