import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class ListeningScreen extends StatelessWidget {
  const ListeningScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.listening)),
      body: Center(child: Text(l10n.listening)),
    );
  }
}
