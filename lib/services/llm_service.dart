import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'gpt2_tokenizer.dart';

/// Service for loading and running the DistilGPT-2 TFLite model.
class LlmService {
  Interpreter? _interpreter;
  final GPT2Tokenizer _tokenizer = GPT2Tokenizer();
  bool _isInitialized = false;

  /// Whether the model has been loaded and is ready for inference
  bool get isInitialized => _isInitialized;

  /// Initialize the LLM model
  /// Loads the TFLite model and tokenizer from assets
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('LLM already initialized');
      return;
    }

    try {
      debugPrint('Loading LLM model and tokenizer...');
      final stopwatch = Stopwatch()..start();

      // Load tokenizer first
      await _tokenizer.initialize();
      debugPrint('Tokenizer loaded');

      // Load the TFLite model (builtins-only version for better mobile compatibility)
      _interpreter = await Interpreter.fromAsset(
        'assets/models/distilgpt2_builtins_only.tflite',
        options: InterpreterOptions()
          ..threads =
              4 // Use multiple threads for better performance
          // Don't use NNAPI - it doesn't support dynamic-sized tensors
          ..useNnApiForAndroid = false,
      );

      stopwatch.stop();
      debugPrint('LLM model loaded in ${stopwatch.elapsedMilliseconds}ms');

      // Get model input/output details
      final inputTensors = _interpreter!.getInputTensors();
      final outputTensors = _interpreter!.getOutputTensors();

      debugPrint('Input tensors: ${inputTensors.length}');
      for (var i = 0; i < inputTensors.length; i++) {
        debugPrint(
          '  Input $i: ${inputTensors[i].shape} ${inputTensors[i].type}',
        );
      }

      debugPrint('Output tensors: ${outputTensors.length}');
      for (var i = 0; i < outputTensors.length; i++) {
        debugPrint(
          '  Output $i: ${outputTensors[i].shape} ${outputTensors[i].type}',
        );
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('Error loading LLM model: $e');
      rethrow;
    }
  }

  /// Generate text from a prompt
  ///
  /// Uses GPT-2 tokenization and the TFLite model to generate text.
  /// Parameters:
  /// - [prompt]: The input text to continue
  /// - [maxTokens]: Maximum number of tokens to generate (default: 20)
  /// - [minTokens]: Minimum number of new tokens required (default: 5)
  /// - [temperature]: Controls randomness (0.0 = deterministic, 1.0 = creative)
  Future<String> generate(
    String prompt, {
    int maxTokens = 20,
    int minTokens = 5,
    double temperature = 0.7,
  }) async {
    if (!_isInitialized) {
      throw StateError('LLM not initialized. Call initialize() first.');
    }

    try {
      final stopwatch = Stopwatch()..start();

      // Tokenize input
      final inputTokens = _tokenizer.encode(prompt);
      debugPrint('Input: "$prompt"');
      debugPrint('Tokens (${inputTokens.length}): $inputTokens');

      // Generate tokens one at a time
      final generatedTokens = List<int>.from(inputTokens);

      for (var i = 0; i < maxTokens; i++) {
        // Prepare input tensor (batch_size=1, sequence_length=current length)
        final inputShape = [1, generatedTokens.length];
        final input = Int32List.fromList(generatedTokens);
        final inputTensor = input.reshape(inputShape);

        // Prepare output tensor (batch_size=1, sequence_length=current, vocab_size=50257)
        final outputShape = [1, generatedTokens.length, 50257];
        final output = List.filled(
          outputShape[0] * outputShape[1] * outputShape[2],
          0.0,
        ).reshape(outputShape);

        // Run inference
        _interpreter!.run(inputTensor, output);

        // Get logits for the last token
        final lastTokenLogits =
            (output)[0][generatedTokens.length - 1] as List;

        // Apply temperature scaling
        final scaledLogits = lastTokenLogits
            .map((logit) => (logit as double) / temperature)
            .toList();

        // Simple greedy decoding (take highest probability token)
        // TODO: Implement top-k, top-p sampling for better quality
        var maxIndex = 0;
        var maxValue = scaledLogits[0];
        for (var j = 1; j < scaledLogits.length; j++) {
          if (scaledLogits[j] > maxValue) {
            maxValue = scaledLogits[j];
            maxIndex = j;
          }
        }

        // Add generated token
        generatedTokens.add(maxIndex);

        // Stop if we hit end-of-text token (50256)
        if (maxIndex == 50256) {
          break;
        }
      }

      // Decode generated tokens
      final generatedText = _tokenizer.decode(generatedTokens);

      // Extract only the newly generated text (remove the prompt)
      final promptLength = prompt.length;
      var newText = generatedText.length > promptLength
          ? generatedText.substring(promptLength).trim()
          : generatedText;

      debugPrint('Full output: "$generatedText"');
      debugPrint('New text only: "$newText"');

      // Check minimum token requirement
      final newTokens = generatedTokens.length - inputTokens.length;
      if (newTokens < minTokens) {
        debugPrint(
          'Warning: Only generated $newTokens tokens (min: $minTokens)',
        );
        // Return what we have - alternatively could retry or use fallback
      }

      stopwatch.stop();
      debugPrint(
        'Generated $newTokens tokens '
        'in ${stopwatch.elapsedMilliseconds}ms',
      );

      return newText;
    } catch (e) {
      debugPrint('Error during inference: $e');
      rethrow;
    }
  }

  /// Dispose of resources
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _tokenizer.clearCache();
    _isInitialized = false;
    debugPrint('LLM service disposed');
  }
}

// Extension to reshape lists for TFLite
extension ListReshape<T> on List<T> {
  List reshape(List<int> shape) {
    if (shape.isEmpty) return this;

    if (shape.length == 1) {
      if (shape[0] != length) {
        throw ArgumentError('Cannot reshape list of length $length to $shape');
      }
      return this;
    }

    final totalSize = shape.reduce((a, b) => a * b);
    if (totalSize != length) {
      throw ArgumentError('Cannot reshape list of length $length to $shape');
    }

    dynamic reshapeRecursive(List data, List<int> dims, int offset) {
      if (dims.length == 1) {
        return data.sublist(offset, offset + dims[0]);
      }

      final result = [];
      final blockSize = dims.skip(1).reduce((a, b) => a * b);

      for (var i = 0; i < dims[0]; i++) {
        result.add(
          reshapeRecursive(data, dims.sublist(1), offset + i * blockSize),
        );
      }

      return result;
    }

    return reshapeRecursive(this, shape, 0);
  }
}
