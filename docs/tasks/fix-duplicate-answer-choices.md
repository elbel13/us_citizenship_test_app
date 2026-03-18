# Task: Fix Duplicate Answer Choices in Multiple Choice Quiz

## Overview

The multiple choice quiz occasionally displays the same answer text twice in a single
question's answer choices — once as the correct answer and again as a distractor. This makes
the question unanswerable correctly and looks like a data bug. The fix is a small change to
the distractor-filtering logic in `_prepareQuiz()`.

---

## Parallel Execution Notice

**This task modifies `lib/screens/multiple_choice_screen.dart`.**

Two other tasks running concurrently also modify this file:
- `fix-early-exit-score-screen` — edits state variables, `_restartQuiz`, adds `_endEarly`, updates `_isQuizComplete` getter and `_buildSummaryScreen`
- `fix-multi-answer-detection` — edits `requiresMultiple` detection block inside `_prepareQuiz()` and hint text in `_buildQuizScreen()`

Your change is inside `_prepareQuiz()` in the distractor-fetch block (the `numWrong` / `incorrectAnswers` lines). The `fix-multi-answer-detection` task also edits `_prepareQuiz()` but in a different sub-block (the `requiresMultiple` detection lines, approximately 20 lines earlier). These are the two highest-conflict tasks — both touch `_prepareQuiz()`.

**Rules for this task:**
1. Make only the changes described in this spec. Do not fix, refactor, or reformat any surrounding code.
2. Locate your target code by its content (the `numWrong` / `getWrongAnswersByCategories` block), not by line number.
3. Do not touch the `requiresMultiple` detection lines — those belong to `fix-multi-answer-detection`.
4. If the file has already been partially edited by another worker, apply only your described change.
5. Run `flutter analyze && flutter test` after your changes and fix any errors introduced by your edits only.

---

## Problem

In `lib/screens/multiple_choice_screen.dart`, `_prepareQuiz()` builds answer choices for
each question in two steps:

1. Select the correct answer(s) from `question.answers`.
2. Fetch wrong (distractor) answers from the database via `getWrongAnswersByCategories`.

The database query for distractors is:

```sql
SELECT DISTINCT a.answer_text
FROM answer a
JOIN question_text qt ON a.question_text_id = qt.id
WHERE qt.question_id != ?
  AND a.category_id IN (...)
ORDER BY RANDOM()
LIMIT ?
```

The `question_id != ?` clause excludes answers that belong to the *current question*, but
it does **not** exclude answers whose text is identical to the randomly-chosen correct
answer(s). If the same answer string exists in another question's answer set within the same
category, the query can return it as a distractor, causing it to appear twice in `allAnswers`.

**Concrete example:**
- Q93: "The Civil War had many important events. Name one."
- Correct answer picked: "(Battle of) Gettysburg" (category: EVENT)
- The distractor query searches for EVENT answers from other questions.
- If another question also has "(Battle of) Gettysburg" as an answer (possible because some
  answer strings are reused across questions), it is returned as a distractor.
- Result: "(Battle of) Gettysburg" appears twice in the 4 answer choices.

This also manifests when the `DISTINCT` on `answer_text` doesn't catch it because the
duplicate comes from a *different* question row.

---

## Solution

After fetching the raw distractor list, filter out any strings that are already present in
`correctAnswers`. To compensate for the filtered-out items, request extra candidates upfront.

All changes are confined to `lib/screens/multiple_choice_screen.dart`, inside `_prepareQuiz()`.

### The change

Locate this block (approximately lines 96–99):

```dart
// Get wrong answers from the same categories
final numWrong = requiresMultiple ? 2 : 3;
final incorrectAnswers = await _databaseService
    .getWrongAnswersByCategories(question.id, categoryIds, numWrong);
```

Replace it with:

```dart
// Get wrong answers from the same categories.
// Request extra candidates to account for any that duplicate correct answers.
final numWrong = requiresMultiple ? 2 : 3;
final rawIncorrect = await _databaseService.getWrongAnswersByCategories(
  question.id,
  categoryIds,
  numWrong + correctAnswers.length,
);
final incorrectAnswers = rawIncorrect
    .where((a) => !correctAnswers.contains(a))
    .take(numWrong)
    .toList();
```

### Why `numWrong + correctAnswers.length`?

In the worst case every one of the `correctAnswers` strings also appears in the distractor
pool, so we need `numWrong + correctAnswers.length` candidates to guarantee `numWrong`
remain after filtering. For a single-answer question `correctAnswers.length == 1`, so we
fetch at most 4 candidates instead of 3. For a multi-answer question with 3 correct answers
we fetch at most 5 candidates instead of 2. The database query still uses `LIMIT` so this is
cheap.

### Edge case: fewer distractors than needed

If the database genuinely cannot provide `numWrong` distinct non-duplicate distractors (e.g.
a category only has a handful of answers), `incorrectAnswers` may be shorter than `numWrong`.
This is acceptable — the quiz already handles varying answer counts, and this scenario is
rare with the current dataset. Do **not** add any extra error-handling for this case.

---

## Affected Files

| File | Change |
|---|---|
| `lib/screens/multiple_choice_screen.dart` | Replace 2-line distractor fetch with filtered version in `_prepareQuiz()` |

No other files need to change.

---

## Full Diff

```
// inside _prepareQuiz(), replacing the distractor fetch block:

- final numWrong = requiresMultiple ? 2 : 3;
- final incorrectAnswers = await _databaseService
-     .getWrongAnswersByCategories(question.id, categoryIds, numWrong);

+ final numWrong = requiresMultiple ? 2 : 3;
+ final rawIncorrect = await _databaseService.getWrongAnswersByCategories(
+   question.id,
+   categoryIds,
+   numWrong + correctAnswers.length,
+ );
+ final incorrectAnswers = rawIncorrect
+     .where((a) => !correctAnswers.contains(a))
+     .take(numWrong)
+     .toList();
```

---

## Testing & Verification

### Run static analysis and tests

```bash
flutter analyze && flutter test
```

Both must pass with no new errors or warnings.

### Manual test checklist

**No duplicates visible:**
1. Launch the multiple choice quiz.
2. Play through at least 20 questions, inspecting the answer choices for each.
3. **Expected:** No question shows the same answer text twice.

**Targeted regression — Q93 (Civil War events):**
1. Play the quiz until question "The Civil War had many important events. Name one." appears.
2. **Expected:** All 4 answer choices are distinct strings.
3. **Expected:** "(Battle of) Gettysburg" (or whichever Civil War event is picked as
   correct) does not appear twice.

**Correct answers still present:**
1. For any question, after answering, verify the green-highlighted correct answer was one of
   the visible choices before you answered.
2. **Expected:** The correct answer is always present in the choice list.

---

## Acceptance Criteria

- [ ] No question in the quiz displays the same answer text more than once
- [ ] Correct answers are always included in the displayed choices
- [ ] The number of answer choices per question is unchanged (3–5 depending on question type)
- [ ] `flutter analyze` reports no new errors or warnings
- [ ] `flutter test` passes with no new failures
