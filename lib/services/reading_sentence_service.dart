import 'dart:convert';
import 'dart:math';
import '../models/reading_sentence.dart';
import 'database_service.dart';

/// Service for loading and managing reading practice sentences
class ReadingSentenceService {
  final DatabaseService _dbService = DatabaseService();
  final Random _random = Random();

  /// Get all sentences
  Future<List<ReadingSentence>> getAllSentences() async {
    final maps = await _dbService.getAllReadingSentences();
    return maps.map((map) => _mapToSentence(map)).toList();
  }

  /// Get a random sentence
  Future<ReadingSentence> getRandomSentence() async {
    final maps = await _dbService.getAllReadingSentences();
    if (maps.isEmpty) {
      throw Exception('No sentences available');
    }
    return _mapToSentence(maps[_random.nextInt(maps.length)]);
  }

  /// Get sentences by category
  Future<List<ReadingSentence>> getSentencesByCategory(String category) async {
    final maps = await _dbService.getReadingSentencesByCategory(category);
    return maps.map((map) => _mapToSentence(map)).toList();
  }

  /// Get sentences by difficulty level
  Future<List<ReadingSentence>> getSentencesByDifficulty(int difficulty) async {
    final maps = await _dbService.getReadingSentencesByDifficulty(difficulty);
    return maps.map((map) => _mapToSentence(map)).toList();
  }

  /// Get a random sentence from a specific category
  Future<ReadingSentence?> getRandomSentenceFromCategory(
    String category,
  ) async {
    final sentences = await getSentencesByCategory(category);
    if (sentences.isEmpty) return null;
    return sentences[_random.nextInt(sentences.length)];
  }

  /// Get a set of random sentences for practice
  Future<List<ReadingSentence>> getRandomSentences(int count) async {
    final maps = await _dbService.getAllReadingSentences();
    if (maps.isEmpty) {
      throw Exception('No sentences available');
    }

    final sentences = maps.map((map) => _mapToSentence(map)).toList()
      ..shuffle(_random);
    return sentences.take(count).toList();
  }

  /// Get sentence by ID
  Future<ReadingSentence?> getSentenceById(String id) async {
    final map = await _dbService.getReadingSentenceById(id);
    return map != null ? _mapToSentence(map) : null;
  }

  /// Get all available categories
  Future<List<String>> getCategories() async {
    final sentences = await getAllSentences();
    return sentences.map((s) => s.category).toSet().toList()..sort();
  }

  /// Get count of sentences
  Future<int> getSentenceCount() async {
    return await _dbService.getReadingSentenceCount();
  }

  /// Convert database map to ReadingSentence model
  ReadingSentence _mapToSentence(Map<String, dynamic> map) {
    return ReadingSentence(
      id: map['id'] as String,
      text: map['text'] as String,
      vocabularyWords: (json.decode(map['vocabulary_words']) as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      category: map['category'] as String,
      difficulty: map['difficulty'] as int,
    );
  }
}
