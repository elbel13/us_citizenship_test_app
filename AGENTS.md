# Agent Coding Guidelines for US Citizenship Test App

This document provides essential information for AI coding agents working on this Flutter/Dart project.

## Project Overview

A Flutter mobile app for US citizenship test preparation with flashcards, multiple choice, reading/writing practice, and simulated interviews. Uses SQLite for data storage, includes localization (English/Spanish), and integrates speech recognition/TTS services.

## Build, Lint & Test Commands

### Standard Operations
```bash
# Install dependencies
flutter pub get

# Run the app (requires emulator or device)
flutter run

# Run on specific device
flutter run -d <device-id>

# List available devices
flutter devices

# Analyze code for issues
flutter analyze

# Run all tests
flutter test

# Run a single test file
flutter test test/services/database_service_test.dart

# Run tests matching a pattern
flutter test --name "database initializes"

# Run tests matching a plain-text substring
flutter test --plain-name "DatabaseService"

# Build debug APK
flutter build apk --debug

# Build release APK
flutter build apk --release
```

### Hot Reload/Restart (when flutter run is active)
- **r**: Hot reload (preserves state)
- **R**: Hot restart (resets state)
- **q**: Quit

## Project Structure

```
lib/
├── main.dart                    # App entry point
├── models/                      # Data models with toMap/fromMap
├── screens/                     # UI screens (StatelessWidget/StatefulWidget)
├── services/                    # Business logic and data services
├── widgets/                     # Reusable UI components
├── theme/                       # Theme and color definitions
└── l10n/                        # Localization files (auto-generated)

test/
├── models/                      # Model tests
├── services/                    # Service tests
├── widgets/                     # Widget tests
└── helpers/                     # Test utilities
```

## Code Style Guidelines

### Import Order
1. Dart/Flutter SDK imports (`dart:*`, `package:flutter/*`)
2. Other package imports (`package:*`)
3. Relative imports (e.g., `../models/question.dart`, `screens/main_menu_screen.dart`)
4. No blank lines between import groups

Example:
```dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../models/question.dart';
import '../services/database_service.dart';
```

### Formatting
- **Use 2-space indentation** (Flutter/Dart standard)
- **Max line length**: Aim for 80 chars, allow up to ~100 when necessary
- **Trailing commas**: Always use trailing commas for multi-line parameter lists/collections
- **String quotes**: Single quotes for strings (use double quotes only for nested strings)
- Use `const` constructors wherever possible

### Types & Nullability
- **Always specify types** for class fields, parameters, and return values
- **Use null safety**: Mark nullable types with `?`, avoid using `!` unless certain
- **Use `late`** only when necessary for initialization
- Prefer `final` over `var` when values won't change

### Naming Conventions
- **Classes**: PascalCase (e.g., `DatabaseService`, `QuestionText`)
- **Files**: snake_case matching class name (e.g., `database_service.dart`)
- **Variables/Functions**: camelCase (e.g., `questionText`, `getQuestions()`)
- **Constants**: camelCase with `const` or `static const` (e.g., `passingThreshold`)
- **Private members**: Prefix with underscore (e.g., `_initDatabase()`, `_MenuItem`)
- **Enums**: PascalCase for enum type, camelCase for values (e.g., `EvaluationResult.pass`)

### Classes & Objects
- Use **singleton pattern** with factory constructor for services:
  ```dart
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();
  ```
- **Models** should have:
  - Required immutable fields (`final`)
  - Named constructor parameters with `required`
  - `toMap()` method for serialization
  - `factory fromMap()` for deserialization
  - Optional `toString()` override for debugging

### Widgets
- Prefer **StatelessWidget** when no state is needed
- Use `const` constructors: `const MyWidget({super.key, required this.field})`
- Always include `key` parameter: `super.key`
- Extract private widget classes with `_` prefix for complex UI (e.g., `_MenuItem`, `_MenuCard`)
- Add doc comments for public widgets with `///`

### Error Handling
- **Prefer explicit error handling** over silent failures
- Use `try-catch` blocks for async operations that may fail
- Use `print()` for debug logging (service initialization, errors)
- Rethrow errors in service methods after logging:
  ```dart
  catch (e) {
    print('Error loading data: $e');
    rethrow;
  }
  ```

### Async/Await
- Use `async`/`await` for asynchronous operations
- Return `Future<Type>` for async functions
- Always `await` database operations
- Close resources in `dispose()` for StatefulWidgets

### Database Patterns
- Use `Batch` for multiple inserts/updates
- Use **indexes** on frequently queried columns
- Use `ConflictAlgorithm.replace` or `.ignore` for upserts
- Always specify `whereArgs` for parameterized queries (prevents SQL injection)
- Use transactions for multi-step database operations

## Testing Guidelines

### Test Structure
```dart
void main() {
  group('ComponentName', () {
    setUp(() async {
      // Setup before each test
    });

    tearDown(() async {
      // Cleanup after each test
    });

    test('descriptive test name', () async {
      // Arrange, Act, Assert
    });
  });
}
```

### Widget Tests
- Wrap widgets in `MaterialApp` for testing
- Use `await tester.pumpWidget()` to render
- Use `find.text()`, `find.byType()`, `find.byKey()` for assertions
- Use descriptive test names that read like sentences

### Service Tests
- Use `TestWidgetsFlutterBinding.ensureInitialized()` in `main()`
- For database tests:
  - Initialize `sqfliteFfi` and set `databaseFactory = databaseFactoryFfi`
  - Use unique database paths per test via `DatabaseTestHelper`
  - Always close database in `tearDown()` and delete test files

### Test Helpers
- Create test helpers in `test/helpers/` for reusable test utilities
- Example: `DatabaseTestHelper` for creating/cleaning test databases

## Localization

- Strings are defined in `l10n.yaml` and ARB files
- Access via `AppLocalizations.of(context)!` (aliased as `l10n`)
- Generate files with: `flutter gen-l10n`
- Supported locales: English (`en`), Spanish (`es`)

## Common Patterns

### Service Initialization
Services use singleton pattern and are accessed via factory constructor:
```dart
final service = DatabaseService();
```

### Theme Usage
Access theme colors/styles via `Theme.of(context)`:
```dart
color: Theme.of(context).colorScheme.primary
textStyle: Theme.of(context).textTheme.bodyMedium
```

### Navigation
Use named routes defined in `main.dart`:
```dart
Navigator.pushNamed(context, '/flashcards');
```

### State Management
- Use `setState()` for local widget state
- Use `ChangeNotifier` for shared state (e.g., `ThemeService`)
- Listen with `addListener()` and `removeListener()` in `dispose()`

## Important Notes

- **Check `docs/TODO.md`** for features that need implementation
- **Never commit** database files or test databases to git
- **Always test** database migrations when changing schema
- **Use `print()` for debugging**, especially in services (not in production builds)
- **Assets** are loaded via `rootBundle.loadString('assets/file.json')`
- **Permissions** (microphone, location) are handled via `permission_handler` package
