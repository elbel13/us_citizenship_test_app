import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/question.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'citizenship_test.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
      onOpen: (db) async {
        // Check if we need to populate the database
        await _populateIfEmpty(db);
      },
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE question (
        id INTEGER PRIMARY KEY
      )
    ''');

    await db.execute('''
      CREATE TABLE question_text (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        question_id INTEGER,
        language_code TEXT,
        question_text TEXT,
        answer_text TEXT,
        FOREIGN KEY (question_id) REFERENCES question(id)
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_question_text_language 
      ON question_text(language_code)
    ''');
  }

  Future<void> _populateIfEmpty(Database db) async {
    // Check if database is already populated
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM question'),
    );

    if (count == null || count == 0) {
      // Database is empty, populate it
      await _loadQuestionsFromAssets(db, 'en');
    }
  }

  Future<void> _loadQuestionsFromAssets(
    Database db,
    String languageCode,
  ) async {
    try {
      // Load the JSON file from assets
      final String jsonString = await rootBundle.loadString(
        'assets/questions_$languageCode.json',
      );
      final List<dynamic> jsonData = json.decode(jsonString);

      // Use a batch for better performance
      Batch batch = db.batch();

      for (var item in jsonData) {
        int questionId = item['id'];

        // Insert into question table
        batch.insert('question', {
          'id': questionId,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);

        // Insert into question_text table
        batch.insert('question_text', {
          'question_id': questionId,
          'language_code': languageCode,
          'question_text': item['question'],
          'answer_text': item['answer'],
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }

      await batch.commit(noResult: true);
    } catch (e) {
      print('Error loading questions from assets: $e');
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

    return List.generate(maps.length, (i) {
      return Question(
        id: maps[i]['question_id'],
        questionText: maps[i]['question_text'],
        answerText: maps[i]['answer_text'],
        languageCode: maps[i]['language_code'],
      );
    });
  }

  Future<void> clearDatabase() async {
    final db = await database;
    await db.delete('question_text');
    await db.delete('question');
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
