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
import 'theme/app_theme.dart';
import 'l10n/app_localizations.dart';
import 'services/database_service.dart';
import 'services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database in background - don't block app startup
  DatabaseService().database
      .then((_) {
        // Database initialized successfully
      })
      .catchError((error) {
        print('Error initializing database: $error');
      });

  runApp(const USCitizenshipTestApp());
}

class USCitizenshipTestApp extends StatefulWidget {
  const USCitizenshipTestApp({Key? key}) : super(key: key);

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
  }

  @override
  void dispose() {
    _themeService.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
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
      initialRoute: '/',
      routes: {
        '/': (context) => const MainMenuScreen(),
        '/flashcards': (context) => const FlashcardsScreen(),
        '/multiple_choice': (context) => const MultipleChoiceScreen(),
        '/writing': (context) => const WritingPracticeScreen(),
        '/reading': (context) => const ReadingPracticeScreen(),
        '/simulated_interview': (context) => const SimulatedInterviewScreen(),
        '/test_readiness': (context) => const TestReadinessScreen(),
        '/settings': (context) => SettingsScreen(themeService: _themeService),
      },
    );
  }
}
