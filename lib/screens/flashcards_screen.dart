import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class FlashcardsScreen extends StatelessWidget {
  const FlashcardsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.flashcards)),
      body: Center(child: Text(l10n.flashcards)),
    );
  }
}
