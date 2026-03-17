# Feature Design: Bug Report

## Overview

This feature allows users to report bugs encountered in the app. The entry point is a new "Report a Bug" option in the Settings screen. When tapped, a bottom sheet form opens where the user can provide bug details. Upon submission, a pre-filled GitHub new-issue URL is opened in the device browser, allowing the bug to be tracked in the repository.

**Key characteristics:**
- No backend required
- Uses `url_launcher` package to open GitHub URLs
- Pre-fills title, description, screen context, reproducibility, exception text (if applicable), and platform info
- Can be launched contextually from error states in practice screens
- Lightweight and non-blocking

---

## GitHub Integration

### Repository

- **Repository URL:** `https://github.com/elbel13/us_citizenship_test_app`
- **Issue tracking:** GitHub Issues at https://github.com/elbel13/us_citizenship_test_app/issues

### GitHub New-Issue URL Format

The URL is constructed using the following format:

```
https://github.com/elbel13/us_citizenship_test_app/issues/new?title=TITLE&body=BODY&labels=bug
```

Both `title` and `body` query parameters must be properly URL-encoded using `Uri.encodeComponent()`.

**Implementation approach:** Use Dart's `Uri` class with named `queryParameters` map, which handles encoding automatically:

```dart
Uri(
  scheme: 'https',
  host: 'github.com',
  path: '/elbel13/us_citizenship_test_app/issues/new',
  queryParameters: {
    'title': title,
    'body': body,
    'labels': 'bug',
  },
)
```

---

## Dependencies

### New Dependency

Add the following to `pubspec.yaml` under the `dependencies` section:

```yaml
url_launcher: ^6.3.0
```

After modification, run:

```bash
flutter pub get
```

This package provides the `launchUrl()` function used to open URLs in the device browser.

---

## New Files

### 1. `lib/services/bug_report_service.dart`

**Purpose:** Builds GitHub new-issue URLs with pre-filled form data.

**Implementation notes:**
- Static-method-only class (no singleton needed)
- All methods are `static`
- Handles URL construction and encoding
- Includes app version and platform information

**Source code:**

```dart
import 'package:flutter/foundation.dart';
import 'dart:io';

class BugReportService {
  // Private constructor to prevent instantiation
  BugReportService._();

  static const String _repoUrl =
      'https://github.com/elbel13/us_citizenship_test_app';
  static const String _appVersion = '0.4.0+4';

  /// Builds a GitHub new-issue URL with pre-filled title and body.
  ///
  /// All required fields must be provided. [exceptionText] is optional and
  /// only included in the body if provided. The returned [Uri] can be opened
  /// using `launchUrl()` from the `url_launcher` package.
  ///
  /// Parameters:
  ///   - [title]: Brief summary of the bug (displayed in issue title)
  ///   - [description]: Detailed description of the issue
  ///   - [screenName]: Name of the screen where the bug occurred
  ///   - [reproducibility]: One of 'Always', 'Sometimes', or 'Once'
  ///   - [exceptionText]: Optional stack trace or exception message
  ///   - [platform]: Device platform (typically 'Android' or 'iOS')
  static Uri buildIssueUri({
    required String title,
    required String description,
    required String screenName,
    required String reproducibility,
    String? exceptionText,
    required String platform,
  }) {
    final bodyLines = <String>[
      '## Description',
      description.isEmpty ? '(No description provided)' : description,
      '',
      '## Context',
      '- **Screen:** $screenName',
      '- **Reproducibility:** $reproducibility',
      '- **App Version:** $_appVersion',
      '- **Platform:** $platform',
    ];

    if (exceptionText != null && exceptionText.isNotEmpty) {
      bodyLines.add('- **Exception:** `$exceptionText`');
    }

    final body = bodyLines.join('\n');

    return Uri(
      scheme: 'https',
      host: 'github.com',
      path: '/elbel13/us_citizenship_test_app/issues/new',
      queryParameters: {
        'title': title,
        'body': body,
        'labels': 'bug',
      },
    );
  }
}
```

**Key details:**
- `_appVersion` is a hardcoded constant matching the current app version (see `pubspec.yaml`)
- Body is formatted as Markdown with clear sections
- Exception text is truncated/sanitized by the caller if needed
- `Uri` constructor automatically handles URL encoding via `queryParameters`

---

