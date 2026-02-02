import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/question.dart';
import '../models/answer.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;
  static String? _customDatabasePath; // For testing purposes

  // Category name to ID mapping
  static const Map<String, int> categoryIds = {
    'DOCUMENT': 1,
    'FOUNDING_FATHER': 2,
    'PRESIDENT': 3,
    'HISTORICAL_FIGURE': 4,
    'GOVERNMENT_OFFICIAL': 5,
    'NUMBER': 6,
    'DATE': 7,
    'WAR': 8,
    'GOVERNMENT_BRANCH': 9,
    'GOVERNMENT_ACTION': 10,
    'RIGHTS': 11,
    'CIVIC_DUTY': 12,
    'POLITICAL_CONCEPT': 13,
    'PLACE': 14,
    'NATIVE_TRIBE': 15,
    'EVENT': 16,
    'INNOVATION': 17,
    'NATIONAL_SYMBOL': 18,
  };

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    print('DatabaseService: Starting database initialization...');
    String path =
        _customDatabasePath ??
        join(await getDatabasesPath(), 'citizenship_test.db');
    return await openDatabase(
      path,
      version: 5, // Bumped for writing sentences
      onCreate: _createDatabase,
      onUpgrade: (db, oldVersion, newVersion) async {
        // For now, just drop and recreate (no user data to preserve)
        if (oldVersion < 5) {
          await db.execute('DROP TABLE IF EXISTS answer');
          await db.execute('DROP TABLE IF EXISTS question_text');
          await db.execute('DROP TABLE IF EXISTS question');
          await db.execute('DROP TABLE IF EXISTS answer_category');
          await db.execute('DROP TABLE IF EXISTS reading_sentence');
          await _createDatabase(db, newVersion);
        }
      },
      onOpen: (db) async {
        // Check if we need to populate the database
        await _populateIfEmpty(db);
      },
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    // Create answer_category table
    await db.execute('''
      CREATE TABLE answer_category (
        id INTEGER PRIMARY KEY,
        category_name TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_answer_category_name 
      ON answer_category(category_name)
    ''');

    await db.execute('''
      CREATE TABLE question (
        id INTEGER PRIMARY KEY
      )
    ''');

    await db.execute('''
      CREATE TABLE question_text (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        question_id INTEGER NOT NULL,
        language_code TEXT NOT NULL,
        question_text TEXT NOT NULL,
        FOREIGN KEY (question_id) REFERENCES question(id)
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_question_text_language 
      ON question_text(language_code)
    ''');

    await db.execute('''
      CREATE INDEX idx_question_text_question 
      ON question_text(question_id)
    ''');

    // Create answer table
    await db.execute('''
      CREATE TABLE answer (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        question_text_id INTEGER NOT NULL,
        answer_text TEXT NOT NULL,
        category_id INTEGER NOT NULL,
        FOREIGN KEY (question_text_id) REFERENCES question_text(id),
        FOREIGN KEY (category_id) REFERENCES answer_category(id)
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_answer_question_text 
      ON answer(question_text_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_answer_category 
      ON answer(category_id)
    ''');

    // Create reading_sentence table
    await db.execute('''
      CREATE TABLE reading_sentence (
        id TEXT PRIMARY KEY,
        text TEXT NOT NULL,
        vocabulary_words TEXT NOT NULL,
        category TEXT NOT NULL,
        difficulty INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_reading_sentence_category 
      ON reading_sentence(category)
    ''');

    await db.execute('''
      CREATE INDEX idx_reading_sentence_difficulty 
      ON reading_sentence(difficulty)
    ''');

    // Create writing_sentence table
    await db.execute('''
      CREATE TABLE writing_sentence (
        id TEXT PRIMARY KEY,
        text TEXT NOT NULL,
        vocabulary_words TEXT NOT NULL,
        category TEXT NOT NULL,
        difficulty INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_writing_sentence_category 
      ON writing_sentence(category)
    ''');

    await db.execute('''
      CREATE INDEX idx_writing_sentence_difficulty 
      ON writing_sentence(difficulty)
    ''');

    // Populate categories
    Batch batch = db.batch();
    categoryIds.forEach((name, id) {
      batch.insert('answer_category', {'id': id, 'category_name': name});
    });
    await batch.commit(noResult: true);
  }

  Future<void> _populateIfEmpty(Database db) async {
    print('DatabaseService: Checking if population needed...');
    // Check if database is already populated
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM question'),
    );

    if (count == null || count == 0) {
      print(
        'DatabaseService: Database empty, will be populated after onboarding.',
      );
      // Database is empty - will be populated after onboarding completes
      // with the user's selected question year
    } else {
      print('DatabaseService: Questions already loaded ($count questions).');
    }

    // Check if reading sentences are populated
    final sentenceCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM reading_sentence'),
    );

    if (sentenceCount == null || sentenceCount == 0) {
      print('DatabaseService: Loading reading sentences...');
      await _loadReadingSentencesFromAssets(db);
      print('DatabaseService: Reading sentences loaded.');
    } else {
      print(
        'DatabaseService: Reading sentences already loaded ($sentenceCount sentences).',
      );
    }

    // Check if writing sentences are populated
    print('DatabaseService: Checking writing sentences...');
    final writingSentenceCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM writing_sentence'),
    );

    if (writingSentenceCount == null || writingSentenceCount == 0) {
      print('DatabaseService: Loading writing sentences...');
      await _loadWritingSentencesFromAssets(db);
      print('DatabaseService: Writing sentences loaded.');
    } else {
      print(
        'DatabaseService: Writing sentences already loaded ($writingSentenceCount sentences).',
      );
    }

    print('DatabaseService: Database initialization complete!');
  }

  Future<void> _loadQuestionsFromAssets(
    Database db,
    String languageCode, {
    String? assetPath,
  }) async {
    try {
      // Use provided asset path or default
      final path =
          assetPath ?? 'assets/questions_${languageCode}_categorized.json';

      // Load the categorized JSON file from assets
      final String jsonString = await rootBundle.loadString(path);
      final List<dynamic> jsonData = json.decode(jsonString);

      // Use a batch for better performance
      Batch batch = db.batch();

      for (var item in jsonData) {
        int questionId = item['id'];
        String questionText = item['question'];
        List<dynamic> answers = item['answers'];

        // Insert into question table
        batch.insert('question', {
          'id': questionId,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);

        // Insert into question_text table and get the ID
        // We need to use rawInsert to get the last inserted ID
        await batch.commit(noResult: true);

        // Insert question_text and get its ID
        int questionTextId = await db.insert('question_text', {
          'question_id': questionId,
          'language_code': languageCode,
          'question_text': questionText,
        }, conflictAlgorithm: ConflictAlgorithm.replace);

        // Insert answers
        batch = db.batch();
        for (var answer in answers) {
          String answerText = answer['text'];
          String category = answer['category'];
          int categoryId =
              categoryIds[category] ?? 13; // Default to POLITICAL_CONCEPT

          batch.insert('answer', {
            'question_text_id': questionTextId,
            'answer_text': answerText,
            'category_id': categoryId,
          });
        }
      }

      await batch.commit(noResult: true);
    } catch (e) {
      print('Error loading questions from assets: $e');
      rethrow;
    }
  }

  Future<void> _loadReadingSentencesFromAssets(Database db) async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/reading_sentences.json',
      );
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      final List<dynamic> sentences = jsonData['sentences'];

      Batch batch = db.batch();

      for (var sentence in sentences) {
        batch.insert('reading_sentence', {
          'id': sentence['id'],
          'text': sentence['text'],
          'vocabulary_words': json.encode(sentence['vocabularyWords']),
          'category': sentence['category'],
          'difficulty': sentence['difficulty'],
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      await batch.commit(noResult: true);
    } catch (e) {
      print('Error loading reading sentences from assets: $e');
      rethrow;
    }
  }

  Future<List<Question>> getQuestions(String languageCode) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'question_text',
      where: 'language_code = ?',
      whereArgs: [languageCode],
      orderBy: 'question_id',
    );

    // Convert to Question objects with answers
    List<Question> questions = [];
    for (var qtMap in maps) {
      int questionTextId = qtMap['id'];

      // Get all answers for this question_text
      final List<Map<String, dynamic>> answerMaps = await db.query(
        'answer',
        where: 'question_text_id = ?',
        whereArgs: [questionTextId],
      );

      // Convert answer maps to Answer objects
      List<Answer> answers = answerMaps
          .map((map) => Answer.fromMap(map))
          .toList();

      // Create question with answers
      questions.add(Question.fromMap(qtMap, answers: answers));
    }

    return questions;
  }

  /// Get random wrong answers from specified categories, excluding the current question
  Future<List<String>> getWrongAnswersByCategories(
    int questionId,
    List<int> categoryIds,
    int count,
  ) async {
    final db = await database;

    // Build the WHERE clause for categories
    final categoryPlaceholders = categoryIds.map((_) => '?').join(',');

    final List<Map<String, dynamic>> answerMaps = await db.rawQuery(
      '''
      SELECT DISTINCT a.answer_text
      FROM answer a
      JOIN question_text qt ON a.question_text_id = qt.id
      WHERE qt.question_id != ?
        AND a.category_id IN ($categoryPlaceholders)
      ORDER BY RANDOM()
      LIMIT ?
    ''',
      [questionId, ...categoryIds, count],
    );

    return answerMaps.map((map) => map['answer_text'] as String).toList();
  }

  Future<void> clearDatabase() async {
    final db = await database;
    // Delete in correct order respecting foreign key constraints
    await db.delete('answer');
    await db.delete('question_text');
    await db.delete('question');
    await db.delete('reading_sentence');
    // Note: We don't delete answer_category as those are constant
  }

  // Reading sentence methods
  Future<List<Map<String, dynamic>>> getAllReadingSentences() async {
    final db = await database;
    return await db.query('reading_sentence', orderBy: 'id');
  }

  Future<List<Map<String, dynamic>>> getReadingSentencesByCategory(
    String category,
  ) async {
    final db = await database;
    return await db.query(
      'reading_sentence',
      where: 'category = ?',
      whereArgs: [category],
    );
  }

  Future<List<Map<String, dynamic>>> getReadingSentencesByDifficulty(
    int difficulty,
  ) async {
    final db = await database;
    return await db.query(
      'reading_sentence',
      where: 'difficulty = ?',
      whereArgs: [difficulty],
    );
  }

  Future<Map<String, dynamic>?> getReadingSentenceById(String id) async {
    final db = await database;
    final results = await db.query(
      'reading_sentence',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> getReadingSentenceCount() async {
    final db = await database;
    return Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM reading_sentence'),
        ) ??
        0;
  }

  Future<void> _loadWritingSentencesFromAssets(Database db) async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/writing_sentences.json',
      );
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      final List<dynamic> sentences = jsonData['sentences'];

      Batch batch = db.batch();

      for (var sentence in sentences) {
        batch.insert('writing_sentence', {
          'id': sentence['id'],
          'text': sentence['text'],
          'vocabulary_words': json.encode(sentence['vocabularyWords']),
          'category': sentence['category'],
          'difficulty': sentence['difficulty'],
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      await batch.commit(noResult: true);
    } catch (e) {
      print('Error loading writing sentences from assets: $e');
      rethrow;
    }
  }

  // Writing sentence methods
  Future<List<Map<String, dynamic>>> getAllWritingSentences() async {
    final db = await database;
    return await db.query('writing_sentence', orderBy: 'id');
  }

  Future<List<Map<String, dynamic>>> getWritingSentencesByCategory(
    String category,
  ) async {
    final db = await database;
    return await db.query(
      'writing_sentence',
      where: 'category = ?',
      whereArgs: [category],
    );
  }

  Future<List<Map<String, dynamic>>> getWritingSentencesByDifficulty(
    int difficulty,
  ) async {
    final db = await database;
    return await db.query(
      'writing_sentence',
      where: 'difficulty = ?',
      whereArgs: [difficulty],
    );
  }

  Future<Map<String, dynamic>?> getWritingSentenceById(String id) async {
    final db = await database;
    final results = await db.query(
      'writing_sentence',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> getWritingSentenceCount() async {
    final db = await database;
    return Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM writing_sentence'),
        ) ??
        0;
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  /// Set a custom database path for testing purposes.
  /// Call this before accessing the database to use a different file.
  static void setCustomDatabasePath(String? path) {
    _customDatabasePath = path;
    _database = null; // Force re-initialization with new path
  }

  /// Get available question years based on asset files
  /// Checks for specific test versions that have been released
  /// Test versions are published periodically (not annually): 2020, 2025, etc.
  Future<List<String>> getAvailableQuestionYears() async {
    final List<String> years = [];

    // Check for known test versions
    // Note: These are specific test editions, not annual releases
    final knownVersions = ['2025', '2020'];

    for (final year in knownVersions) {
      try {
        String assetPath;
        if (year == '2020') {
          // 2020 version uses the default file name
          assetPath = 'assets/questions_en_categorized.json';
        } else {
          assetPath = 'assets/questions_en_categorized_$year.json';
        }
        await rootBundle.loadString(assetPath);
        years.add(year);
      } catch (e) {
        // File doesn't exist - version not bundled yet
      }
    }

    // Sort in descending order (latest first)
    years.sort((a, b) => b.compareTo(a));

    return years;
  }

  /// Load questions for a specific year
  /// This should be called after onboarding when the user selects their question year
  Future<void> loadQuestionsForYear(String year, String languageCode) async {
    final db = await database;

    // Clear existing questions
    await db.delete('answer');
    await db.delete('question_text');
    await db.delete('question');

    print('DatabaseService: Loading questions for year $year...');

    // Determine the asset file name
    String assetPath;
    if (year == '2020') {
      assetPath = 'assets/questions_${languageCode}_categorized.json';
    } else {
      assetPath = 'assets/questions_${languageCode}_categorized_$year.json';
    }

    await _loadQuestionsFromAssets(db, languageCode, assetPath: assetPath);
    print('DatabaseService: Questions for year $year loaded successfully.');
  }

  /// Update location-specific answers in the database
  /// This replaces placeholder answers with actual government official names
  Future<void> updateLocationSpecificAnswers({
    required String governor,
    required String senator1,
    required String senator2,
    required String representative,
    required String state,
  }) async {
    final db = await database;

    print('DatabaseService: Updating location-specific answers for $state...');

    // Find questions that need location-specific answers
    // These are typically questions with GOVERNMENT_OFFICIAL category
    // that have placeholder text like "Your state's governor", etc.

    // For now, we'll update specific question IDs that are known to need this
    // In a real implementation, you might want to mark these questions differently

    // Example: Update governor question (you'll need to identify the actual question IDs)
    // This is a placeholder implementation - actual IDs would come from your question set

    final questionTexts = await db.query('question_text');

    for (var qt in questionTexts) {
      final questionText = qt['question_text'] as String;
      final questionTextId = qt['id'] as int;

      // Check if this is a location-specific question and update accordingly
      if (questionText.toLowerCase().contains('governor')) {
        // Update or add the governor answer
        await _upsertLocationAnswer(
          db,
          questionTextId,
          governor,
          DatabaseService.categoryIds['GOVERNMENT_OFFICIAL']!,
        );
      } else if (questionText.toLowerCase().contains('senator')) {
        // Update senator answers
        await _upsertLocationAnswer(
          db,
          questionTextId,
          senator1,
          DatabaseService.categoryIds['GOVERNMENT_OFFICIAL']!,
        );
        await _upsertLocationAnswer(
          db,
          questionTextId,
          senator2,
          DatabaseService.categoryIds['GOVERNMENT_OFFICIAL']!,
        );
      } else if (questionText.toLowerCase().contains('representative')) {
        // Update representative answer
        await _upsertLocationAnswer(
          db,
          questionTextId,
          representative,
          DatabaseService.categoryIds['GOVERNMENT_OFFICIAL']!,
        );
      }
    }

    print('DatabaseService: Location-specific answers updated.');
  }

  /// Helper to upsert location-specific answer
  Future<void> _upsertLocationAnswer(
    Database db,
    int questionTextId,
    String answerText,
    int categoryId,
  ) async {
    // Check if an answer with this category already exists
    final existing = await db.query(
      'answer',
      where: 'question_text_id = ? AND category_id = ?',
      whereArgs: [questionTextId, categoryId],
    );

    if (existing.isEmpty) {
      // Insert new answer
      await db.insert('answer', {
        'question_text_id': questionTextId,
        'answer_text': answerText,
        'category_id': categoryId,
      });
    } else {
      // Update existing answer
      await db.update(
        'answer',
        {'answer_text': answerText},
        where: 'question_text_id = ? AND category_id = ?',
        whereArgs: [questionTextId, categoryId],
      );
    }
  }
}
