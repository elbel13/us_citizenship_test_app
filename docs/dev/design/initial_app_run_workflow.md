# Initial App Run Workflow

This document outlines the workflow for a user during their initial run of the US Citizenship Test App. The goal is to configure user specific settings, such as:
- Language preference
- Year of test questions
- Local government officials based on user's location
- Initial tutorial or onboarding (very brief)

All settings should be saved locally so they persist across app restarts. They can be changed later in the Settings screen.

## Step 1: Language Selection
On first launch, the app prompts the user to select their preferred language for the app interface. Options include:
- English
- Spanish
- Other languages (future enhancement)

We should also select whether to use English or the selected language for study content (questions, flashcards, etc.). The actual test will always be in English, barring a few exceptions, so we recommend using English for study content.

## Step 2: Year of Test Questions
Next, the user selects the year of the citizenship test questions they wish to study. Options include:
- 2025 (latest)
- 2020 (previous, will be deprecated in future)

The app explains that the test questions reflect the time their application was filed, so users should choose the year that matches their situation.

This will affect which set of civics questions are presented in flashcards, multiple choice quizzes, and the simulated interview feature. We should load a different question set based on this selection into the database.

## Step 3: Location Setup
To provide accurate information about local government officials, the app requests permission to access the user's location. If granted, the app automatically determines the user's state and county. If denied, the user is prompted to manually select their zip code or state/county from a list.

This will affect the local government official questions in the civics section. We should update the database with the correct officials based on the user's location.