import 'package:flutter/material.dart';

/// Holds the app-wide theme choice so it follows the user across every route.
class AppThemeController extends ChangeNotifier {
  AppThemeController._();

  static final AppThemeController instance = AppThemeController._();

  bool isDarkMode = false;

  void toggle() {
    isDarkMode = !isDarkMode;
    notifyListeners();
  }
}

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: AppThemeController.instance.isDarkMode ? 'Switch to light mode' : 'Switch to dark mode',
    onPressed: AppThemeController.instance.toggle,
    icon: Icon(AppThemeController.instance.isDarkMode ? Icons.light_mode : Icons.dark_mode),
  );
}
