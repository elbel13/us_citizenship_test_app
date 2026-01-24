# App Structure

This is a mobile app planed for UI optimized to a mobile experience. There should be smooth transitions between screens. The app should be easy to navigate. The app will be structured with the following pages/screens:
- Main menu
  - Flashcards
  - Multiple Choice
  - Writing
  - Listening
  - Simulated Interview
  - Test Readiness
  - Settings


## Main Menu Design Decision

The main menu uses a card-based grid layout. Each menu option is presented as a card with an icon and label, arranged in a 2-column grid. This design is chosen for its:
- Visual appeal and modern look
- Easy scanning and selection of options
- Touch-friendly, large tap targets
- Consistent theming across all menu items

This approach improves the user experience by making navigation intuitive and visually engaging, especially on mobile devices. The card menu is implemented in `MainMenuScreen` using Flutter's `GridView` and `Card` widgets.

## Localization Support

The app includes comprehensive multi-language support using Flutter's official localization system. Currently supported languages:
- English (en) - Default
- Spanish (es)

Users can change the language in the Settings screen, and the UI updates immediately. All user-facing text is stored in ARB (Application Resource Bundle) files for easy translation and maintenance.

For detailed information about the localization implementation, see [localization.md](localization.md).

All screens should follow the same theme and the theme should be modularized. This modularization should make changes applicable accross all screens.