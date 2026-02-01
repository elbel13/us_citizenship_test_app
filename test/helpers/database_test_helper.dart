import 'dart:io';
import 'package:path/path.dart';

/// Helper for managing isolated database instances in tests.
/// Each test gets its own unique database file to prevent concurrency issues.
class DatabaseTestHelper {
  static int _testCounter = 0;

  /// Generate a unique database path for this test.
  /// Each test gets its own database file to avoid locking issues.
  static String getUniqueDatabasePath() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final counter = _testCounter++;
    return join(Directory.systemTemp.path, 'test_db_${timestamp}_$counter.db');
  }

  /// Delete a database file and all its associated files (-journal, -wal, -shm).
  static Future<void> deleteDatabaseFile(String path) async {
    try {
      final dbFile = File(path);
      if (await dbFile.exists()) {
        await dbFile.delete();
      }

      // Delete SQLite auxiliary files
      final journalFile = File('$path-journal');
      if (await journalFile.exists()) {
        await journalFile.delete();
      }

      final walFile = File('$path-wal');
      if (await walFile.exists()) {
        await walFile.delete();
      }

      final shmFile = File('$path-shm');
      if (await shmFile.exists()) {
        await shmFile.delete();
      }
    } catch (e) {
      // Ignore errors during cleanup
    }
  }
}
