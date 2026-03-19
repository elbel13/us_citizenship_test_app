# Task: Fix Multi-Answer Question Detection

## Overview

Three questions in the dataset ask users to name three or five things, but the quiz treats
them as single-answer questions because the detection logic only recognises the word "two".
This task expands the detection to cover "three", "five", and similar phrasings, and updates
the hint text shown to the user so it is accurate for any multi-answer question.

---

## Parallel Execution Notice

**This task modifies `lib/screens/multiple_choice_screen.dart`.**

Two other tasks running concurrently also modify this file:
- `fix-early-exit-score-screen` — edits state variables, `_restartQuiz`, adds `_endEarly`, updates `_isQuizComplete` getter and `_buildSummaryScreen`
- `fix-duplicate-answer-choices` — edits the distractor-fetch block inside `_prepareQuiz()`

Your changes are:
1. The `requiresMultiple` detection block in `_prepareQuiz()` — approximately 20 lines before the distractor-fetch block that `fix-duplicate-answer-choices` touches. These are the two highest-conflict tasks because both are inside `_prepareQuiz()`.
2. The hint text string in `_buildQuizScreen()` — in a completely different method from all other tasks.

**Rules for this task:**
1. Make only the changes described in this spec. Do not fix, refactor, or reformat any surrounding code.
2. Locate the `requiresMultiple` detection block by its content (the `contains('two ')` lines), not by line number.
3. Do not touch the `numWrong` / `getWrongAnswersByCategories` lines — those belong to `fix-duplicate-answer-choices`.
4. If the file has already been partially edited by another worker, apply only your described changes.
5. Run `flutter analyze && flutter test` after your changes and fix any errors introduced by your edits only.

---

## Problem

In `lib/screens/multiple_choice_screen.dart`, `_prepareQuiz()` determines whether a question
requires multiple selections with this logic (approximately lines 74–78):

```dart
final questionTextLower = question.questionText.toLowerCase();
final requiresMultiple =
    questionTextLower.contains('two ') ||
    questionTextLower.contains('name two') ||
    questionTextLower.contains('what are two');
```

This only catches questions containing the word "two". The following questions in
`assets/questions_en_categorized.json` are not caught and are incorrectly treated as
single-answer:

| Q# | Question text | Correct answers available |
|----|--------------|--------------------------|
| 65 | "What are **three** rights of everyone living in the United States?" | 6 |
| 81 | "There were 13 original states. Name **five**." | 13 |
| 126 | "Name **three** national U.S. holidays." | 11 |

For these questions:
- Only one answer choice is shown as correct (single-answer path).
- No checkbox UI is shown to the user.
- The question text clearly asks for multiple answers, creating a confusing experience.

A secondary issue: when `requiresMultiple` IS true, the hint text shown beneath the question
reads "Select at least 2 correct answers". For questions asking for 3 (Q65, Q126) or 5
(Q81), the quiz always shows exactly `min(3, answers.length)` correct answers in the choice
list — meaning the user needs to select all shown correct answers. The hint "at least 2" is
misleading for these questions.

---

## Solution

All changes are confined to `lib/screens/multiple_choice_screen.dart`.

### Change 1 — Expand `requiresMultiple` detection

Replace the existing detection block (approximately lines 74–78):

**Before:**
```dart
final questionTextLower = question.questionText.toLowerCase();
final requiresMultiple =
    questionTextLower.contains('two ') ||
    questionTextLower.contains('name two') ||
    questionTextLower.contains('what are two');
```

**After:**
```dart
final questionTextLower = question.questionText.toLowerCase();
final requiresMultiple = RegExp(
  r'name (two|three|four|five|six|seven|eight|nine|ten|\d+)'
  r'|what are (two|three|four|five|six|seven|eight|nine|ten|\d+)'
  r'|name five'
  r'|two or more',
).hasMatch(questionTextLower);
```

This regex matches:
- "name two", "name three", "name five", "name ten", "name 13", etc.
- "what are two", "what are three", etc.
- "two or more" (future-proofing)

The three currently-broken questions all match:
- Q65 "What are three rights..." → matches `what are three`
- Q81 "Name five." → matches `name five`
- Q126 "Name three national..." → matches `name three`

### Change 2 — Update hint text

In `_buildQuizScreen()`, locate the hint text widget shown when `requiresMultiple` is true
(approximately lines 265–277):

