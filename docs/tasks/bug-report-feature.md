# Bug Report Feature

## Summary
Add a "Report a Bug" option in Settings that opens a bottom sheet form and creates pre-filled GitHub issues.

## Files to Modify
- `pubspec.yaml` (add url_launcher dependency)
- `lib/services/bug_report_service.dart` (new file)
- `lib/widgets/bug_report_bottom_sheet.dart` (new file)
- `lib/screens/settings_screen.dart` (add bug report option)

## Acceptance Criteria
1. Add url_launcher dependency
2. Create BugReportService to build GitHub issue URLs
3. Create BugReportBottomSheet with form (title, description, screen, reproducibility)
4. Add "Report a Bug" option to Settings screen
5. Form opens GitHub issue with pre-filled information

## Tests
Manual testing - verify form works and GitHub issue opens correctly
