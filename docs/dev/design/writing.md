# Writing Practice Implementation

## Overview
The Writing Practice screen helps users prepare for the English writing portion of the US Citizenship Test. During the actual test, applicants are read up to 3 sentences and must write 1 out of 3 correctly to pass. This screen simulates that experience by playing audio of sentences and having users type what they hear.

## Test Requirements (USCIS)
- Applicants are read up to 3 sentences
- Must write 1 out of 3 sentences correctly to demonstrate writing ability
- Sentences use specific vocabulary focused on civics and history
- Sentences must be dictated in a natural speaking voice at normal speed
- Applicants can ask for repetition as needed

## Technical Approach

### Audio Playback
Use Flutter's text-to-speech (TTS) package to read sentences aloud:
- **Package**: `flutter_tts` - Cross-platform TTS support
- **Configuration**: 
  - Language: en-US
  - Speech rate: Normal (1.0)
  - Pitch: Normal (1.0)
  - Allow users to replay the sentence
  - Show visual indicator when speaking

### Text Input & Evaluation
- User types what they hear in a text field
- Evaluate using the same `ReadingEvaluator` service (Levenshtein distance)
- 80% similarity threshold for passing (same as reading)
- Provide immediate feedback after submission

### Data Storage
- Store writing sentences in SQLite database
- Sentences created from USCIS writing vocabulary
- Database table: `writing_sentence`
- Populate from JSON asset file on first run

## USCIS Writing Vocabulary

### People
Adams, Lincoln, Washington

### Civics
American Indians, capital, citizens, Civil War, Congress, Father of Our Country, flag, free, freedom of speech, President, right, Senators, state/states, White House

### Places
Alaska, California, Canada, Delaware, Mexico, New York City, United States, Washington, Washington, D.C.

### Months
February, May, June, July, September, October, November

### Holidays
Presidents' Day, Memorial Day, Flag Day, Independence Day, Labor Day, Columbus Day, Thanksgiving

### Verbs
can, come, elect, have/has, is/was/be, lives/lived, meets, pay, vote, want

### Other (Function)
and, during, for, here, in, of, on, to, the, we

### Other (Content)
blue, dollar bill, fifty/50, first, largest, most, north, one, one hundred/100, people, red, second, south, taxes, white

## Data Model

### WritingSentence
```dart
class WritingSentence {
  final String id;
  final String text;
  final List<String> vocabularyWords;
  final String category;
  final int difficulty;
}
```

### Database Schema
```sql
CREATE TABLE writing_sentence (
  id TEXT PRIMARY KEY,
  text TEXT NOT NULL,
  vocabulary_words TEXT NOT NULL,  -- JSON array
  category TEXT NOT NULL,
  difficulty INTEGER NOT NULL
);

CREATE INDEX idx_writing_sentence_category ON writing_sentence(category);
CREATE INDEX idx_writing_sentence_difficulty ON writing_sentence(difficulty);
```

## Sample Sentences
Create 40+ sentences using only words from the USCIS vocabulary list:

**People** (5 sentences)
1. "Adams was the President."
2. "Lincoln was the President."
3. "Washington was the Father of Our Country."
4. "George Washington was the first President."
5. "Abraham Lincoln freed the slaves."

**Civics** (10 sentences)
1. "Citizens have the right to vote."
2. "Congress meets in the capital."
3. "The President lives in the White House."
4. "Senators meet in Washington."
5. "People elect the President."
6. "We have freedom of speech."
7. "The United States has a flag."
8. "The flag is red, white, and blue."
9. "Citizens can vote."
10. "We pay taxes."

**Places** (8 sentences)
1. "Alaska is a state."
2. "California is a state."
3. "Delaware is a state."
4. "Canada is north of the United States."
5. "Mexico is south of the United States."
6. "New York City is the largest city."
7. "Washington, D.C. is the capital."
8. "The United States has fifty states."

**Holidays** (7 sentences)
1. "Presidents' Day is in February."
2. "Memorial Day is in May."
3. "Flag Day is in June."
4. "Independence Day is in July."
5. "Labor Day is in September."
6. "Columbus Day is in October."
7. "Thanksgiving is in November."

