# Localization Implementation

This document describes the multi-language support implementation in the US Citizenship Test App.

## Overview

The app uses Flutter's official localization system with ARB (Application Resource Bundle) files. This approach provides:
- Type-safe access to localized strings
- Automatic code generation
- Support for multiple languages
- Easy extensibility for new languages
- Locale-specific formatting

## Supported Languages

Currently, the app supports:
- **English (en)** - Default language
- **Spanish (es)** - Secondary language

## Architecture

### 1. Configuration Files

**pubspec.yaml**
- Dependencies: `flutter_localizations` and `intl` packages
- `generate: true` enables automatic code generation

**l10n.yaml**
- Configures the localization tool
- Specifies ARB file directory (`lib/l10n`)
- Sets template file (`app_en.arb`)
- Defines output file name (`app_localizations.dart`)

### 2. Translation Files

All translation files are located in `lib/l10n/`:

**app_en.arb** - English translations (template file)
```json
{
  "@@locale": "en",
  "appTitle": "US Citizenship Test App",
  "@appTitle": {
    "description": "The title of the application"
  }
}
```

**app_es.arb** - Spanish translations
```json
{
  "@@locale": "es",
  "appTitle": "Examen de Ciudadanía de EE.UU."
}
```

### 3. Generated Code

When you run `flutter pub get` or build the app, Flutter automatically generates:
- `lib/l10n/app_localizations.dart` - Base localization class
- `lib/l10n/app_localizations_en.dart` - English implementation
- `lib/l10n/app_localizations_es.dart` - Spanish implementation

**Never edit these files manually** - they are regenerated on each build.

### 4. Main App Configuration

The `main.dart` file configures localization support:

```dart
class USCitizenshipTestApp extends StatefulWidget {
  // Provides a method to change locale dynamically
  static void setLocale(BuildContext context, Locale newLocale) {
    _USCitizenshipTestAppState? state =
        context.findAncestorStateOfType<_USCitizenshipTestAppState>();
    state?.setLocale(newLocale);
  }
}

class _USCitizenshipTestAppState extends State<USCitizenshipTestApp> {
  Locale? _locale;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: _locale, // Current app locale
      localizationsDelegates: const [
        AppLocalizations.delegate,           // App-specific localizations
        GlobalMaterialLocalizations.delegate, // Material widgets
        GlobalWidgetsLocalizations.delegate,  // General widgets
        GlobalCupertinoLocalizations.delegate, // iOS widgets
      ],
      supportedLocales: const [
        Locale('en'), // English
        Locale('es'), // Spanish
      ],
      // ... routes and theme
    );
  }
}
```

## Usage in Code

### Accessing Localized Strings

In any widget, access translations using:

```dart
import '../l10n/app_localizations.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Text(l10n.appTitle); // Displays localized app title
  }
}
```

### Example: Main Menu Screen

```dart
@override
Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  
  return Scaffold(
    appBar: AppBar(title: Text(l10n.mainMenu)),
    body: Column(
      children: [
        Text(l10n.flashcards),
        Text(l10n.multipleChoice),
        // ... more localized text
      ],
    ),
  );
}
```

## Language Selection

Users can change the language in the Settings screen:

1. Navigate to Settings
2. Tap on "Language" option
3. Select desired language from dialog
4. UI updates immediately to show selected language

The language selection is implemented in `settings_screen.dart`:

```dart
void _changeLanguage(BuildContext context, String languageCode) {
  Navigator.pop(context);
  USCitizenshipTestApp.setLocale(context, Locale(languageCode));
}
```

## Adding New Languages

To add support for a new language:

1. **Create a new ARB file** in `lib/l10n/`:
   - Name it `app_[language_code].arb` (e.g., `app_fr.arb` for French)
   - Copy all keys from `app_en.arb`
   - Translate the values

2. **Update main.dart**:
   ```dart
   supportedLocales: const [
     Locale('en'),
     Locale('es'),
     Locale('fr'), // Add new locale
   ],
   ```

3. **Update Settings screen**:
   - Add new language option in `_showLanguageDialog()`
   - Add new case in `_getLanguageName()`

4. **Add translations to ARB files**:
   - Add `"french": "French"` to `app_en.arb`
   - Add `"french": "Francés"` to `app_es.arb`
   - Add `"french": "Français"` to `app_fr.arb`

5. **Run flutter pub get** to regenerate localization files

## Adding New Translatable Strings

When adding new UI text:

1. **Add to English ARB file** (`app_en.arb`):
   ```json
   {
     "myNewString": "My New Text",
     "@myNewString": {
       "description": "Description of where this text appears"
     }
   }
   ```

2. **Add to all other ARB files** (`app_es.arb`, etc.):
   ```json
   {
     "myNewString": "Mi Nuevo Texto"
   }
   ```

3. **Run flutter pub get** to regenerate

4. **Use in code**:
   ```dart
   final l10n = AppLocalizations.of(context)!;
   Text(l10n.myNewString);
   ```

## Best Practices

1. **Never hardcode user-visible text** - Always use AppLocalizations
2. **Keep ARB files synchronized** - Every key in the template must exist in all language files
3. **Use descriptive keys** - `flashcards` is better than `text1`
4. **Add descriptions** - Use `@keyName` blocks to document purpose
5. **Test all languages** - Verify UI layouts work with different text lengths
6. **Use flexible layouts** - Some languages require more space than English
7. **Consider RTL languages** - Design layouts that work for right-to-left text if needed

## Design Considerations

### Text Length Variations
- Spanish text is typically 20-30% longer than English
- Use `Expanded`, `Flexible`, or `FittedBox` widgets to handle variable text lengths
- Avoid fixed-width containers for text

### Layout Flexibility
```dart
// Good: Flexible layout
Row(
  children: [
    Expanded(child: Text(l10n.longText)),
  ],
)

// Bad: Fixed width
Container(
  width: 100,
  child: Text(l10n.longText), // May overflow
)
```

### Testing
- Test with longest language (usually Spanish for EN/ES apps)
- Check all screens with each supported language
- Verify proper text wrapping and overflow handling

## Troubleshooting

### "AppLocalizations not found" error
- Run `flutter pub get` to generate localization files
- Check that `generate: true` is in `pubspec.yaml`
- Verify `l10n.yaml` exists and is properly configured

### Missing translations
- Ensure all ARB files have the same keys
- Check for typos in key names
- Run `flutter pub get` after adding new strings

### Language not changing
- Verify locale is added to `supportedLocales`
- Check that `setLocale` is being called correctly
- Ensure MaterialApp uses the `locale` parameter

## Future Enhancements

Potential improvements for production apps:
- **Persistent language selection** - Save user's language preference using SharedPreferences
- **Automatic language detection** - Use device locale as default
- **State management** - Integrate with Provider, Riverpod, or Bloc for cleaner state handling
- **Plurals and genders** - Use `intl` package features for complex translations
- **Date/number formatting** - Locale-specific formatting for dates, numbers, and currencies
- **Region-specific variants** - Support for regional differences (e.g., es_MX vs es_ES)
