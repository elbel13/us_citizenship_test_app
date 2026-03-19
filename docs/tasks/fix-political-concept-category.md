# Task: Split POLITICAL_CONCEPT into More Specific Answer Categories

## Overview

The `POLITICAL_CONCEPT` answer category (ID 13) contains 30+ answers spanning wildly
different semantic domains. Because the multiple choice distractor algorithm pulls wrong
answers from the same category as the correct answer, questions in this category receive
absurd distractors. For example, "Why did the US enter the Korean War?" (correct: "To stop
the spread of communism", category POLITICAL_CONCEPT) gets distractors like "Equality" and
"No one is above the law." — both technically POLITICAL_CONCEPT but contextually nonsensical.

This task splits POLITICAL_CONCEPT into four more focused categories, re-tags affected
answers in the JSON data file, adds the new categories to the database service, and bumps
the database version.

---

## Parallel Execution Notice

**This task modifies `assets/questions_en_categorized.json` and `lib/services/database_service.dart`.**

No other concurrent task touches either of these files. This task is fully independent.

**Rules for this task:**
1. Make only the changes described in this spec. Re-tag exactly the 13 specified answers; do not alter any other answers, questions, or ordering in the JSON.
2. Add exactly the 3 new entries to `categoryIds` in `database_service.dart`; do not reformat or reorder existing entries.
3. Bump the DB version from 5 to 6 and update the upgrade condition from `< 5` to `< 6`; change nothing else in the upgrade handler.
4. Run `flutter analyze && flutter test` after your changes and fix any errors introduced by your edits only.

---

## Problem — POLITICAL_CONCEPT answers in the current dataset

The following is every answer currently tagged `POLITICAL_CONCEPT` in
`assets/questions_en_categorized.json`, grouped by the semantic domain they actually belong
to:

**Government structure / founding principles** (stay as POLITICAL_CONCEPT):
- Q1: "Republic", "Constitution-based federal republic", "Representative democracy"
- Q4: "Self-government", "Popular sovereignty", "Consent of the governed",
  "People should govern themselves", "(Example of) social contract"
- Q10: "Equality", "Liberty", "Social contract", "Natural rights", "Limited government",
  "Self-government"
- Q15: "So one part does not become too powerful", "Checks and balances",
  "Separation of powers"
- Q26: "To more closely follow public opinion"
- Q28: "Equal representation (for small states)"
- Q37: "To keep the president from becoming too powerful"
- Q49: "It provides a compromise between the popular election of the president and
  congressional selection."
- Q73: "Freedom", "Political liberty", "Economic opportunity"
- Q124: "Out of many, one", "We all become one"

**Rule-of-law statements** (move to new RULE_OF_LAW category):
- Q13: "Everyone must follow the law.", "Leaders must obey the law.",
  "Government must obey the law.", "No one is above the law."
- Q56: "To be independent (of politics)", "To limit outside (political) influence"
- Q60: "(It states that the) powers not given to the federal government belong to the
  states or to the people."

**Political ideologies** (move to new POLITICAL_IDEOLOGY category):
- Q12: "Capitalism", "Free market economy"
- Q109: "Communism"
- Q110: "To stop the spread of communism"
- Q111: "To stop the spread of communism"

**Population / apportionment reasons** (move to new POPULATION_REASON category):
- Q35: "(Because of) the state's population", "(Because) they have more people",
  "(Because) some states have more people"

---

## Solution

### New categories

| ID | Name | Semantic domain |
|----|------|----------------|
| 19 | `RULE_OF_LAW` | Statements about law applying to all, judicial independence |
| 20 | `POLITICAL_IDEOLOGY` | Named ideologies (capitalism, communism) and motivations rooted in them |
| 21 | `POPULATION_REASON` | Explanations based on population size or distribution |

`POLITICAL_CONCEPT` (ID 13) is retained and kept for government structure, founding
principles, and abstract ideals.

---

## Change 1 — `assets/questions_en_categorized.json`

Re-tag the following answers. Every other answer in the file is unchanged.

### Q12 — "What is the economic system of the United States?"
```json
// Before:
{"text": "Capitalism", "category": "POLITICAL_CONCEPT"},
{"text": "Free market economy", "category": "POLITICAL_CONCEPT"}

// After:
{"text": "Capitalism", "category": "POLITICAL_IDEOLOGY"},
{"text": "Free market economy", "category": "POLITICAL_IDEOLOGY"}
```

### Q13 — "What is the rule of law?"
```json
// Before:
{"text": "Everyone must follow the law.", "category": "POLITICAL_CONCEPT"},
{"text": "Leaders must obey the law.", "category": "POLITICAL_CONCEPT"},
{"text": "Government must obey the law.", "category": "POLITICAL_CONCEPT"},
{"text": "No one is above the law.", "category": "POLITICAL_CONCEPT"}

// After:
{"text": "Everyone must follow the law.", "category": "RULE_OF_LAW"},
{"text": "Leaders must obey the law.", "category": "RULE_OF_LAW"},
{"text": "Government must obey the law.", "category": "RULE_OF_LAW"},
{"text": "No one is above the law.", "category": "RULE_OF_LAW"}
```

### Q35 — "Some states have more representatives than other states. Why?"
```json
// Before:
{"text": "(Because of) the state's population", "category": "POLITICAL_CONCEPT"},
{"text": "(Because) they have more people", "category": "POLITICAL_CONCEPT"},
{"text": "(Because) some states have more people", "category": "POLITICAL_CONCEPT"}

// After:
{"text": "(Because of) the state's population", "category": "POPULATION_REASON"},
{"text": "(Because) they have more people", "category": "POPULATION_REASON"},
{"text": "(Because) some states have more people", "category": "POPULATION_REASON"}
```

### Q56 — "Supreme Court justices serve for life. Why?"
```json
// Before:
{"text": "To be independent (of politics)", "category": "POLITICAL_CONCEPT"},
{"text": "To limit outside (political) influence", "category": "POLITICAL_CONCEPT"}

// After:
{"text": "To be independent (of politics)", "category": "RULE_OF_LAW"},
{"text": "To limit outside (political) influence", "category": "RULE_OF_LAW"}
```

### Q60 — "What is the purpose of the 10th Amendment?"
```json
// Before:
{"text": "(It states that the) powers not given to the federal government belong to the states or to the people.", "category": "POLITICAL_CONCEPT"}

// After:
{"text": "(It states that the) powers not given to the federal government belong to the states or to the people.", "category": "RULE_OF_LAW"}
```

### Q109 — "During the Cold War, what was one main concern of the United States?"
```json
// Before:
{"text": "Communism", "category": "POLITICAL_CONCEPT"},

// After:
{"text": "Communism", "category": "POLITICAL_IDEOLOGY"},
```

### Q110 — "Why did the United States enter the Korean War?"
```json
// Before:
{"text": "To stop the spread of communism", "category": "POLITICAL_CONCEPT"}

// After:
{"text": "To stop the spread of communism", "category": "POLITICAL_IDEOLOGY"}
```

### Q111 — "Why did the United States enter the Vietnam War?"
```json
// Before:
{"text": "To stop the spread of communism", "category": "POLITICAL_CONCEPT"}

// After:
{"text": "To stop the spread of communism", "category": "POLITICAL_IDEOLOGY"}
```

---

## Change 2 — `lib/services/database_service.dart`

### 2a — Add new categories to `categoryIds` map

Locate the `categoryIds` static const map (approximately lines 17–36):

**Before:**
```dart
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
```

**After:**
```dart
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
  'RULE_OF_LAW': 19,
  'POLITICAL_IDEOLOGY': 20,
  'POPULATION_REASON': 21,
};
```

The `_createDatabase` method seeds `answer_category` rows by iterating over `categoryIds`,
so no additional SQL changes are needed to insert the new category rows.

### 2b — Bump database version and update upgrade handler

**Locate the `_initDatabase` method. Find the `openDatabase` call.**

**Before:**
```dart
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
```

**After:**
```dart
return await openDatabase(
  path,
  version: 6, // Bumped for RULE_OF_LAW, POLITICAL_IDEOLOGY, POPULATION_REASON categories
  onCreate: _createDatabase,
  onUpgrade: (db, oldVersion, newVersion) async {
    // For now, just drop and recreate (no user data to preserve)
    if (oldVersion < 6) {
      await db.execute('DROP TABLE IF EXISTS answer');
      await db.execute('DROP TABLE IF EXISTS question_text');
      await db.execute('DROP TABLE IF EXISTS question');
      await db.execute('DROP TABLE IF EXISTS answer_category');
      await db.execute('DROP TABLE IF EXISTS reading_sentence');
      await _createDatabase(db, newVersion);
    }
  },
```

The only changes are: `version: 5` → `version: 6` and `oldVersion < 5` → `oldVersion < 6`.

---

## Affected Files

| File | Change |
|---|---|
| `assets/questions_en_categorized.json` | Re-tag 13 answers across 8 questions |
| `lib/services/database_service.dart` | Add 3 entries to `categoryIds`; bump DB version 5→6; update upgrade condition |

---

## Testing & Verification

### Run static analysis and tests

```bash
flutter analyze && flutter test
```

Both must pass with no new errors or warnings.

### Manual test checklist

**Distractor quality — rule-of-law questions:**
1. Play through until "What is the rule of law?" appears.
2. The correct answer will be one of the rule-of-law statements.
3. **Expected:** All 3 distractors are also rule-of-law statements (e.g. "Government must
   obey the law.") — NOT "Communism", "Equality", or state-population reasons.

**Distractor quality — ideology questions:**
1. Play through until "Why did the United States enter the Korean War?" appears.
2. The correct answer is "To stop the spread of communism".
3. **Expected:** Distractors are also POLITICAL_IDEOLOGY answers — either "Capitalism",
   "Free market economy", or "Communism" — NOT "Equality", "No one is above the law.", etc.

**Distractor quality — population questions:**
1. Play through until "Some states have more representatives than other states. Why?" appears.
2. **Expected:** Distractors are other POPULATION_REASON answers or, if the pool is small,
   other answers. Crucially: "Communism" and "No one is above the law." should NOT appear.

**Database upgrade:**
1. If testing on a device/emulator that already has the app installed with DB version 5,
   launch the app.
2. **Expected:** App opens without errors (upgrade handler drops and recreates the DB).
3. **Expected:** Questions load normally after the upgrade.

**No regression on existing categories:**
1. Play through a variety of questions (war, document, government official, etc.).
2. **Expected:** Distractors for non-POLITICAL_CONCEPT questions are unaffected and still
   sensible.

---

## Acceptance Criteria

- [ ] `RULE_OF_LAW` (ID 19), `POLITICAL_IDEOLOGY` (ID 20), `POPULATION_REASON` (ID 21)
  are present in `DatabaseService.categoryIds`
- [ ] All 13 re-tagged answers in the JSON use their new category names exactly as specified
- [ ] No other answers in the JSON are changed
- [ ] Database version is 6
- [ ] Upgrade from version 5 drops and recreates all tables without errors
- [ ] Distractors for Q13 (rule of law), Q35 (representatives), Q56 (justices), Q110/Q111
  (Korean/Vietnam War), Q109 (Cold War) are semantically sensible
- [ ] `flutter analyze` reports no new errors or warnings
- [ ] `flutter test` passes with no new failures
