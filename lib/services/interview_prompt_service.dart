import 'dart:math';
import '../models/interview_question.dart';
import '../services/reading_evaluator.dart';

/// Service for generating interview conversation prompts
///
/// Currently uses pre-written professional variations for instant, reliable responses.
/// LLM integration (DistilGPT-2) attempted but proved unsuitable:
/// - Model too small (82M params) for instruction-following
/// - Poor output quality (repetitive, nonsensical)
/// - Unacceptable latency (60-90 seconds per response)
///
/// Future enhancement: Replace with larger instruction-tuned model (Gemma 2B, Phi-2)
/// or cloud API (Gemini Flash) for natural conversation variety.
class InterviewPromptService {
  final _random = Random();

  /// Generate greeting to start the interview
  String getGreetingPrompt() {
    final greetings = [
      'Good morning. Welcome to your citizenship interview.',
      'Hello. Thank you for coming today.',
      'Good afternoon. Please have a seat and we can begin.',
      'Welcome. Let\'s get started with your interview.',
    ];
    return greetings[_random.nextInt(greetings.length)];
  }

  /// Generate prompt for asking a reading question
  String getReadingQuestionPrompt(String sentence) {
    final prompts = [
      'Please read this sentence aloud for me.',
      'Can you read this sentence?',
      'I\'d like you to read this sentence.',
    ];
    return prompts[_random.nextInt(prompts.length)];
  }

  /// Generate prompt for asking a writing question
  String getWritingQuestionPrompt(String sentence) {
    final prompts = [
      'Please write this sentence: $sentence',
      'I\'ll dictate a sentence for you to write: $sentence',
      'Please write down: $sentence',
    ];
    return prompts[_random.nextInt(prompts.length)];
  }

  /// Generate prompt for asking a civics question
  String getCivicsQuestionPrompt(String question) {
    // Randomly decide whether to add a prefix
    if (_random.nextBool()) {
      return question;
    }
    final prefixes = ['', 'Tell me, ', 'Can you tell me, '];
    return prefixes[_random.nextInt(prefixes.length)] + question;
  }

  /// Generate response based on evaluation result
  String getResponsePrompt({
    required InterviewQuestionType questionType,
    required EvaluationResult result,
    required String question,
    required String userAnswer,
    required int attemptNumber,
  }) {
    switch (result) {
      case EvaluationResult.pass:
        final responses = [
          'That is correct.',
          'Good.',
          'Very good.',
          'Correct.',
        ];
        return responses[_random.nextInt(responses.length)];
      case EvaluationResult.partial:
        if (attemptNumber >= 3) {
          final moveOn = ['Let\'s move on.', 'Okay, next question.'];
          return moveOn[_random.nextInt(moveOn.length)];
        }
        final clarify = [
          'Can you tell me more?',
          'Can you elaborate on that?',
          'Could you give me more details?',
        ];
        return clarify[_random.nextInt(clarify.length)];
      case EvaluationResult.fail:
        if (attemptNumber >= 3) {
          final moveOn = ['Next question.', 'Let\'s continue.'];
          return moveOn[_random.nextInt(moveOn.length)];
        }
        final retry = ['Let me ask again.', 'I\'ll repeat the question.'];
        return retry[_random.nextInt(retry.length)];
    }
  }

  /// Generate section transition prompt
  String getSectionTransitionPrompt({
    required InterviewQuestionType fromSection,
    required InterviewQuestionType toSection,
  }) {
    switch (toSection) {
      case InterviewQuestionType.reading:
        final transitions = [
          'Now we\'ll do the reading test.',
          'Let\'s move on to the reading portion.',
        ];
        return transitions[_random.nextInt(transitions.length)];
      case InterviewQuestionType.writing:
        final transitions = [
          'Next is the writing test.',
          'Now for the writing portion.',
        ];
        return transitions[_random.nextInt(transitions.length)];
      case InterviewQuestionType.civics:
        final transitions = [
          'Now for the civics questions.',
          'Let\'s begin the civics test.',
        ];
        return transitions[_random.nextInt(transitions.length)];
    }
  }

  /// Generate completion prompt
  String getCompletionPrompt({
    required bool passed,
    required int civicsCorrect,
    required int civicsTotal,
  }) {
    if (passed) {
      final messages = [
        'Congratulations! You have passed the test.',
        'Well done. You passed.',
        'You have successfully completed the test.',
      ];
      return messages[_random.nextInt(messages.length)];
    }
    final messages = [
      'Thank you for coming today. We\'ll be in touch.',
      'Thank you. You\'ll hear from us soon.',
    ];
    return messages[_random.nextInt(messages.length)];
  }

  /// Clean up LLM response (remove quotes, extra whitespace)
  String cleanResponse(String response) {
    var cleaned = response.trim();

    // Remove leading/trailing quotes
    if ((cleaned.startsWith('"') && cleaned.endsWith('"')) ||
        (cleaned.startsWith("'") && cleaned.endsWith("'"))) {
      cleaned = cleaned.substring(1, cleaned.length - 1);
    }

    // Normalize whitespace
    return cleaned.replaceAll(RegExp(r'\s+'), ' ');
  }
}
