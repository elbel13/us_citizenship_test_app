import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage onboarding state and user preferences
/// Follows the same pattern as ThemeService for consistency
class OnboardingService extends ChangeNotifier {
  // Keys for SharedPreferences
  static const String _onboardingCompleteKey = 'onboarding_completed';
  static const String _currentStepKey = 'onboarding_current_step';
  static const String _uiLanguageKey = 'ui_language';
  static const String _studyLanguageKey = 'study_language';
  static const String _questionYearKey = 'question_year';
  static const String _locationSetKey = 'location_set';
  static const String _userStateKey = 'user_state';
  static const String _userZipCodeKey = 'user_zip_code';

  bool _isOnboardingComplete = false;
  int _currentStep = 0;
  String _uiLanguage = 'en'; // Default to English
  String _studyLanguage = 'en'; // Default to English
  String? _questionYear;
  bool _locationSet = false;
  String? _userState;
  String? _userZipCode;

  // Getters
  bool get isOnboardingComplete => _isOnboardingComplete;
  int get currentStep => _currentStep;
  String get uiLanguage => _uiLanguage;
  String get studyLanguage => _studyLanguage;
  String? get questionYear => _questionYear;
  bool get locationSet => _locationSet;
  String? get userState => _userState;
  String? get userZipCode => _userZipCode;

  OnboardingService() {
    _loadOnboardingState();
  }

  /// Load onboarding state from SharedPreferences
  Future<void> _loadOnboardingState() async {
    final prefs = await SharedPreferences.getInstance();

    _isOnboardingComplete = prefs.getBool(_onboardingCompleteKey) ?? false;
    _currentStep = prefs.getInt(_currentStepKey) ?? 0;
    _uiLanguage = prefs.getString(_uiLanguageKey) ?? 'en';
    _studyLanguage = prefs.getString(_studyLanguageKey) ?? 'en';
    _questionYear = prefs.getString(_questionYearKey);
    _locationSet = prefs.getBool(_locationSetKey) ?? false;
    _userState = prefs.getString(_userStateKey);
    _userZipCode = prefs.getString(_userZipCodeKey);

    if (hasListeners) {
      notifyListeners();
    }
  }

  /// Set UI language preference
  Future<void> setUILanguage(String languageCode) async {
    _uiLanguage = languageCode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_uiLanguageKey, languageCode);
  }

  /// Set study materials language preference
  Future<void> setStudyLanguage(String languageCode) async {
    _studyLanguage = languageCode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_studyLanguageKey, languageCode);
  }

  /// Set question year preference
  Future<void> setQuestionYear(String year) async {
    _questionYear = year;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_questionYearKey, year);
  }

  /// Set location information
  Future<void> setLocation({String? state, String? zipCode}) async {
    _userState = state;
    _userZipCode = zipCode;
    _locationSet = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    if (state != null) await prefs.setString(_userStateKey, state);
    if (zipCode != null) await prefs.setString(_userZipCodeKey, zipCode);
    await prefs.setBool(_locationSetKey, true);
  }

  /// Update current onboarding step
  Future<void> setCurrentStep(int step) async {
    _currentStep = step;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_currentStepKey, step);
  }

  /// Mark onboarding as complete
  Future<void> completeOnboarding() async {
    _isOnboardingComplete = true;
    _currentStep = 0; // Reset for next time (if reset)
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompleteKey, true);
    await prefs.setInt(_currentStepKey, 0);
  }

  /// Reset onboarding (for testing/re-running)
  Future<void> resetOnboarding() async {
    _isOnboardingComplete = false;
    _currentStep = 0;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompleteKey, false);
    await prefs.setInt(_currentStepKey, 0);
  }

  /// Check if user needs to see study language selection
  /// (Only show if UI language is not English)
  bool shouldShowStudyLanguageSelection() {
    return _uiLanguage != 'en';
  }

  /// Validate that all required onboarding steps are complete
  bool isReadyToComplete() {
    return _questionYear != null && _locationSet;
  }
}