### 2. `lib/widgets/bug_report_bottom_sheet.dart`

**Purpose:** Renders the bug report form as a modal bottom sheet.

**Implementation notes:**
- `StatefulWidget` with form validation
- Shown via `showModalBottomSheet()`, typically using the static `show()` convenience method
- Handles platform detection, form submission, and browser opening
- Includes error handling for cases where the browser cannot open the URL

**Public API:**

```dart
class BugReportBottomSheet extends StatefulWidget {
  /// Pre-selected screen name (e.g., when launched from an error state).
  /// If not provided, defaults to 'Not sure'.
  final String? initialScreen;

  /// Pre-filled exception text (e.g., when launched from a caught error).
  /// If provided, shown in a read-only field. Automatically truncated to 200 chars.
  final String? initialException;

  const BugReportBottomSheet({
    super.key,
    this.initialScreen,
    this.initialException,
  });

  /// Convenience static method to show the bottom sheet.
  ///
  /// This wraps [showModalBottomSheet()] with appropriate configuration
  /// for the bug report form.
  static void show(
    BuildContext context, {
    String? initialScreen,
    String? initialException,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => BugReportBottomSheet(
        initialScreen: initialScreen,
        initialException: initialException,
      ),
    );
  }
}
```

**Form fields:**

#### Field 1: Title (Required)
- **Widget type:** `TextFormField`
- **Label:** None (use hint instead)
- **Hint text:** `'Brief summary of the issue'`
- **Max length:** 100 characters
- **Validation:** Required (error: `'Title is required'`)
- **Input type:** Text
- **Min lines:** 1

#### Field 2: Description (Optional)
- **Widget type:** `TextFormField`
- **Label:** `'Description'` (optional label)
- **Hint text:** `'What happened? What did you expect?'`
- **Max length:** 500 characters (no hard limit enforced, but suggested)
- **Max lines:** 4
- **Validation:** None (optional field)
- **Input type:** Multiline text

#### Field 3: Screen (Required)
- **Widget type:** `DropdownButtonFormField<String>`
- **Label:** `'Where did this happen?'`
- **Default value:** `initialScreen ?? 'Not sure'`
- **Options (in order):**
  1. `'Not sure'`
  2. `'Main Menu'`
  3. `'Flashcards'`
  4. `'Multiple Choice'`
  5. `'Reading Practice'`
  6. `'Writing Practice'`
  7. `'Simulated Interview'`
  8. `'Settings'`
  9. `'Other'`
- **Validation:** Required (error: `'Please select a screen'`)

#### Field 4: Reproducibility (Required)
- **Widget type:** `SegmentedButton<String>`
- **Label (above widget):** `'How often does this happen?'`
- **Segments (in order):** `'Always'`, `'Sometimes'`, `'Once'`
- **Initial selection:** `{'Sometimes'}`
- **Single selection:** Yes (only one segment selected at a time)

