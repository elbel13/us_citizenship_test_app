import '../models/interview_question.dart';
import '../services/reading_evaluator.dart';

/// Service for generating LLM prompts for interview conversation flow
/// Keeps prompts concise (<50 tokens) for faster inference
class InterviewPromptService {
  /// Generate greeting prompt to start the interview
  String getGreetingPrompt() {
    return 'You are a USCIS officer conducting a citizenship interview. '
        'Greet the applicant professionally and warmly. Keep it brief (1-2 sentences).';
  }

  /// Generate prompt for asking a reading question
  String getReadingQuestionPrompt(String sentence) {
    return 'Ask the applicant to read this sentence aloud: "$sentence". '
        'Be professional and encouraging.';
  }

  /// Generate prompt for asking a writing question
  String getWritingQuestionPrompt(String sentence) {
    return 'Dictate this sentence to the applicant for them to write: "$sentence". '
        'Speak clearly and at a moderate pace.';
  }

  /// Generate prompt for asking a civics question
  String getCivicsQuestionPrompt(String question) {
    return 'Ask this citizenship question: "$question". '
        'Be professional and neutral.';
  }

  /// Generate response based on evaluation result
  String getResponsePrompt({
    required InterviewQuestionType questionType,
    required EvaluationResult result,
    required String question,
    required String userAnswer,
    required int attemptNumber,
  }) {
    final context = _getQuestionContext(questionType, question);

    switch (result) {
      case EvaluationResult.pass:
        return _getPassResponse(context, attemptNumber);
      case EvaluationResult.partial:
        return _getPartialResponse(context, userAnswer, attemptNumber);
      case EvaluationResult.fail:
        return _getFailResponse(context, attemptNumber);
    }
  }

  /// Generate section transition prompt
  String getSectionTransitionPrompt({
    required InterviewQuestionType fromSection,
    required InterviewQuestionType toSection,
  }) {
    final toSectionName = _getSectionName(toSection);
    return 'Briefly transition to the $toSectionName section. '
        'Keep it professional and brief (1 sentence).';
  }

  /// Generate completion prompt
  String getCompletionPrompt({
    required bool passed,
    required int civicsCorrect,
    required int civicsTotal,
  }) {
    if (passed) {
      return 'Thank the applicant and inform them they passed the test. '
          'They answered $civicsCorrect out of $civicsTotal civics questions correctly. '
          'Be warm and professional (2-3 sentences).';
    } else {
      return 'Thank the applicant professionally. Inform them they can retake the test. '
          'Be respectful and encouraging (2-3 sentences).';
    }
  }

  String _getQuestionContext(InterviewQuestionType type, String question) {
    switch (type) {
      case InterviewQuestionType.reading:
        return 'reading "$question"';
      case InterviewQuestionType.writing:
        return 'writing "$question"';
      case InterviewQuestionType.civics:
        return 'the question "$question"';
    }
  }

  String _getPassResponse(String context, int attemptNumber) {
    if (attemptNumber == 1) {
      return 'The applicant answered correctly on first try for $context. '
          'Acknowledge positively and briefly. Then say "Next question." (1-2 sentences)';
    } else {
      return 'The applicant answered correctly for $context after $attemptNumber attempts. '
          'Acknowledge and move on. Say "Next question." (1-2 sentences)';
    }
  }

  String _getPartialResponse(
    String context,
    String userAnswer,
    int attemptNumber,
  ) {
    if (attemptNumber >= 3) {
      return 'The applicant\'s answer "$userAnswer" for $context was partially correct '
          'after $attemptNumber attempts. Move on professionally. Say "Next question." (1-2 sentences)';
    } else {
      return 'The applicant\'s answer "$userAnswer" for $context needs more detail. '
          'Ask them to clarify or elaborate. Be encouraging (1-2 sentences).';
    }
  }

  String _getFailResponse(String context, int attemptNumber) {
    if (attemptNumber >= 3) {
      return 'The applicant did not answer correctly for $context after $attemptNumber attempts. '
          'Move on professionally without revealing the correct answer. Say "Next question." (1-2 sentences)';
    } else {
      return 'The applicant\'s answer for $context was not quite right. '
          'Encourage them to try again. Rephrase the question if helpful (1-2 sentences).';
    }
  }

  String _getSectionName(InterviewQuestionType type) {
    switch (type) {
      case InterviewQuestionType.reading:
        return 'reading test';
      case InterviewQuestionType.writing:
        return 'writing test';
      case InterviewQuestionType.civics:
        return 'civics test';
    }
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
