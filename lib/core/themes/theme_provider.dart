import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:WanderBite/core/constants/app_constants.dart';
import 'package:WanderBite/core/themes/app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeData _currentTheme = AppTheme.lightTheme;
  String _themeType = AppConstants.travelTheme; // Default theme

  ThemeData get currentTheme => _currentTheme;
  String get themeType => _themeType;

  ThemeProvider() {
    _loadThemeFromPrefs();
  }

  void _loadThemeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme =
        prefs.getString(AppConstants.themeKey) ?? AppConstants.travelTheme;
    setTheme(savedTheme);
  }

  Future<void> setTheme(String themeType) async {
    _themeType = themeType;

    switch (themeType) {
      case AppConstants.travelTheme:
        _currentTheme = AppTheme.travelTheme;
        break;
      case AppConstants.recipeTheme:
        _currentTheme = AppTheme.recipeTheme;
        break;
      default:
        _currentTheme = AppTheme.lightTheme;
    }

    // Save to preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.themeKey, themeType);

    notifyListeners();
  }
}
