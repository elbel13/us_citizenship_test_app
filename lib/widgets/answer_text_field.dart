import 'package:flutter/material.dart';

/// A text field for entering answers with clear and optional submit buttons.
///
/// Provides consistent styling for text input across reading, writing,
/// and interview screens. Includes a clear button and optional submit button.
class AnswerTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? labelText;
  final String? hintText;
  final int maxLines;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSubmit;
  final String? submitButtonText;
  final bool showSubmitButton;
  final bool isSubmitting;

  const AnswerTextField({
    super.key,
    required this.controller,
    this.labelText,
    this.hintText,
    this.maxLines = 3,
    this.enabled = true,
    this.onChanged,
    this.onSubmit,
    this.submitButtonText,
    this.showSubmitButton = false,
    this.isSubmitting = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: labelText,
            hintText: hintText,
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => controller.clear(),
            ),
          ),
          maxLines: maxLines,
          textCapitalization: TextCapitalization.sentences,
          enabled: enabled,
          onChanged: onChanged,
        ),
        if (showSubmitButton && onSubmit != null) ...[
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: isSubmitting ? null : onSubmit,
            icon: isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check),
            label: Text(submitButtonText ?? 'Submit & Evaluate'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ],
    );
  }
}
