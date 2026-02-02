import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';
import '../services/theme_service.dart';
import '../services/onboarding_service.dart';

class SettingsScreen extends StatefulWidget {
  final ThemeService themeService;
  final OnboardingService? onboardingService;

  const SettingsScreen({
    super.key,
    required this.themeService,
    this.onboardingService,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Check actual brightness when system mode is active
    final isDarkMode =
        widget.themeService.themeMode == ThemeMode.dark ||
        (widget.themeService.themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode),
            title: const Text('Dark Mode'),
            subtitle: Text(isDarkMode ? 'Enabled' : 'Disabled'),
            value: isDarkMode,
            onChanged: (bool value) {
              widget.themeService.toggleTheme(value);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.language),
            subtitle: Text(_getLanguageName(context)),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _showLanguageDialog(context),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.science),
            title: const Text('LLM Test (Developer)'),
            subtitle: const Text('Test DistilGPT-2 model inference'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => Navigator.pushNamed(context, '/llm_test'),
          ),
          if (widget.onboardingService != null) ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.refresh, color: Colors.orange),
              title: const Text('Reset Onboarding'),
              subtitle: const Text('Replay first-time setup (for testing)'),
              onTap: () => _showResetOnboardingDialog(context),
            ),
          ],
        ],
      ),
    );
  }

  String _getLanguageName(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final l10n = AppLocalizations.of(context)!;

    switch (locale.languageCode) {
      case 'en':
        return l10n.english;
      case 'es':
        return l10n.spanish;
      default:
        return l10n.english;
    }
  }

  void _showLanguageDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.selectLanguage),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(l10n.english),
                leading: Radio<String>(
                  value: 'en',
                  groupValue: Localizations.localeOf(context).languageCode,
                  onChanged: (String? value) {
                    if (value != null) {
                      _changeLanguage(context, value);
                    }
                  },
                ),
                onTap: () => _changeLanguage(context, 'en'),
              ),
              ListTile(
                title: Text(l10n.spanish),
                leading: Radio<String>(
                  value: 'es',
                  groupValue: Localizations.localeOf(context).languageCode,
                  onChanged: (String? value) {
                    if (value != null) {
                      _changeLanguage(context, value);
                    }
                  },
                ),
                onTap: () => _changeLanguage(context, 'es'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _changeLanguage(BuildContext context, String languageCode) {
    Navigator.pop(context);
    USCitizenshipTestApp.setLocale(context, Locale(languageCode));
  }

  void _showResetOnboardingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reset Onboarding?'),
          content: const Text(
            'This will restart the first-time setup process. '
            'You will need to configure your language, question year, '
            'and location settings again. This will also reload the question database.\\n\\n'
            'This is primarily for testing purposes.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await widget.onboardingService?.resetOnboarding();
                if (context.mounted) {
                  // Navigate to root and let the app restart with onboarding
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/', (route) => false);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );
  }
}
