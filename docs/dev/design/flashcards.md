# Flashcards Design

The flashcard screen has a simple MVP: cycle through a set of flashcards with the option to flip each card over to see answers to questions. Each flashcard should give a flip animation each time the user taps on it. The flashcards should be presented one at a time, with navigation controls to move to the next or previous card.

## Localization
The flashcards screen supports multiple languages using Flutter's localization framework. All text displayed on the flashcards and related UI elements are localized. See [localization.md](localization.md) for implementation details.

## Storage of Flashcards
Flashcards are stored in a local database using the `sqflite` package. Each flashcard consists of a question and an answer, both of which are localized strings. The database schema includes fields for the flashcard ID, question text, answer text, and language code.

The dataset isn't specific to just flashcards, but rather the entire question set for the US Citizenship Test. Flashcards are generated dynamically from this dataset. The questions/answers dataset can be found here: https://www.uscis.gov/sites/default/files/document/questions-and-answers/2025-Civics-Test-128-Questions-and-Answers.pdf

We can store the dataset in JSON files within the app's assets, structured by language. On app initialization, the relevant JSON file is parsed and the asnwers/questions are created in the local database. This way they can be used by the Flashcards screen as well as other screens like Multiple Choice, Writing, Listening, and Simulated Interview.

DB Table Schema:
```sql
CREATE TABLE question (
    id INTEGER PRIMARY KEY
);

CREATE TABLE question_text (
    id INTEGER PRIMARY KEY,
    question_id INTEGER,
    language_code TEXT,
    question_text TEXT,
    answer_text TEXT,
    FOREIGN KEY (question_id) REFERENCES question(id)
);

CREATE INDEX idx_question_text_language ON question_text(language_code);
```
)
## Additional Features (Future Enhancements)

- **Progress Tracking**: Track which flashcards have been reviewed and which ones need more practice.
- **Categories**: Allow users to organize flashcards into categories or decks.
- **Search Functionality**: Enable users to search for specific flashcards by keywords.
- **Audio Support**: Add audio pronunciations for questions and answers on the flashcards.
- **Spaced Repetition**: Implement a spaced repetition algorithm to optimize learning efficiency.
- **User Customization**: Allow users to create their own flashcards and decks.
- **Shuffle Mode**: Provide an option to shuffle flashcards for varied practice sessions.