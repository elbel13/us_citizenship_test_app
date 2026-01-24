import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class MultipleChoiceScreen extends StatelessWidget {
  const MultipleChoiceScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.multipleChoice)),
      body: Center(child: Text(l10n.multipleChoice)),
    );
  }
}
