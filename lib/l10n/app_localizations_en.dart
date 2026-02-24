// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'US Citizenship Test App';

  @override
  String get mainMenu => 'Main Menu';

  @override
  String get flashcards => 'Flashcards';

  @override
  String get multipleChoice => 'Multiple Choice';

  @override
  String get writing => 'Writing';

  @override
  String get reading => 'Reading';

  @override
  String get simulatedInterview => 'Simulated Interview';

  @override
  String get testReadiness => 'Test Readiness';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get english => 'English';

  @override
  String get spanish => 'Spanish';

  @override
  String get onboardingWelcome => 'Welcome!';

  @override
  String get onboardingLanguageSubtitle =>
      'Select your preferred language for the app interface';

  @override
  String get onboardingStudyLanguageTitle => 'Study Materials Language';

  @override
  String get onboardingStudyLanguageSubtitle =>
      'The citizenship test is conducted in English. We recommend studying in English for best preparation.';

  @override
  String studyInLanguageRecommended(String language) {
    return 'Study in $language (Recommended)';
  }

  @override
  String studyInLanguage(String language) {
    return 'Study in $language';
  }

  @override
  String studyLanguageNote(String language) {
    return 'Use $language translations to help understand concepts';
  }

  @override
  String get onboardingTestVersionTitle => 'Select Test Version';

  @override
  String get onboardingTestVersionSubtitle =>
      'Choose which version of the citizenship test questions you want to study';

  @override
  String get latest => 'Latest';

  @override
  String get currentTestVersion =>
      'Current test version (for recent applications)';

  @override
  String get previousTestVersion => 'Previous test version';

  @override
  String get onboardingLocationTitle => 'Location Setup';

  @override
  String get onboardingLocationSubtitle =>
      'We need your location to provide accurate information about your local government officials';

  @override
  String get useMyLocation => 'Use My Location';

  @override
  String get or => 'or';

  @override
  String get enterZipCode => 'Enter Zip Code';

  @override
  String locationSet(String state) {
    return 'Location set: $state';
  }

  @override
  String zipCode(String zip) {
    return 'Zip Code: $zip';
  }

  @override
  String get enterYourZipCode => 'Enter Your Zip Code';

  @override
  String get cancel => 'Cancel';

  @override
  String get submit => 'Submit';

  @override
  String get next => 'Next';

  @override
  String get back => 'Back';

  @override
  String get finish => 'Finish';

  @override
  String stepProgress(int current, int total) {
    return 'Step $current of $total';
  }
}
