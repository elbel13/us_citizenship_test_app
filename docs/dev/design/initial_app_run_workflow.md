# Initial App Run Workflow

This document outlines the workflow for a user during their initial run of the US Citizenship Test App. The goal is to configure user specific settings, such as:
- Language preference
- Year of test questions
- Local government officials based on user's location
- ~~Initial tutorial or onboarding (very brief)~~ (Future enhancement - skipped for initial implementation)

All settings should be saved locally using SharedPreferences (following the pattern used for theme settings) so they persist across app restarts. They can be changed later in the Settings screen.

**Important**: The onboarding workflow must complete BEFORE the database is populated with questions, as the year selection determines which question set to load.

## Step 1: Language Selection
On first launch, the app prompts the user to select their preferred language for the app interface. Options include:
- English (default)
- Spanish
- Other languages (future enhancement)

### Step 1.5: Study Materials Language (conditional)
If a non-English language is selected for the UI, show an additional screen to select whether to use English or the selected language for study content (questions, flashcards, etc.). The actual test will always be in English, barring a few exceptions, so we recommend using English for study content.

**Implementation Note**: This screen should be hidden/skipped if English is selected as the UI language, since it would not apply. Currently, only English study materials are available; Spanish and other languages are planned for future enhancement.

## Step 2: Year of Test Questions
Next, the user selects the version of the citizenship test questions they wish to study. The app explains that the test questions reflect the time their application was filed, so users should choose the version that matches their situation.

Available options are determined by which question JSON files are bundled in the assets folder. Test versions are published periodically (not annually) when USCIS updates the civics test:
- **2025** - Latest version (will be available when file is added: `questions_en_categorized_2025.json`)
- **2020** - Previous version (currently available as `questions_en_categorized.json`)

**Implementation Note**: The dropdown dynamically populates based on available question files. Future test versions (e.g., if a 2030 version is released) can be added by simply including the corresponding JSON file. The selected question set will be loaded into the database during initial setup.

## Step 3: Location Setup
To provide accurate information about local government officials, the app requests permission to access the user's location using the `geolocator` package. 

**If permission is granted**: The app automatically determines the user's state and uses government APIs to find their specific officials (Governor, Senators, Representatives).

**If permission is denied**: The user is prompted to manually enter their zip code. The app then uses this to determine state/district and lookup officials.

**Resources for official lookup**:
- Congressional members: https://www.congress.gov/members/find-your-member
- State governors: https://www.usa.gov/state-governor

**Implementation Note**: This setting doesn't change often, so it should be persisted in the database. The database has questions with placeholders (e.g., "Who is your state's governor?") that need to be updated with actual official names based on the user's location. There is no default value for this step; the user must provide location information (either via permission or manual entry) before proceeding.

## UX Flow Details

### Navigation
- Full-screen pages with Back and Next buttons
- Next button should be hidden or disabled if no selection is made and there's no sensible default
- Sensible defaults: English for language selection
- Required selections: Location setup (no default, must be completed)
- Progress indicator showing current step

### Persistence & Resume
- All onboarding progress is stored in SharedPreferences
- If the app is closed mid-onboarding, it should resume where the user left off
- A flag tracks whether onboarding has been fully completed

### Testing
- Settings screen includes a "Reset Onboarding" button for developers/testing purposes
- This allows replaying the onboarding flow without reinstalling the app