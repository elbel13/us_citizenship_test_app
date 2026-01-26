import 'dart:convert';
import '../models/writing_sentence.dart';
import 'database_service.dart';

/// Service for loading and managing writing practice sentences
class WritingSentenceService {
  final DatabaseService _dbService = DatabaseService();

  /// Get all sentences shuffled
  Future<List<WritingSentence>> getAllSentences() async {
    final maps = await _dbService.getAllWritingSentences();
    return maps.map((map) => _mapToSentence(map)).toList();
  }

  /// Get sentences by category
  Future<List<WritingSentence>> getSentencesByCategory(String category) async {
    final maps = await _dbService.getWritingSentencesByCategory(category);
    return maps.map((map) => _mapToSentence(map)).toList();
  }

  /// Get sentences by difficulty level
  Future<List<WritingSentence>> getSentencesByDifficulty(int difficulty) async {
    final maps = await _dbService.getWritingSentencesByDifficulty(difficulty);
    return maps.map((map) => _mapToSentence(map)).toList();
  }

  /// Get sentence by ID
  Future<WritingSentence?> getSentenceById(String id) async {
    final map = await _dbService.getWritingSentenceById(id);
    return map != null ? _mapToSentence(map) : null;
  }

  /// Get all available categories
  Future<List<String>> getCategories() async {
    final sentences = await getAllSentences();
    return sentences.map((s) => s.category).toSet().toList()..sort();
  }

  /// Get count of sentences
  Future<int> getSentenceCount() async {
    return await _dbService.getWritingSentenceCount();
  }

  /// Convert database map to WritingSentence model
  WritingSentence _mapToSentence(Map<String, dynamic> map) {
    return WritingSentence(
      id: map['id'] as String,
      text: map['text'] as String,
      vocabularyWords: (json.decode(map['vocabulary_words'] as String) as List)
          .map((e) => e as String)
          .toList(),
      category: map['category'] as String,
      difficulty: map['difficulty'] as int,
    );
  }
}
