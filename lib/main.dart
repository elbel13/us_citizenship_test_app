import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/main_menu_screen.dart';
import 'screens/flashcards_screen.dart';
import 'screens/multiple_choice_screen.dart';
import 'screens/writing_practice_screen.dart';
import 'screens/reading_practice_screen.dart';
import 'screens/simulated_interview_screen.dart';
import 'screens/test_readiness_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/llm_test_screen.dart';
import 'screens/onboarding_screen.dart';
import 'theme/app_theme.dart';
import 'l10n/app_localizations.dart';
import 'services/theme_service.dart';
import 'services/onboarding_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize onboarding service
  final onboardingService = OnboardingService();

  runApp(USCitizenshipTestApp(onboardingService: onboardingService));
}

class USCitizenshipTestApp extends StatefulWidget {
  final OnboardingService onboardingService;

  const USCitizenshipTestApp({super.key, required this.onboardingService});

  @override
  State<USCitizenshipTestApp> createState() => _USCitizenshipTestAppState();

  static void setLocale(BuildContext context, Locale newLocale) {
    _USCitizenshipTestAppState? state = context
        .findAncestorStateOfType<_USCitizenshipTestAppState>();
    state?.setLocale(newLocale);
  }

  static void setThemeMode(BuildContext context, ThemeMode mode) {
    _USCitizenshipTestAppState? state = context
        .findAncestorStateOfType<_USCitizenshipTestAppState>();
    state?.setThemeMode(mode);
  }
}

class _USCitizenshipTestAppState extends State<USCitizenshipTestApp> {
  Locale? _locale;
  final ThemeService _themeService = ThemeService();

  @override
  void initState() {
    super.initState();
    _themeService.addListener(_onThemeChanged);
    widget.onboardingService.addListener(_onOnboardingChanged);

    // Set initial locale from onboarding service
    _locale = Locale(widget.onboardingService.uiLanguage);
  }

  @override
  void dispose() {
    _themeService.removeListener(_onThemeChanged);
    widget.onboardingService.removeListener(_onOnboardingChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  void _onOnboardingChanged() {
    setState(() {
      _locale = Locale(widget.onboardingService.uiLanguage);
    });
  }

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  void setThemeMode(ThemeMode mode) {
    _themeService.setThemeMode(mode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'US Citizenship Test App',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeService.themeMode,
      locale: _locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // English
        Locale('es'), // Spanish
      ],
      initialRoute: widget.onboardingService.isOnboardingComplete
          ? '/'
          : '/onboarding',
      routes: {
        '/': (context) => const MainMenuScreen(),
        '/onboarding': (context) =>
            OnboardingScreen(onboardingService: widget.onboardingService),
        '/flashcards': (context) => const FlashcardsScreen(),
        '/multiple_choice': (context) => const MultipleChoiceScreen(),
        '/writing': (context) => const WritingPracticeScreen(),
        '/reading': (context) => const ReadingPracticeScreen(),
        '/simulated_interview': (context) => const SimulatedInterviewScreen(),
        '/test_readiness': (context) => const TestReadinessScreen(),
        '/settings': (context) => SettingsScreen(
          themeService: _themeService,
          onboardingService: widget.onboardingService,
        ),
        '/llm_test': (context) => const LlmTestScreen(),
      },
    );
  }
}
