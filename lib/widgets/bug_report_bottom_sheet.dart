import 'package:flutter/material.dart';
import '../services/bug_report_service.dart';

class BugReportBottomSheet extends StatefulWidget {
  const BugReportBottomSheet({super.key});

  @override
  State<BugReportBottomSheet> createState() => _BugReportBottomSheetState();
}

class _BugReportBottomSheetState extends State<BugReportBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedScreen = 'Main Menu';
  String _selectedReproducibility = 'Always';
  bool _isSubmitting = false;

  static const List<String> _screens = [
    'Main Menu',
    'Flashcards',
    'Multiple Choice',
    'Reading & Writing',
    'Mock Interview',
    'Settings',
  ];

  static const List<String> _reproducibilityOptions = [
    'Always',
    'Often',
    'Sometimes',
    'Rarely',
    'Couldn\'t Reproduce',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitBugReport() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await BugReportService.reportBug(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        screen: _selectedScreen,
        reproducibility: _selectedReproducibility,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email app opened with bug report!'),
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open email app: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Report a Bug',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),

              // Title Field
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Bug Title',
                  hintText: 'Brief description of the issue',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a bug title';
                  }
                  if (value.trim().length < 5) {
                    return 'Title must be at least 5 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description Field
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  hintText: 'Detailed description of the issue',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  if (value.trim().length < 10) {
                    return 'Description must be at least 10 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Screen Dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedScreen,
                decoration: InputDecoration(
                  labelText: 'Screen',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: _screens.map((screen) {
                  return DropdownMenuItem(value: screen, child: Text(screen));
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedScreen = value);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Reproducibility Dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedReproducibility,
                decoration: InputDecoration(
                  labelText: 'How often does it happen?',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: _reproducibilityOptions.map((option) {
                  return DropdownMenuItem(value: option, child: Text(option));
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedReproducibility = value);
                  }
                },
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitBugReport,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Submit Bug Report'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
