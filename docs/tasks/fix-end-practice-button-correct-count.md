# Task: Fix Incorrect "Correct" Count in End Practice Dialog

## Overview

The "End Practice" confirmation dialog displays the wrong value for the "Correct" row in
its progress summary. It shows the total number of questions answered instead of the number
answered correctly. This is a one-line typo fix in `lib/widgets/end_practice_button.dart`.

---

## Parallel Execution Notice

**This task modifies `lib/widgets/end_practice_button.dart`.**

No other concurrent task touches this file. This task is fully independent.

**Rules for this task:**
1. Make only the single-line change described in this spec (`$_totalAnswered` → `$correctAnswers`).
2. Do not reformat, rename, or alter any other code in the file.
3. Run `flutter analyze && flutter test` after your change and fix any errors introduced by your edit only.

---

## Problem

In `lib/widgets/end_practice_button.dart`, the `EndPracticeButton` widget computes:

```dart
int get _totalAnswered => correctAnswers + incorrectAnswers;
```

Inside `_showConfirmationDialog`, the progress summary rows are built as follows (lines
55–68):

```dart
Row(
  children: [
    Icon(Icons.check_circle, color: Colors.green, size: 20),
    const SizedBox(width: 8),
    Text('Correct: $_totalAnswered'),   // <-- BUG: should be correctAnswers
  ],
),
const SizedBox(height: 4),
Row(
  children: [
    Icon(Icons.cancel, color: Colors.red, size: 20),
    const SizedBox(width: 8),
    Text('Incorrect: $incorrectAnswers'),
  ],
),
const SizedBox(height: 4),
Row(
  children: [
    Icon(Icons.help_outline, color: Colors.grey, size: 20),
    const SizedBox(width: 8),
    Text('Unanswered: ${totalItems - _totalAnswered}'),
  ],
),
```

The "Correct" row uses `$_totalAnswered` (the sum of correct + incorrect) instead of
`$correctAnswers`. For example, if the user has answered 5 questions — 3 correct and 2
incorrect — the dialog shows:

```
✅ Correct: 5      ← wrong, should be 3
❌ Incorrect: 2
❓ Unanswered: 123
```

The "Incorrect" and "Unanswered" rows are correct.

---

## Solution

Change `$_totalAnswered` to `$correctAnswers` on the single affected line.

**File:** `lib/widgets/end_practice_button.dart`

**Before:**
```dart
Text('Correct: $_totalAnswered'),
```

**After:**
```dart
Text('Correct: $correctAnswers'),
```

That is the entire change.

---

## Affected Files

| File | Change |
|---|---|
| `lib/widgets/end_practice_button.dart` | Line ~59: `$_totalAnswered` → `$correctAnswers` |

No other files need to change.

---

## Full Diff

```
- Text('Correct: $_totalAnswered'),
+ Text('Correct: $correctAnswers'),
```

---

## Testing & Verification

### Run static analysis and tests

```bash
flutter analyze && flutter test
```

Both must pass with no new errors or warnings.

### Manual test checklist

**Correct count displayed accurately:**
1. Launch the multiple choice quiz.
2. Answer exactly 4 questions: get 3 correct and 1 incorrect (or any known split).
3. Tap the exit icon in the AppBar.
4. **Expected:** The dialog "Progress Summary" section shows:
   - `✅ Correct: 3` (the number answered correctly)
   - `❌ Incorrect: 1`
   - `❓ Unanswered: 124`
5. **Expected:** The three numbers add up to 128 (total questions).

**Zero questions answered (no summary shown):**
1. Launch the quiz, answer no questions.
2. Tap the exit icon.
3. **Expected:** The dialog shows only "Are you sure you want to exit?" with no Progress
   Summary section (existing behaviour — the `if (_totalAnswered > 0)` guard hides it).

---

## Acceptance Criteria

- [ ] The "Correct" row in the End Practice dialog shows the number of correctly-answered
  questions, not the total answered
- [ ] The "Incorrect" and "Unanswered" rows are unchanged
- [ ] The three progress numbers (correct + incorrect + unanswered) sum to `totalItems`
- [ ] `flutter analyze` reports no new errors or warnings
- [ ] `flutter test` passes with no new failures
