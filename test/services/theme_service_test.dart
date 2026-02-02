import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:us_citizenship_test_app/services/theme_service.dart';

void main() {
  group('ThemeService', () {
    setUp(() {
      // Initialize shared preferences with empty values before each test
      SharedPreferences.setMockInitialValues({});
    });

    test('initializes with system theme mode by default', () {
      final themeService = ThemeService();
      expect(themeService.themeMode, ThemeMode.system);
    });

    test('setThemeMode updates theme and notifies listeners', () async {
      final themeService = ThemeService();
      var notificationCount = 0;

      // Wait for initialization to complete
      await Future.delayed(const Duration(milliseconds: 100));

      themeService.addListener(() {
        notificationCount++;
      });

      await themeService.setThemeMode(ThemeMode.dark);

      expect(themeService.themeMode, ThemeMode.dark);
      expect(notificationCount, 1);
    });

    test('setThemeMode persists theme preference', () async {
      final themeService = ThemeService();

      await themeService.setThemeMode(ThemeMode.light);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('theme_mode'), ThemeMode.light.toString());
    });

    test('loads persisted theme on initialization', () async {
      // Set up a persisted theme
      SharedPreferences.setMockInitialValues({
        'theme_mode': ThemeMode.dark.toString(),
      });

      final themeService = ThemeService();

      // Give it time to load
      await Future.delayed(const Duration(milliseconds: 100));

      expect(themeService.themeMode, ThemeMode.dark);
    });

    test('toggleTheme sets dark mode when true', () async {
      final themeService = ThemeService();

      await themeService.toggleTheme(true);

      expect(themeService.themeMode, ThemeMode.dark);
    });

    test('toggleTheme sets light mode when false', () async {
      final themeService = ThemeService();

      await themeService.toggleTheme(false);

      expect(themeService.themeMode, ThemeMode.light);
    });

    test('toggleTheme persists the selection', () async {
      final themeService = ThemeService();

      await themeService.toggleTheme(true);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('theme_mode'), ThemeMode.dark.toString());
    });

    test('can switch between all theme modes', () async {
      final themeService = ThemeService();

      await themeService.setThemeMode(ThemeMode.system);
      expect(themeService.themeMode, ThemeMode.system);

      await themeService.setThemeMode(ThemeMode.light);
      expect(themeService.themeMode, ThemeMode.light);

      await themeService.setThemeMode(ThemeMode.dark);
      expect(themeService.themeMode, ThemeMode.dark);
    });

    test('handles invalid persisted theme gracefully', () async {
      SharedPreferences.setMockInitialValues({
        'theme_mode': 'invalid_theme_mode',
      });

      final themeService = ThemeService();
      await Future.delayed(const Duration(milliseconds: 100));

      // Should fall back to system mode
      expect(themeService.themeMode, ThemeMode.system);
    });

    test('notifies listeners on theme change', () async {
      final themeService = ThemeService();
      final notifications = <ThemeMode>[];

      // Wait for initialization to complete
      await Future.delayed(const Duration(milliseconds: 100));

      themeService.addListener(() {
        notifications.add(themeService.themeMode);
      });

      await themeService.setThemeMode(ThemeMode.dark);
      await themeService.setThemeMode(ThemeMode.light);
      await themeService.setThemeMode(ThemeMode.system);

      expect(notifications, [
        ThemeMode.dark,
        ThemeMode.light,
        ThemeMode.system,
      ]);
    });

    test('multiple theme changes are persisted correctly', () async {
      final themeService = ThemeService();

      await themeService.setThemeMode(ThemeMode.dark);
      await themeService.setThemeMode(ThemeMode.light);
      await themeService.setThemeMode(ThemeMode.dark);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('theme_mode'), ThemeMode.dark.toString());
      expect(themeService.themeMode, ThemeMode.dark);
    });

    test('does not notify before listeners are attached', () async {
      SharedPreferences.setMockInitialValues({
        'theme_mode': ThemeMode.dark.toString(),
      });

      final themeService = ThemeService();
      var notified = false;

      // Wait for initialization to complete
      await Future.delayed(const Duration(milliseconds: 100));

      // Add listener after initialization
      themeService.addListener(() {
        notified = true;
      });

      // Listener should not have been called during initialization
      expect(notified, false);
    });

    test('listeners can be added and removed', () async {
      final themeService = ThemeService();

      bool listenerCalled = false;
      void listener() {
        listenerCalled = true;
      }

      themeService.addListener(listener);
      await themeService.setThemeMode(ThemeMode.dark);
      expect(listenerCalled, true);

      themeService.removeListener(listener);
    });
  });
}
