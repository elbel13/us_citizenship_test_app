import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class SimulatedInterviewScreen extends StatelessWidget {
  const SimulatedInterviewScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.simulatedInterview)),
      body: Center(child: Text(l10n.simulatedInterview)),
    );
  }
}
