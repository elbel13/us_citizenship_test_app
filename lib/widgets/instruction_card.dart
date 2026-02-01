import 'package:flutter/material.dart';

/// A card displaying instructions or information to the user.
///
/// Uses the theme's primaryContainer color for consistent styling
/// across the app. Used in reading, writing, and interview screens.
class InstructionCard extends StatelessWidget {
  final String text;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry? padding;

  const InstructionCard({
    super.key,
    required this.text,
    this.textStyle,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: padding ?? const EdgeInsets.all(12.0),
        child: Text(
          text,
          style: textStyle ?? Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
