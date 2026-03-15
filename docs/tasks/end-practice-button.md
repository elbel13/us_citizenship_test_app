# End Practice Button

## Summary
Add an "End Practice" button to practice screens that allows users to exit early and return to the main menu. First implementation is for Multiple Choice screen.

## Files to Modify
- `lib/widgets/end_practice_button.dart` (new file)
- `lib/screens/multiple_choice_screen.dart` (add import and update AppBar)

## Acceptance Criteria
1. Create reusable EndPracticeButton widget with confirmation dialog
2. Add button to Multiple Choice screen AppBar
3. Button shows progress summary if questions have been answered
4. Cancel returns to quiz, End Practice returns to main menu
5. Follows code conventions in AGENTS.md

## Tests
Manual testing only - verify button appears, dialog works, navigation is correct
