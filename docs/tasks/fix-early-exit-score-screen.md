# Task: Show Score Screen on Early Quiz Exit

## Overview

When a user exits the multiple choice quiz early via the "End Practice" button, they are
immediately returned to the main menu with no score summary. A score/summary screen already
exists in the codebase (`_buildSummaryScreen`) but is only shown when the user reaches and
answers the final question. This task adds an early-exit path to that same summary screen.

---

## Parallel Execution Notice

**This task modifies `lib/screens/multiple_choice_screen.dart`.**

Two other tasks running concurrently also modify this file:
- `fix-duplicate-answer-choices` — edits inside `_prepareQuiz()` (distractor fetch block)
- `fix-multi-answer-detection` — edits inside `_prepareQuiz()` (requiresMultiple detection) and `_buildQuizScreen()` (hint text)

Your changes are in **different regions** of the file (state variables, `_restartQuiz`, new `_endEarly` method, `_isQuizComplete` getter, AppBar `onEndPractice` callback, `_buildSummaryScreen`) and do not overlap with either other task. Merge conflicts are unlikely but possible if line numbers shift.

**Rules for this task:**
1. Make only the changes described in this spec. Do not fix, refactor, or reformat any surrounding code.
2. Do not add imports, rename variables, or alter logic outside the described diff.
3. If the file has already been partially edited by another worker, locate your target code by its content (not by line number) and apply only your described change.
4. Run `flutter analyze && flutter test` after your changes and fix any errors introduced by your edits only.

---

## Problem

In `lib/screens/multiple_choice_screen.dart`, the `EndPracticeButton` in the AppBar is wired
as follows (around line 213–218):

```dart
if (!_isQuizComplete)
  EndPracticeButton(
    correctAnswers: _correctAnswers,
    incorrectAnswers: _incorrectAnswers,
    totalItems: _quizQuestions.length,
    onEndPractice: () => Navigator.of(context).pop(),
  ),
```

`onEndPractice` calls `Navigator.of(context).pop()` — this pops straight to the main menu
with no feedback to the user about how they performed.

The summary screen (`_buildSummaryScreen`) is gated by the `_isQuizComplete` getter:

```dart
bool get _isQuizComplete =>
    _currentQuestionIndex == _quizQuestions.length - 1 && _hasAnswered;
```

This is only `true` on the very last question after it has been answered. There is no path
from early exit to this screen.

If the user exits before answering any question, there is nothing meaningful to show — in
that case, the existing `Navigator.of(context).pop()` behaviour (return to menu immediately)
is correct.

---

## Solution

All changes are confined to `lib/screens/multiple_choice_screen.dart`.

### Step 1 — Add `_isEarlyExit` state variable

In `_MultipleChoiceScreenState`, add a new field alongside the existing state variables:

```dart
bool _isEarlyExit = false;
```

Full state variable block after change (for orientation — add only the new line):

```dart
int _currentQuestionIndex = 0;
int _correctAnswers = 0;
int _incorrectAnswers = 0;
bool _isLoading = true;
String? _error;
bool _hasLoadedQuestions = false;
bool _hasAnswered = false;
bool _isEarlyExit = false;          // NEW
Set<int> _selectedAnswerIndices = {};
```

### Step 2 — Reset `_isEarlyExit` in `_restartQuiz()`

The existing `_restartQuiz()` resets all other state. Add the reset here too:

**Before:**
```dart
void _restartQuiz() {
  setState(() {
    _currentQuestionIndex = 0;
    _correctAnswers = 0;
    _incorrectAnswers = 0;
    _hasAnswered = false;
    _selectedAnswerIndices.clear();
  });
  _prepareQuiz();
}
```

**After:**
```dart
void _restartQuiz() {
  setState(() {
    _currentQuestionIndex = 0;
    _correctAnswers = 0;
    _incorrectAnswers = 0;
    _hasAnswered = false;
    _isEarlyExit = false;           // NEW
    _selectedAnswerIndices.clear();
  });
  _prepareQuiz();
}
```

### Step 3 — Add `_endEarly()` method

Add this new private method anywhere among the other action methods (`_submitAnswer`,
`_nextQuestion`, `_restartQuiz`):

```dart
void _endEarly() {
  if (_correctAnswers + _incorrectAnswers == 0) {
    // No questions answered — nothing to show, just leave.
    Navigator.of(context).pop();
    return;
  }
  setState(() {
    _isEarlyExit = true;
  });
}
```

### Step 4 — Update `_isQuizComplete` getter

**Before:**
```dart
bool get _isQuizComplete =>
    _currentQuestionIndex == _quizQuestions.length - 1 && _hasAnswered;
```

**After:**
```dart
bool get _isQuizComplete =>
    (_currentQuestionIndex == _quizQuestions.length - 1 && _hasAnswered) ||
    _isEarlyExit;
```

Note: `_endEarly()` already guards against zero-answered-questions before setting
`_isEarlyExit = true`, so `_isQuizComplete` becoming `true` via `_isEarlyExit` implies
at least one question was answered.

### Step 5 — Wire `onEndPractice` to `_endEarly()`

**Before:**
```dart
onEndPractice: () => Navigator.of(context).pop(),
```

**After:**
```dart
onEndPractice: _endEarly,
```

### Step 6 — Update `_buildSummaryScreen` for early-exit context

