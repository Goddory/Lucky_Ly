import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeType {
  defaultTheme,
  tet,
  valentine,
}

class ThemeProvider extends ChangeNotifier {
  AppThemeType _currentTheme = AppThemeType.defaultTheme;

  AppThemeType get currentTheme => _currentTheme;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeStr = prefs.getString('app_theme');
    if (themeStr != null) {
      if (themeStr == 'tet') {
        _currentTheme = AppThemeType.tet;
      } else if (themeStr == 'valentine') {
        _currentTheme = AppThemeType.valentine;
      }
      notifyListeners();
    }
  }

  Future<void> setTheme(AppThemeType theme) async {
    if (_currentTheme != theme) {
      _currentTheme = theme;
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      String themeStr = 'default';
      if (theme == AppThemeType.tet) themeStr = 'tet';
      if (theme == AppThemeType.valentine) themeStr = 'valentine';
      await prefs.setString('app_theme', themeStr);
    }
  }
}
