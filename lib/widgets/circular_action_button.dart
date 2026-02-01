import 'package:flutter/material.dart';

/// A circular button used for mic, play, and other action controls.
///
/// Displays a 100x100 circular button with customizable icon, color,
/// and shadow effects when active. Used consistently across reading,
/// writing, and simulated interview screens.
class CircularActionButton extends StatelessWidget {
  final VoidCallback? onTap;
  final IconData icon;
  final Color color;
  final bool isActive;
  final bool showProgress;
  final String? statusText;

  const CircularActionButton({
    super.key,
    required this.onTap,
    required this.icon,
    this.color = Colors.blue,
    this.isActive = false,
    this.showProgress = false,
    this.statusText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(50),
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ]
                  : null,
            ),
            child: showProgress
                ? const CircularProgressIndicator(color: Colors.white)
                : Icon(icon, size: 50, color: Colors.white),
          ),
        ),
        if (statusText != null) ...[
          const SizedBox(height: 12),
          Text(statusText!, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ],
    );
  }
}
