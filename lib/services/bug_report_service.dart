import 'package:url_launcher/url_launcher.dart';

class BugReportService {
  static const String _bugReportEmail = 'elijahb@duck.com';

  /// Builds a mailto URL with pre-filled bug report information
  static String buildEmailUrl({
    required String title,
    required String description,
    required String screen,
    required String reproducibility,
  }) {
    final subject = '[Bug Report] $title';

    final body =
        '''Description:
$description

Screen: $screen
How often does it happen? $reproducibility

Device Info:
- App Version: 0.4.0
- Date: ${DateTime.now().toString()}''';

    final emailUri = Uri(
      scheme: 'mailto',
      path: _bugReportEmail,
      queryParameters: {'subject': subject, 'body': body},
    );

    return emailUri.toString();
  }

  /// Opens the user's email client with pre-filled bug report information
  static Future<void> reportBug({
    required String title,
    required String description,
    required String screen,
    required String reproducibility,
  }) async {
    final url = buildEmailUrl(
      title: title,
      description: description,
      screen: screen,
      reproducibility: reproducibility,
    );

    try {
      final uri = Uri.parse(url);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        throw Exception('Could not open email app');
      }
    } catch (e) {
      print('Error launching bug report email: $e');
      rethrow;
    }
  }
}
