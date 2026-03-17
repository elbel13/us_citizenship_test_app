import 'package:flutter_test/flutter_test.dart';
import 'package:us_citizenship_test_app/services/bug_report_service.dart';

void main() {
  group('BugReportService', () {
    test('buildEmailUrl generates correct mailto URL with all fields', () {
      final url = BugReportService.buildEmailUrl(
        title: 'Test Bug',
        description: 'This is a test description',
        screen: 'Main Menu',
        reproducibility: 'Always',
      );

      expect(url, startsWith('mailto:elijahb@duck.com'));
      expect(url, contains('subject='));
      expect(url, contains('Bug+Report'));
      expect(url, contains('Test+Bug'));
      expect(url, contains('body='));
      expect(url, contains('Description'));
      expect(url, contains('Main+Menu'));
      expect(url, contains('Always'));
    });

    test('buildEmailUrl handles special characters correctly', () {
      final url = BugReportService.buildEmailUrl(
        title: 'Bug with & and = chars',
        description: 'Description with special chars: & < > " \'',
        screen: 'Settings',
        reproducibility: 'Sometimes',
      );

      expect(url, startsWith('mailto:elijahb@duck.com'));
      // URL encoding should handle special characters
      expect(url, contains('Bug+with'));
      expect(url, contains('%26')); // & should be encoded
      expect(url, isNot(contains('&body=&'))); // Shouldn't break URL structure
    });

    test('buildEmailUrl includes all required information', () {
      final url = BugReportService.buildEmailUrl(
        title: 'Missing data bug',
        description: 'The app crashes when opening flashcards',
        screen: 'Flashcards',
        reproducibility: 'Often',
      );

      // Check for all required sections
      expect(url, contains('Description'));
      expect(url, contains('Screen'));
      expect(url, contains('How+often'));
      expect(url, contains('Device+Info'));
      expect(url, contains('App+Version'));
    });
  });
}
