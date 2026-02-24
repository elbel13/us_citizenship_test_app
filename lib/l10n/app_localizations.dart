import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'US Citizenship Test App'**
  String get appTitle;

  /// Main menu screen title
  ///
  /// In en, this message translates to:
  /// **'Main Menu'**
  String get mainMenu;

  /// Flashcards menu option
  ///
  /// In en, this message translates to:
  /// **'Flashcards'**
  String get flashcards;

  /// Multiple choice menu option
  ///
  /// In en, this message translates to:
  /// **'Multiple Choice'**
  String get multipleChoice;

  /// Writing menu option
  ///
  /// In en, this message translates to:
  /// **'Writing'**
  String get writing;

  /// Reading menu option
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get reading;

  /// Simulated interview menu option
  ///
  /// In en, this message translates to:
  /// **'Simulated Interview'**
  String get simulatedInterview;

  /// Test readiness menu option
  ///
  /// In en, this message translates to:
  /// **'Test Readiness'**
  String get testReadiness;

  /// Settings menu option
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Language setting label
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Select language dialog title
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// English language option
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// Spanish language option
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get spanish;

  /// Onboarding welcome title
  ///
  /// In en, this message translates to:
  /// **'Welcome!'**
  String get onboardingWelcome;

  /// Onboarding language selection subtitle
  ///
  /// In en, this message translates to:
  /// **'Select your preferred language for the app interface'**
  String get onboardingLanguageSubtitle;

  /// Study language selection title
  ///
  /// In en, this message translates to:
  /// **'Study Materials Language'**
  String get onboardingStudyLanguageTitle;

  /// Study language selection subtitle
  ///
  /// In en, this message translates to:
  /// **'The citizenship test is conducted in English. We recommend studying in English for best preparation.'**
  String get onboardingStudyLanguageSubtitle;

  /// Study in a specific language with recommendation
  ///
  /// In en, this message translates to:
  /// **'Study in {language} (Recommended)'**
  String studyInLanguageRecommended(String language);

  /// Study in a specific language
  ///
  /// In en, this message translates to:
  /// **'Study in {language}'**
  String studyInLanguage(String language);

  /// Note about using translated study materials
  ///
  /// In en, this message translates to:
  /// **'Use {language} translations to help understand concepts'**
  String studyLanguageNote(String language);

  /// Test version selection title
  ///
  /// In en, this message translates to:
  /// **'Select Test Version'**
  String get onboardingTestVersionTitle;

  /// Test version selection subtitle
  ///
  /// In en, this message translates to:
  /// **'Choose which version of the citizenship test questions you want to study'**
  String get onboardingTestVersionSubtitle;

  /// Latest version badge
  ///
  /// In en, this message translates to:
  /// **'Latest'**
  String get latest;

  /// Current test version description
  ///
  /// In en, this message translates to:
  /// **'Current test version (for recent applications)'**
  String get currentTestVersion;

  /// Previous test version description
  ///
  /// In en, this message translates to:
  /// **'Previous test version'**
  String get previousTestVersion;

  /// Location setup title
  ///
  /// In en, this message translates to:
  /// **'Location Setup'**
  String get onboardingLocationTitle;

  /// Location setup subtitle
  ///
  /// In en, this message translates to:
  /// **'We need your location to provide accurate information about your local government officials'**
  String get onboardingLocationSubtitle;

  /// Use GPS location button
  ///
  /// In en, this message translates to:
  /// **'Use My Location'**
  String get useMyLocation;

  /// Or separator text
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get or;

  /// Manual zip code entry button
  ///
  /// In en, this message translates to:
  /// **'Enter Zip Code'**
  String get enterZipCode;

  /// Location confirmation message
  ///
  /// In en, this message translates to:
  /// **'Location set: {state}'**
  String locationSet(String state);

  /// Zip code display
  ///
  /// In en, this message translates to:
  /// **'Zip Code: {zip}'**
  String zipCode(String zip);

  /// Zip code dialog title
  ///
  /// In en, this message translates to:
  /// **'Enter Your Zip Code'**
  String get enterYourZipCode;

  /// Cancel button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Submit button
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// Next button
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// Back button
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// Finish button
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// Shows current step and total steps
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String stepProgress(int current, int total);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