**Before:**
```dart
if (currentQuestion.requiresMultiple && !_hasAnswered)
  Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16.0),
    child: Text(
      'Select at least 2 correct answers',
      style: TextStyle(
        fontSize: 14,
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.w500,
      ),
      textAlign: TextAlign.center,
    ),
  ),
```

**After:**
```dart
if (currentQuestion.requiresMultiple && !_hasAnswered)
  Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16.0),
    child: Text(
      'Select all correct answers',
      style: TextStyle(
        fontSize: 14,
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.w500,
      ),
      textAlign: TextAlign.center,
    ),
  ),
```

"Select all correct answers" is accurate regardless of whether 2 or 3 correct answers are
shown, because the quiz always surfaces exactly `min(3, answers.length)` correct answers in
the choice list and the user must select all of them to score the question correct.

### No change needed to scoring logic

The existing scoring for `requiresMultiple` questions is:

```dart
final isCorrect = currentQuestion.requiresMultiple
    ? (selectedCorrect >= 2 && selectedWrong == 0)
    : (selectedCorrect == 1 && selectedWrong == 0);
```

`selectedCorrect >= 2` is already correct for 2-answer questions. For 3-answer questions
(Q65, Q126) where 3 correct choices are shown, the user must pick all 3 to have
`selectedWrong == 0`, so effectively they need `selectedCorrect == 3`. The `>= 2` threshold
still accepts this. No scoring change is needed.

### No change needed to answer count logic

```dart
final numCorrect = min(3, question.answers.length);
```

This already caps at 3 correct answers shown regardless of how many the question asks for.
For Q81 (asks 5, has 13 answers), 3 correct answers will be shown — which is consistent with
the 4-choice quiz format (3 correct + 1 wrong). This is an acceptable simplification.

---

## Affected Files

| File | Change |
|---|---|
| `lib/screens/multiple_choice_screen.dart` | Expand `requiresMultiple` regex; update hint text string |

No other files need to change.

---

## Full Diff

```
// _prepareQuiz() — requiresMultiple detection:

- final questionTextLower = question.questionText.toLowerCase();
- final requiresMultiple =
-     questionTextLower.contains('two ') ||
-     questionTextLower.contains('name two') ||
-     questionTextLower.contains('what are two');

+ final questionTextLower = question.questionText.toLowerCase();
+ final requiresMultiple = RegExp(
+   r'name (two|three|four|five|six|seven|eight|nine|ten|\d+)'
+   r'|what are (two|three|four|five|six|seven|eight|nine|ten|\d+)'
+   r'|name five'
+   r'|two or more',
+ ).hasMatch(questionTextLower);


// _buildQuizScreen() — hint text:

- 'Select at least 2 correct answers'
+ 'Select all correct answers'
```

---

## Testing & Verification

### Run static analysis and tests

```bash
flutter analyze && flutter test
```

Both must pass with no new errors or warnings.

### Manual test checklist

**Q65 — "What are three rights of everyone living in the United States?"**
1. Play through the quiz until this question appears.
2. **Expected:** Checkbox UI is shown (square check boxes beside each answer).
3. **Expected:** Hint text reads "Select all correct answers".
4. **Expected:** Multiple answers are highlighted green after submission.
5. **Expected:** Selecting only 1 answer does not allow submission (Submit button absent
   until ≥2 selected — existing behaviour from `requiresMultiple` guard).

**Q81 — "There were 13 original states. Name five."**
1. Play through until this question appears.
2. **Expected:** Same checkbox/multi-select behaviour as above.
3. **Expected:** 3 correct state names shown as correct after answering.

**Q126 — "Name three national U.S. holidays."**
1. Play through until this question appears.
2. **Expected:** Same checkbox/multi-select behaviour.

**Existing two-answer questions (regression):**
1. Find a question containing "two" (e.g. Q10 "Name two important ideas...", Q48 "What are
   two Cabinet-level positions?", Q67 "Name two promises...").
2. **Expected:** Still treated as multi-select (no regression).

**Hint text on two-answer questions:**
1. On any multi-select question, confirm hint reads "Select all correct answers" (not the
   old "Select at least 2 correct answers").

---

## Acceptance Criteria

- [ ] Q65, Q81, and Q126 are rendered as multi-select questions with checkbox UI
- [ ] Questions containing "two" continue to be treated as multi-select (no regression)
- [ ] Hint text reads "Select all correct answers" on all multi-select questions
- [ ] Scoring logic is unchanged and still functions correctly
- [ ] `flutter analyze` reports no new errors or warnings
- [ ] `flutter test` passes with no new failures