The summary screen currently always shows "Quiz Complete!" and scores over the total number
of questions. When the user exits early, the title and denominator should reflect that only
a subset of questions were answered.

Compute answered count and derive percentage from it:

**Before (inside `_buildSummaryScreen`):**
```dart
Widget _buildSummaryScreen(AppLocalizations l10n) {
  final percentage = (_correctAnswers / _quizQuestions.length * 100).round();
  // ...
      Text(
        '$_correctAnswers / ${_quizQuestions.length}',
        // ...
      ),
      Text(
        '$percentage%',
        // ...
      ),
  // ...
      Text(
        'Quiz Complete!',
        // ...
      ),
```

**After:**
```dart
Widget _buildSummaryScreen(AppLocalizations l10n) {
  final answeredCount = _correctAnswers + _incorrectAnswers;
  final denominator = _isEarlyExit ? answeredCount : _quizQuestions.length;
  final percentage = denominator > 0
      ? (_correctAnswers / denominator * 100).round()
      : 0;
  // ...
      Text(
        _isEarlyExit ? 'Practice Ended Early' : 'Quiz Complete!',
        // ...
      ),
  // ...
      Text(
        '$_correctAnswers / $denominator',
        // ...
      ),
      Text(
        '$percentage%',
        // ...
      ),
```

The rest of `_buildSummaryScreen` (trophy icon threshold, correct/incorrect counts, "Try
Again" and "Back to Menu" buttons) is unchanged.

---

## Affected Files

| File | Change |
|---|---|
| `lib/screens/multiple_choice_screen.dart` | Add `_isEarlyExit` field, `_endEarly()` method, update getter, wire callback, update summary screen copy/denominator |

No other files need to change.

---

## Full Diff Summary

```
_MultipleChoiceScreenState:
  + bool _isEarlyExit = false;

_restartQuiz():
  + _isEarlyExit = false;

+ void _endEarly() {
+   if (_correctAnswers + _incorrectAnswers == 0) {
+     Navigator.of(context).pop();
+     return;
+   }
+   setState(() { _isEarlyExit = true; });
+ }

_isQuizComplete getter:
  - _currentQuestionIndex == _quizQuestions.length - 1 && _hasAnswered
  + (_currentQuestionIndex == _quizQuestions.length - 1 && _hasAnswered) || _isEarlyExit

EndPracticeButton onEndPractice:
  - () => Navigator.of(context).pop()
  + _endEarly

_buildSummaryScreen():
  + final answeredCount = _correctAnswers + _incorrectAnswers;
  + final denominator = _isEarlyExit ? answeredCount : _quizQuestions.length;
  - final percentage = (_correctAnswers / _quizQuestions.length * 100).round();
  + final percentage = denominator > 0 ? (_correctAnswers / denominator * 100).round() : 0;
  - 'Quiz Complete!'
  + _isEarlyExit ? 'Practice Ended Early' : 'Quiz Complete!'
  - '$_correctAnswers / ${_quizQuestions.length}'
  + '$_correctAnswers / $denominator'
```

---

## Testing & Verification

### Run static analysis and tests

```bash
flutter analyze && flutter test
```

Both must pass with no new errors or warnings.

### Manual test checklist

**Early exit with no questions answered:**
1. Launch the multiple choice quiz.
2. Wait for questions to load.
3. Without selecting any answer, tap the exit icon in the AppBar.
4. Confirm the dialog — tap "End Practice".
5. **Expected:** App navigates directly to the main menu. No summary screen is shown.

**Early exit after answering some questions:**
1. Launch the multiple choice quiz.
2. Answer 3 questions (mix of correct and incorrect).
3. Tap the exit icon — tap "End Practice".
4. **Expected:** The summary screen appears with title "Practice Ended Early".
5. **Expected:** Score shows `X / 3` (questions answered, not 128).
6. **Expected:** Percentage is calculated from those 3 questions.
7. **Expected:** Correct and incorrect counts are accurate.
8. **Expected:** "Try Again" restarts from question 1 with score reset.
9. **Expected:** "Back to Menu" returns to main menu.

**Normal quiz completion (regression):**
1. Complete the full quiz (or fast-forward by answering through questions).
2. After the final question, tap "View Results".
3. **Expected:** Summary screen shows "Quiz Complete!" (not "Practice Ended Early").
4. **Expected:** Score shows `X / 128`.

**AppBar button hidden on summary screen:**
1. Reach the summary screen (via either path).
2. **Expected:** The exit icon is NOT shown in the AppBar (existing `if (!_isQuizComplete)` guard).

---

## Acceptance Criteria

- [ ] Exiting early after zero answers pops to main menu with no summary screen
- [ ] Exiting early after ≥1 answer shows the summary screen
- [ ] Summary title reads "Practice Ended Early" on early exit
- [ ] Summary title reads "Quiz Complete!" on natural completion
- [ ] Score denominator reflects answered questions on early exit, total questions on completion
- [ ] Percentage is calculated from the correct denominator
- [ ] "Try Again" resets all state including `_isEarlyExit` and restarts the quiz
- [ ] "Back to Menu" navigates to main menu from the summary screen
- [ ] AppBar exit button is hidden while summary screen is showing
- [ ] `flutter analyze` reports no new errors or warnings
- [ ] `flutter test` passes with no new failures
