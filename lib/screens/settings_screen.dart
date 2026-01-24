import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.language),
            subtitle: Text(_getLanguageName(context)),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _showLanguageDialog(context),
          ),
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
}