#### Field 5: Exception Details (Conditional, Read-only)
- **Widget type:** `TextField` (not `TextFormField`, as it's read-only)
- **Visibility:** Only shown if `initialException != null`
- **Label:** `'Error details (auto-filled)'`
- **Read-only:** `true`
- **Max lines:** 5
- **Font:** Monospace (use `const TextStyle(fontFamily: 'monospace')`)
- **Content:** Exception text truncated to 200 characters
  - If truncated, append `'...'` to the displayed text
  - Truncation logic: `initialException!.substring(0, min(initialException!.length, 200)) + (initialException!.length > 200 ? '...' : '')`

**Submit Button:**
- **Widget type:** `ElevatedButton` (full width, typically via `SizedBox(width: double.infinity)`)
- **Label:** `'Open GitHub Issue'`
- **On tap behavior:**
  1. Validate the form using `_formKey.currentState!.validate()`
  2. Detect platform:
     ```dart
     final platform = Platform.isAndroid
         ? 'Android'
         : Platform.isIOS
         ? 'iOS'
         : 'Other';
     ```
     (Requires `import 'dart:io'`)
  3. Collect form values:
     - Title: from title field controller
     - Description: from description field controller (can be empty)
     - Screen: from dropdown selection
     - Reproducibility: from segmented button selection (will be one of the three values)
     - Exception: `initialException` (not re-read from form)
     - Platform: from detection above
  4. Call `BugReportService.buildIssueUri(...)` with all parameters
  5. Call `launchUrl(uri, mode: LaunchMode.externalApplication)` from `url_launcher`
  6. If `launchUrl` returns `false`:
     - Show a `SnackBar` with message: `'Could not open browser. Please visit github.com/elbel13/us_citizenship_test_app/issues manually.'`
     - Do NOT close the bottom sheet; let the user try again or dismiss manually
  7. If `launchUrl` returns `true`:
     - Close the bottom sheet: `Navigator.pop(context)`

**Helper text:**
Below the submit button, add a small text widget:
- Text: `'App version and platform info will be included automatically.'`
- Styling: `Theme.of(context).textTheme.bodySmall` with `Colors.grey` color
- Margin: Top margin of 8 dp

**Layout structure:**

```
Container (full-width modal)
├─ Drag Handle (visual indicator)
│  └─ Container (40×4, gray, centered, bottom margin 16)
└─ SingleChildScrollView
   └─ Form (key: _formKey)
      └─ Padding (16 + keyboard avoidance)
         ├─ Title field
         ├─ SizedBox (8)
         ├─ Description field
         ├─ SizedBox (8)
         ├─ Screen dropdown
         ├─ SizedBox (8)
         ├─ Reproducibility label
         ├─ SegmentedButton
         ├─ SizedBox (8)
         ├─ [Exception field - if initialException != null]
         ├─ SizedBox (16)
         ├─ Submit button
         ├─ SizedBox (8)
         └─ Helper text
```

**Padding calculation:**
```dart
Padding(
  padding: EdgeInsets.fromLTRB(
    16,
    16,
    16,
    16 + MediaQuery.viewInsetsOf(context).bottom,
  ),
  child: // ... form content
)
```

This ensures the form is not obscured by the on-screen keyboard.

**Drag handle styling:**
```dart
Container(
  width: 40,
  height: 4,
  margin: const EdgeInsets.only(bottom: 16),
  decoration: BoxDecoration(
    color: Colors.grey.shade400,
    borderRadius: BorderRadius.circular(2),
  ),
)
```

**Complete implementation template:**

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/bug_report_service.dart';

class BugReportBottomSheet extends StatefulWidget {
  final String? initialScreen;
  final String? initialException;

  const BugReportBottomSheet({
    super.key,
    this.initialScreen,
    this.initialException,
  });

  static void show(
    BuildContext context, {
    String? initialScreen,
    String? initialException,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => BugReportBottomSheet(
        initialScreen: initialScreen,
        initialException: initialException,
      ),
    );
  }

  @override
  State<BugReportBottomSheet> createState() => _BugReportBottomSheetState();
}

class _BugReportBottomSheetState extends State<BugReportBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  String _selectedScreen = 'Not sure';
  String _selectedReproducibility = 'Sometimes';
  bool _isSubmitting = false;

  static const List<String> _screenOptions = [
    'Not sure',
    'Main Menu',
    'Flashcards',
    'Multiple Choice',
    'Reading Practice',
    'Writing Practice',
    'Simulated Interview',
    'Settings',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _selectedScreen = widget.initialScreen ?? 'Not sure';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitBugReport() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final platform = Platform.isAndroid
          ? 'Android'
          : Platform.isIOS
          ? 'iOS'
          : 'Other';

      final uri = BugReportService.buildIssueUri(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        screenName: _selectedScreen,
        reproducibility: _selectedReproducibility,
        exceptionText: widget.initialException,
        platform: platform,
      );

      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (mounted) {
        if (launched) {
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              message:
                  'Could not open browser. Please visit '
                  'github.com/elbel13/us_citizenship_test_app/issues manually.',
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final truncatedException = widget.initialException != null
        ? widget.initialException!.substring(
            0,
            widget.initialException!.length > 200
                ? 200
                : widget.initialException!.length,
          )
        : '';
    final showTruncated = widget.initialException != null &&
        widget.initialException!.length > 200;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 16),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Form
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  0,
                  16,
                  16 + MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title field
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          hintText: 'Brief summary of the issue',
                          border: OutlineInputBorder(),
                        ),
                        maxLength: 100,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Title is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      // Description field
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText:
                              'What happened? What did you expect?',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 4,
                      ),
                      const SizedBox(height: 8),
                      // Screen dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedScreen,
                        decoration: const InputDecoration(
                          labelText: 'Where did this happen?',
                          border: OutlineInputBorder(),
                        ),
                        items: _screenOptions
                            .map(
                              (option) => DropdownMenuItem(
                                value: option,
                                child: Text(option),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedScreen = value);
                          }
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a screen';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      // Reproducibility label
                      Text(
                        'How often does this happen?',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 8),
                      // Reproducibility segmented button
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(label: Text('Always')),
                          ButtonSegment(label: Text('Sometimes')),
                          ButtonSegment(label: Text('Once')),
                        ],
                        selected: {_selectedReproducibility},
                        onSelectionChanged: (Set<String> newSelection) {
                          setState(
                            () => _selectedReproducibility =
                                newSelection.first,
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      // Exception field (conditional)
                      if (widget.initialException != null) ...[
                        TextField(
                          readOnly: true,
                          maxLines: 5,
                          decoration: const InputDecoration(
                            labelText: 'Error details (auto-filled)',
                            border: OutlineInputBorder(),
                          ),
                          style: const TextStyle(fontFamily: 'monospace'),
                          controller: TextEditingController(
                            text: truncatedException +
                                (showTruncated ? '...' : ''),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ] else
                        const SizedBox(height: 16),
                      // Submit button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              _isSubmitting ? null : _submitBugReport,
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Open GitHub Issue'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Helper text
                      Center(
                        child: Text(
                          'App version and platform info will be included automatically.',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## Modifications to Existing Files

### 1. `pubspec.yaml`

**Location:** Root of project

**Change:** Add `url_launcher` dependency

**Before:**
```yaml
dependencies:
  flutter:
    sdk: flutter
  sqflite: ^2.3.0
  # ... other dependencies
```

**After:**
```yaml
dependencies:
  flutter:
    sdk: flutter
  sqflite: ^2.3.0
  url_launcher: ^6.3.0
  # ... other dependencies
```

**Action after modification:** Run `flutter pub get`

---

### 2. `lib/screens/settings_screen.dart`

**Changes:** Add import and new settings section for bug reporting.

**Step 1: Add import at top of file**

After the existing imports, add:

```dart
import '../widgets/bug_report_bottom_sheet.dart';
```

**Step 2: Add new settings section in ListView**

In the `ListView` children, after the existing `Divider` following the language selection tile, add:

```dart
const Divider(),
ListTile(
  leading: const Icon(Icons.bug_report_outlined),
  title: const Text('Report a Bug'),
  subtitle: const Text('Open a GitHub issue with details pre-filled'),
  onTap: () => BugReportBottomSheet.show(context),
),
```

**Updated section (for reference):**

```dart
const Divider(),
ListTile(
  leading: const Icon(Icons.language),
  title: Text(l10n.language),
  subtitle: Text(_getLanguageName(context)),
  trailing: const Icon(Icons.arrow_forward_ios),
  onTap: () => _showLanguageDialog(context),
),
const Divider(),
ListTile(
  leading: const Icon(Icons.bug_report_outlined),
  title: const Text('Report a Bug'),
  subtitle: const Text('Open a GitHub issue with details pre-filled'),
  onTap: () => BugReportBottomSheet.show(context),
),
if (widget.onboardingService != null) ...[
  const Divider(),
  // ... rest of conditional section
]
```

---

### 3. Error handling in practice screens

Modify the following screens to add a contextual bug report button in error states:
- `lib/screens/flashcards_screen.dart`
- `lib/screens/multiple_choice_screen.dart`
- `lib/screens/reading_practice_screen.dart`
- `lib/screens/writing_practice_screen.dart`
- `lib/screens/simulated_interview_screen.dart`

**Change pattern for each screen:**

In the `build()` method, find the error state (typically `_error != null` condition), and replace:

**Before:**
```dart
_error != null
    ? Center(child: Text('Error: $_error'))
    : ...
```

**After:**
```dart
_error != null
    ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Error: $_error'),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => BugReportBottomSheet.show(
                context,
                initialScreen: '<ScreenName>',
                initialException: _error,
              ),
              icon: const Icon(Icons.bug_report_outlined),
              label: const Text('Report this bug'),
            ),
          ],
        ),
      )
    : ...
```

**Screen name mappings (use for `initialScreen` parameter):**
- Flashcards screen → `'Flashcards'`
- Multiple choice screen → `'Multiple Choice'`
- Reading practice screen → `'Reading Practice'`
- Writing practice screen → `'Writing Practice'`
- Simulated interview screen → `'Simulated Interview'`

**Import requirement:** Each modified screen must add:

```dart
import '../widgets/bug_report_bottom_sheet.dart';
```

---

## Code Style Requirements

All new code must follow the project's existing conventions:

- **Indentation:** 2 spaces (Dart standard)
- **String quotes:** Single quotes for strings, double quotes only for nested strings
- **Const constructors:** Use `const` wherever possible for performance
- **Key parameter:** All widgets must include `super.key` in constructor
- **Field modifiers:** Use `final` for fields that don't change; `late` only when necessary
- **Trailing commas:** Always use trailing commas on multi-line parameter lists and collections
- **Type annotations:** Always specify types for fields, parameters, and return values
- **Null safety:** Use `?` for nullable types; avoid using `!` unless the value is guaranteed non-null
- **Private members:** Prefix with underscore (e.g., `_formKey`, `_submitBugReport`)
- **Import order:**
  1. Dart SDK imports (`dart:*`)
  2. Flutter imports (`package:flutter/*`)
  3. Package imports (`package:*`)
  4. Relative imports (`../`, `./`)
  5. No blank lines between groups

---

## Verification Checklist

After implementation, verify the following:

1. **Code analysis:**
   - Run `flutter analyze` — should report no new errors or warnings related to the bug report feature
   - Verify all imports are correct and in the proper order

2. **Build:**
   - Run `flutter pub get` to ensure all dependencies resolve
   - Build the debug APK: `flutter build apk --debug` (or run on an emulator)
   - Verify the app builds without errors

3. **Functionality (manual testing):**
   - Navigate to Settings screen
   - Tap "Report a Bug"
   - Verify bottom sheet opens with correct layout (drag handle, form fields, etc.)
   - Fill in form fields (test required field validation by leaving title empty)
   - Tap "Open GitHub Issue"
   - Verify GitHub new-issue page opens in browser with:
     - Pre-filled title from form
     - Pre-filled body with description, screen name, reproducibility, app version, and platform
     - `bug` label applied
   - If browser cannot open, verify SnackBar error message appears

4. **Contextual launching (optional but recommended):**
   - In a practice screen, simulate an error state or manually trigger error handling
   - Verify bug report button appears in error UI
   - Tap "Report this bug"
   - Verify bottom sheet opens with `initialScreen` pre-selected and exception text shown in read-only field
   - Verify exception text is truncated at 200 characters with `...` suffix if longer

5. **Platform detection:**
   - On Android device: verify "Platform: Android" appears in GitHub issue body
   - On iOS device (if available): verify "Platform: iOS" appears in GitHub issue body

6. **Existing tests:**
   - Run `flutter test` — all existing tests should still pass (no regressions)

---

## Notes for Implementer

1. **Monospace font:** The exception field uses `fontFamily: 'monospace'` to display exception text in a fixed-width font for readability.

2. **Keyboard avoidance:** The bottom sheet uses `isScrollControlled: true` and keyboard-aware padding to ensure form fields remain visible when the on-screen keyboard appears.

3. **URL encoding:** Dart's `Uri` class with `queryParameters` handles encoding automatically. Do not manually encode values.

4. **External application launch:** Use `LaunchMode.externalApplication` to open the URL in the system browser (Chrome, Safari, etc.), not in an in-app webview.

5. **Exception text handling:** The exception text is passed as-is from the screen; consider that it may be very long. The bottom sheet truncates it for display, but the full text is sent to GitHub (which will handle very long bodies).

6. **Segmented button segments:** Ensure segments are labeled `'Always'`, `'Sometimes'`, and `'Once'` — these exact strings are sent to GitHub and should be human-readable.

7. **Platform import:** Remember to import `dart:io` in `bug_report_bottom_sheet.dart` for `Platform` class.

8. **No tests:** As specified, do not implement tests for this feature. All manual verification should be performed.

9. **Version constant:** The `_appVersion` in `BugReportService` must be kept in sync with the version in `pubspec.yaml`. If the app version changes, update `_appVersion` in the service.

---

## Future Enhancements (Out of Scope)

- Analytics tracking for bug report submissions
- User authentication to attach GitHub username to reports
- In-app issue list viewing
- Localization of form labels and placeholders
- File attachment support (screenshots, logs)
