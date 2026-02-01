import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final List<_MenuItem> menuItems = [
      _MenuItem(
        title: l10n.flashcards,
        icon: Icons.style,
        route: '/flashcards',
      ),
      _MenuItem(
        title: l10n.multipleChoice,
        icon: Icons.quiz,
        route: '/multiple_choice',
      ),
      _MenuItem(title: l10n.writing, icon: Icons.edit, route: '/writing'),
      _MenuItem(
        title: l10n.reading,
        icon: Icons.record_voice_over,
        route: '/reading',
      ),
      _MenuItem(
        title: l10n.simulatedInterview,
        icon: Icons.mic,
        route: '/simulated_interview',
      ),
      _MenuItem(
        title: l10n.testReadiness,
        icon: Icons.check_circle,
        route: '/test_readiness',
      ),
      _MenuItem(title: l10n.settings, icon: Icons.settings, route: '/settings'),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.mainMenu), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          itemCount: menuItems.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.1,
          ),
          itemBuilder: (context, index) {
            final item = menuItems[index];
            return _MenuCard(item: item);
          },
        ),
      ),
    );
  }
}

class _MenuItem {
  final String title;
  final IconData icon;
  final String route;

  const _MenuItem({
    required this.title,
    required this.icon,
    required this.route,
  });
}

class _MenuCard extends StatelessWidget {
  final _MenuItem item;

  const _MenuCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, item.route),
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                item.icon,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                item.title,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