**Other** (10+ sentences)
1. "We live in the United States."
2. "The President is here."
3. "One hundred Senators meet in Congress."
4. "People can vote for the President."
5. "Washington was the first President."
6. "Lincoln was the second President." (Note: factually incorrect but uses vocab)
7. "The capital is in Washington, D.C."
8. "Citizens want to vote."
9. "The largest state is Alaska."
10. "Here is a dollar bill."

## UI Components

### Screen Layout
```
┌─────────────────────────────────┐
│  Writing Practice        🔊 ℹ️  │
├─────────────────────────────────┤
│                                 │
│  ┌───────────────────────────┐ │
│  │  Sentences: 5 of 40       │ │
│  │  Score: 4 correct,        │ │
│  │        1 incorrect        │ │
│  └───────────────────────────┘ │
│                                 │
│  ┌───────────────────────────┐ │
│  │  Listen to the sentence   │ │
│  │  and type what you hear   │ │
│  └───────────────────────────┘ │
│                                 │
│     ┌─────────────────────┐    │
│     │   🔊 Play Audio     │    │
│     │                     │    │
│     │   [Speaking...]     │    │
│     └─────────────────────┘    │
│                                 │
│  ┌───────────────────────────┐ │
│  │  Type your answer here... │ │
│  │  ________________________ │ │
│  │                           │ │
│  └───────────────────────────┘ │
│                                 │
│        ┌──────────────┐         │
│        │ Submit       │         │
│        └──────────────┘         │
│                                 │
│  You wrote: [user text]         │
│                                 │
│  ┌───────────────────────────┐ │
│  │  Score: 95% ✓             │ │
│  │  Excellent!               │ │
│  └───────────────────────────┘ │
│                                 │
│  ┌──────────┐  ┌──────────┐   │
│  │ Try Again│  │   Next   │   │
│  └──────────┘  └──────────┘   │
│                                 │
└─────────────────────────────────┘
```

### Features
1. **Audio Playback**
   - Large play button with speaker icon
   - Visual feedback while speaking (pulsing animation)
   - Replay button to hear sentence again
   - Auto-stop after sentence completes

2. **Text Input**
   - Multi-line text field for typing
   - Clear button to reset input
   - Auto-capitalize first letter
   - Submit button (enabled when text entered)

3. **Evaluation Display**
   - Show typed text
   - Show percentage score with color coding
   - Display feedback message
   - Show checkmark/X icon

4. **Action Buttons**
   - **Try Again**: Reset current sentence (decrements incorrect counter)
   - **Next**: Load new sentence
   - Show both buttons if failed (<80%)
   - Show only Next if passed (≥80%)

5. **Progress Tracking**
   - Reuse `ProgressIndicatorWidget`
   - Track correct/incorrect answers
   - Show sentences answered vs total

## Implementation Steps

### Phase 1: Data Layer
1. Create `WritingSentence` model
2. Create `writing_sentences.json` with 40+ sentences
3. Update `DatabaseService`:
   - Add `writing_sentence` table creation
   - Add methods: `getAllWritingSentences()`, `getWritingSentencesByCategory()`, etc.
   - Bump database version to 5
4. Create `WritingSentenceService` for business logic

### Phase 2: Evaluation
1. Reuse existing `ReadingEvaluator` service
   - Already has similarity calculation
   - Already has 80% threshold
   - Already has feedback generation

### Phase 3: UI
1. Create `WritingPracticeScreen` widget
2. Integrate `flutter_tts` package
3. Implement audio playback controls
4. Implement text input and submission
5. Implement evaluation display
6. Add progress tracking with `ProgressIndicatorWidget`
7. Add navigation from main menu

### Phase 4: Testing
1. Test TTS on different devices
2. Verify sentence audio quality
3. Test evaluation accuracy
4. Test progress tracking
5. Test database population

## Dependencies
- `flutter_tts: ^4.2.0` - Text-to-speech functionality
- Existing: `string_similarity` for evaluation
- Existing: `sqflite` for database

## Localization
Currently English only (en-US). Spanish localization would require:
- Spanish TTS voice
- Spanish translations of sentences
- Update to `app_es.arb`

## Future Enhancements
1. **3-Sentence Test Mode**: Present 3 sentences, require 1 correct (like actual test)
2. **Speech Rate Control**: Allow users to adjust playback speed
3. **Voice Selection**: Allow users to choose TTS voice
4. **Hint System**: Show first letter or word count
5. **Practice History**: Track which sentences user struggles with
6. **Spaced Repetition**: Prioritize difficult sentences
