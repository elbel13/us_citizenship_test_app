# Database Schema

## Tables

### answer_category
Stores the category types for answers
```sql
CREATE TABLE answer_category (
    id INTEGER PRIMARY KEY,
    category_name TEXT NOT NULL
);

CREATE INDEX idx_answer_category_name ON answer_category(category_name);
```

**Initial Categories:**
1. DOCUMENT
2. FOUNDING_FATHER
3. PRESIDENT
4. HISTORICAL_FIGURE
5. GOVERNMENT_OFFICIAL
6. NUMBER
7. DATE
8. WAR
9. GOVERNMENT_BRANCH
10. GOVERNMENT_POWER
11. RIGHTS
12. CIVIC_DUTY
13. POLITICAL_CONCEPT
14. PLACE
15. NATIVE_TRIBE
16. EVENT
17. INNOVATION
18. NATIONAL_SYMBOL

### question
Base question table (language-independent)
```sql
CREATE TABLE question (
    id INTEGER PRIMARY KEY
);
```

### question_text
Language-specific question text
```sql
CREATE TABLE question_text (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    question_id INTEGER NOT NULL,
    language_code TEXT NOT NULL,
    question_text TEXT NOT NULL,
    FOREIGN KEY (question_id) REFERENCES question(id)
);

CREATE INDEX idx_question_text_language ON question_text(language_code);
CREATE INDEX idx_question_text_question ON question_text(question_id);
```

### answer
Individual answers with categories
```sql
CREATE TABLE answer (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    question_text_id INTEGER NOT NULL,
    answer_text TEXT NOT NULL,
    category_id INTEGER NOT NULL,
    FOREIGN KEY (question_text_id) REFERENCES question_text(id),
    FOREIGN KEY (category_id) REFERENCES answer_category(id)
);

CREATE INDEX idx_answer_question_text ON answer(question_text_id);
CREATE INDEX idx_answer_category ON answer(category_id);
```

## Relationships

- `question` (1) -> (many) `question_text`
- `question_text` (1) -> (many) `answer`
- `answer_category` (1) -> (many) `answer`

## Migration from Current Schema

Current schema has `answer_text` on `question_text` table. Need to:
1. Drop and recreate database (acceptable for MVP - no user data)
2. Parse multi-line answers into separate answer records
3. Assign category to each answer
