# Multiple Choice Design

The Multiple Choice screen allows users to practice answering questions in a quiz format. Each question is presented with four possible answers, and the user must select the correct one. Immediate feedback is provided after each selection, indicating whether the answer was correct or incorrect. The user can then proceed to the next question. At the end of the quiz, a summary of performance is displayed, including the number of correct answers and areas for improvement.

## Feedback Mechanism

When a user selects an answer, the app provides instant feedback:
- If the answer is correct, display a green checkmark and a "Correct!" message. The correct answer is highlighted in green.
- If the answer is incorrect, display a red cross and an "Incorrect!" message. The correct answer is highlighted in green, while the selected wrong answer is highlighted in red.

## Question Data Source

The multiple choice questions are sourced from the same dataset as the flashcards, stored in a local database. Each question has four possible answers, with one marked as correct. The questions are presented in a random order to ensure varied practice sessions.

Since the questions don't have incorrect answers stored, the app generates three random incorrect answers from the pool of all possible answers for each question.

## Score Tracking

The app tracks the user's score throughout the quiz session. At the end of the quiz, a summary screen displays:
- Total number of questions answered
- Number of correct answers
- Percentage score
- Suggestions for areas to review based on incorrect answers (future enhancement, as questions are not categorized yet)

The score data is then persisted locally for future reference and progress tracking (future enhancement).