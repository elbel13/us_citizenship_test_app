# End Practice Early Feature Design

## Overview

This document specifies the implementation of an "End Practice Early" feature that allows users to exit a practice session from any practice screen and return to the main menu. The feature is implemented as a reusable `EndPracticeButton` widget that can be added to the `AppBar` of any practice screen.

The first screen to receive this feature is **Multiple Choice** (`lib/screens/multiple_choice_screen.dart`). Other screens are explicitly **out of scope** for this task but are documented for future work (see [Screens Out of Scope](#screens-out-of-scope)).

**No new dependencies are required.**

---

## Feature Behavior

### User Flow

1. User is on any practice screen (e.g., Multiple Choice quiz)
2. User taps the stop icon button in the `AppBar` (far right of the action buttons)
3. A confirmation dialog appears with:
   - Title: "End Practice?"
   - Optional progress summary (e.g., "3 correct, 2 incorrect") if at least one question has been answered
   - Two action buttons: "Cancel" and "End Practice"
4. If user taps "Cancel": dialog closes, user remains on the practice screen
5. If user taps "End Practice": user is navigated back to the Main Menu (`'/'`)

### Navigation Behavior

The navigation must use:
```dart
Navigator.of(context).popUntil((route) => route.isFirst);
```

This ensures that regardless of how the practice screen was pushed (direct route or nested navigation), the user always returns to the first route in the stack, which is the Main Menu (`'/'`).

---

## Implementation

### File 1: New Widget — `lib/widgets/end_practice_button.dart`

Create a new file implementing a reusable, stateless button widget.

#### Class Definition

```dart
/// An AppBar action button that lets the user end the current practice session.
///
/// Shows a confirmation dialog before navigating back to the main menu.
/// Optionally displays a [progressSummary] in the dialog body (e.g. "3 correct,
/// 2 incorrect") when meaningful partial progress exists.
class EndPracticeButton extends StatelessWidget {
  /// Optional one-line summary of the user's current progress.
  /// If null, only the generic warning is shown in the dialog.
  final String? progressSummary;

  const EndPracticeButton({super.key, this.progressSummary});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.stop_circle_outlined),
      tooltip: 'End practice',
      onPressed: () => _confirmEnd(context),
    );
  }

  Future<void> _confirmEnd(BuildContext context) async {
    // Implementation details below
  }
}
```

#### Widget Behavior

##### build() Method

- Returns an `IconButton` with:
  - `icon: const Icon(Icons.stop_circle_outlined)` — a stop circle icon
  - `tooltip: 'End practice'` — tooltip text shown on long press
  - `onPressed` callback that calls `_confirmEnd(context)`

##### _confirmEnd(BuildContext context) Method

This private method displays the confirmation dialog and handles the user's response.

**Dialog Display:**

Call `showDialog<bool>(...)` with the following configuration:
- `context`: the provided build context
- `builder`: a function returning an `AlertDialog`

**AlertDialog Properties:**

- `title: const Text('End Practice?')`
- `content`: a `Text` widget whose content depends on `progressSummary`:
  - If `progressSummary != null`: `'$progressSummary\n\nReturn to the main menu?'`
  - If `progressSummary == null`: `'Return to the main menu?'`
- `actions`: a `List<Widget>` with two buttons (in order):
  1. **Cancel Button** — `TextButton`:
     ```dart
     TextButton(
       onPressed: () => Navigator.pop(dialogContext, false),
       child: const Text('Cancel'),
     )
     ```
  2. **End Practice Button** — `ElevatedButton` with orange background:
     ```dart
     ElevatedButton(
       onPressed: () => Navigator.pop(dialogContext, true),
       style: ElevatedButton.styleFrom(
         backgroundColor: Colors.orange,
       ),
       child: const Text('End Practice'),
     )
     ```

**Post-Dialog Navigation:**

After `showDialog` returns with result `confirmed`:
```dart
if (confirmed == true && context.mounted) {
  Navigator.of(context).popUntil((route) => route.isFirst);
}
```

- Check `confirmed == true` (not just `confirmed`) because `showDialog` can return `null` if the dialog is dismissed by tapping outside
- Check `context.mounted` to ensure the widget is still mounted before calling `Navigator`
- Use `Navigator.of(context).popUntil(...)` to pop all routes until reaching the first route (Main Menu)

#### Full Implementation Code

```dart
import 'package:flutter/material.dart';

/// An AppBar action button that lets the user end the current practice session.
///
/// Shows a confirmation dialog before navigating back to the main menu.
/// Optionally displays a [progressSummary] in the dialog body (e.g. "3 correct,
/// 2 incorrect") when meaningful partial progress exists.
class EndPracticeButton extends StatelessWidget {
  /// Optional one-line summary of the user's current progress.
  /// If null, only the generic warning is shown in the dialog.
  final String? progressSummary;

  const EndPracticeButton({super.key, this.progressSummary});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.stop_circle_outlined),
      tooltip: 'End practice',
      onPressed: () => _confirmEnd(context),
    );
  }

  Future<void> _confirmEnd(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('End Practice?'),
        content: Text(
          progressSummary != null
              ? '$progressSummary\n\nReturn to the main menu?'
              : 'Return to the main menu?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('End Practice'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }
}
```

#### Import Order

At the top of `lib/widgets/end_practice_button.dart`:
```dart
import 'package:flutter/material.dart';
```

This is the only import needed.

---

### File 2: Modified Screen — `lib/screens/multiple_choice_screen.dart`

#### Change 1: Add Import

Add the following import to the imports section of the file, grouped with other relative imports at the bottom of the import block (after SDK and package imports):

```dart
import '../widgets/end_practice_button.dart';
```

**Current import block** (lines 1–6):
```dart
import 'dart:math';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/question.dart';
import '../services/database_service.dart';
import '../widgets/progress_indicator_widget.dart';
```

**Modified import block** (add at the end):
```dart
import 'dart:math';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/question.dart';
import '../services/database_service.dart';
import '../widgets/progress_indicator_widget.dart';
import '../widgets/end_practice_button.dart';
```

#### Change 2: Update AppBar

**Current code** (line 208):
```dart
appBar: AppBar(title: Text(l10n.multipleChoice)),
```

**Modified code**:
```dart
appBar: AppBar(
  title: Text(l10n.multipleChoice),
  actions: [
    EndPracticeButton(
      progressSummary: (_correctAnswers + _incorrectAnswers) > 0
          ? '$_correctAnswers correct, $_incorrectAnswers incorrect'
          : null,
    ),
  ],
),
```

**Explanation:**

- The `AppBar` now includes an `actions` parameter with a `List<Widget>`
- `EndPracticeButton` is added as the sole action
- `progressSummary` is set conditionally:
  - If the total answered questions is greater than 0: `'$_correctAnswers correct, $_incorrectAnswers incorrect'`
  - Otherwise (no questions answered yet): `null` (shows only the generic warning in the dialog)

#### Button Placement

The button automatically appears as the rightmost icon in the `AppBar`. The button is present on all screen states:
- Loading state (while questions are being fetched)
- Error state (if questions fail to load)
- Quiz state (while answering questions)
- Summary state (after all questions are answered)

---

## Code Style Requirements

All code must follow the project's existing conventions:

### Formatting & Structure
- **Indentation**: 2 spaces (Flutter/Dart standard)
- **Line length**: Target 80 characters; allow up to ~100 when necessary
- **Trailing commas**: Always use trailing commas on multi-line parameter lists and collections
- **Quote style**: Single quotes for strings (double quotes only for nested strings)
- **Const constructors**: Use `const` wherever possible for optimization

### Naming & Types
- **Always specify types** for all class fields, parameters, and return values
- **Use null safety**: Mark nullable types with `?`; avoid `!` unless certain
- **Prefer `final`** over `var` for fields and local variables (except where values change)
- **Private members**: Prefix with underscore (e.g., `_confirmEnd()`)
- **File names**: snake_case matching class name (e.g., `end_practice_button.dart`)
- **Class names**: PascalCase (e.g., `EndPracticeButton`)
- **Function/variable names**: camelCase (e.g., `_confirmEnd`)

### Widget Classes
- **Doc comments**: Public widget classes must have a doc comment (`///`)
- **Key parameter**: Always include `super.key` in the constructor
- **Constructors**: Use named parameters with `required` where appropriate
- **StatelessWidget**: Preferred when no state is needed (as with `EndPracticeButton`)

### Import Order
1. `dart:*` imports (SDK)
2. `package:flutter/*` imports
3. Other `package:*` imports
4. Relative imports (no leading `./`)
5. No blank lines between groups

Example:
```dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../models/question.dart';
import '../services/database_service.dart';
import '../widgets/end_practice_button.dart';
```

---

## Testing & Verification

### Manual Testing Checklist

Perform the following manual tests to verify the feature works correctly:

1. **Initial State (No Questions Answered)**
   - Navigate to Multiple Choice screen
   - Wait for questions to load
   - Verify the stop icon appears in the AppBar (far right)
   - Tap the stop icon
   - Verify the dialog shows: "End Practice?" title
   - Verify the dialog body shows: "Return to the main menu?"
   - Verify two buttons are present: "Cancel" and "End Practice"

2. **Cancel Action**
   - From the dialog, tap "Cancel"
   - Verify the dialog closes
   - Verify you remain on the Multiple Choice screen
   - Verify the first question is still displayed

3. **Progress Summary (After Answering)**
   - Answer the first question (select an answer and tap Submit)
   - Verify the feedback is displayed
   - Tap the stop icon in the AppBar
   - Verify the dialog shows: "End Practice?" title
   - Verify the dialog body shows: "[X] correct, [Y] incorrect" followed by "Return to the main menu?"
     - (e.g., "1 correct, 0 incorrect" or "0 correct, 1 incorrect")

4. **End Practice Navigation**
   - From any dialog state, tap "End Practice"
   - Verify the dialog closes
   - Verify you are returned to the Main Menu (`'/'`)
   - Verify the Multiple Choice screen is no longer in the navigation stack

5. **Dialog Button Styling**
   - Verify "Cancel" button is a `TextButton` with standard styling
   - Verify "End Practice" button is an `ElevatedButton` with orange background

6. **Summary Screen State**
   - Complete the entire quiz (answer all questions and reach the summary screen)
   - Verify the stop icon is still visible in the AppBar
   - Tap the stop icon
   - Verify the dialog appears with the final score summary
   - Tap "End Practice"
   - Verify you return to the Main Menu

### Automated Testing

**Do not** implement unit or widget tests for this feature. Testing is out of scope for this task.

### Code Analysis

After implementation, run the following commands:

```bash
flutter analyze
```

Verify:
- No new errors are introduced
- No new warnings are introduced
- All existing tests still pass (run before implementation as a baseline)

```bash
flutter test
```

Verify:
- All existing unit and widget tests pass
- No new test failures are introduced

---

## Screens Out of Scope (Future Work)

The following screens are **not** modified in this task but should implement the same feature in future work. The expected implementation approach for each is documented here for reference:

### 1. Flashcards (`lib/screens/flashcards_screen.dart`)

**Effort**: Low  
**Progress tracking**: No scoring system; card index exists but not typically displayed as a summary

**Implementation notes:**
- Add `EndPracticeButton` to the AppBar (same as Multiple Choice)
- `progressSummary` should always be `null` (no score to display)
- Dialog will show only the generic "Return to the main menu?" message
- No service cleanup required

### 2. Reading Practice (`lib/screens/reading_practice_screen.dart`)

**Effort**: Medium  
**Progress tracking**: Partially tracked; may have a score displayed

**Implementation notes:**
- Add `EndPracticeButton` to the AppBar
- Include a `progressSummary` if score tracking exists (varies by implementation)
- **Critical**: Stop speech-to-text (STT) service before confirming:
  - Get reference to STT service from the screen state
  - Call `_sttService.stop()` before popping
  - Example:
    ```dart
    if (confirmed == true && context.mounted) {
      await _sttService.stop();
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
    ```

### 3. Writing Practice (`lib/screens/writing_practice_screen.dart`)

**Effort**: Medium  
**Progress tracking**: Partially tracked; may have a score displayed

**Implementation notes:**
- Add `EndPracticeButton` to the AppBar
- Include a `progressSummary` if score tracking exists
- **Critical**: Stop text-to-speech (TTS) service before confirming:
  - Get reference to TTS service from the screen state
  - Call `_ttsService.stop()` (or equivalent) before popping
  - Example:
    ```dart
    if (confirmed == true && context.mounted) {
      await _ttsService.stop();
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
    ```

### 4. Simulated Interview (`lib/screens/simulated_interview_screen.dart`)

**Effort**: High  
**Progress tracking**: Fully tracked with multiple metrics; most complex screen

**Implementation notes:**
- Add `EndPracticeButton` to the AppBar
- Include comprehensive `progressSummary` (number of questions, current score, time elapsed, etc.)
- **Critical**: Stop both TTS and polling/async operations:
  - Stop TTS service: `await _ttsService.stop()`
  - Cancel polling loop: Set a cancellation flag that the polling loop checks
  - Example implementation pattern:
    ```dart
    bool _shouldCancelPolling = false;
    
    // In polling loop:
    while (!_shouldCancelPolling && otherConditions) {
      // ... polling logic
    }
    
    // In confirmation handler:
    if (confirmed == true && context.mounted) {
      _shouldCancelPolling = true;
      await _ttsService.stop();
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
    ```

---

## API Reference: EndPracticeButton

### Constructor

```dart
const EndPracticeButton({
  super.key,
  this.progressSummary,
})
```

**Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `key` | `Key?` | `null` | Optional widget key for testing |
| `progressSummary` | `String?` | `null` | Optional one-line progress summary; if `null`, only generic warning shown |

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `progressSummary` | `String?` | The user's progress summary to display in the dialog |

### Build Method

**Returns**: `Widget` (an `IconButton`)

**Side effects**: None (button is stateless)

### Dialog Behavior

| Event | Dialog Content | Action Buttons |
|-------|----------------|-----------------|
| Button tapped (no progress) | "Return to the main menu?" | Cancel, End Practice |
| Button tapped (with progress) | "[score]\n\nReturn to the main menu?" | Cancel, End Practice |
| Cancel tapped | N/A | Navigation: stays on current screen |
| End Practice tapped | N/A | Navigation: pops to Main Menu |

---

## Example Usage in Multiple Choice

**Before:**
```dart
appBar: AppBar(title: Text(l10n.multipleChoice)),
```

**After:**
```dart
appBar: AppBar(
  title: Text(l10n.multipleChoice),
  actions: [
    EndPracticeButton(
      progressSummary: (_correctAnswers + _incorrectAnswers) > 0
          ? '$_correctAnswers correct, $_incorrectAnswers incorrect'
          : null,
    ),
  ],
),
```

---

## Acceptance Criteria

The feature is complete when:

1. ✅ `lib/widgets/end_practice_button.dart` is created with the exact specification above
2. ✅ `lib/screens/multiple_choice_screen.dart` is updated with the import and AppBar changes
3. ✅ `flutter analyze` reports no new errors or warnings
4. ✅ All existing tests pass without modification
5. ✅ Manual testing checklist passes entirely
6. ✅ The stop icon appears in the AppBar and is functional
7. ✅ Tapping Cancel returns to the quiz; tapping End Practice returns to Main Menu
8. ✅ Progress summary displays correctly (null on first question, score after)
9. ✅ Code follows all style requirements and conventions

---

## Notes for Implementer

- **Do not** add any new dependencies
- **Do not** modify any files other than `end_practice_button.dart` and `multiple_choice_screen.dart`
- **Do not** implement tests for the new feature
- **Do not** modify other practice screens (they are out of scope)
- The feature is **purely UI-based**; no database or service logic is required
- All state needed for the feature (correct/incorrect counts) already exists in `MultipleChoiceScreenState`
- Use `context.mounted` to safely check if the widget is still mounted before navigation
- The `popUntil` approach ensures the button works regardless of how the screen was navigated to
