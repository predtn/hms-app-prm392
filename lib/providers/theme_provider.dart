import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  bool get isLight => _themeMode == ThemeMode.light;
  bool get isDark => _themeMode == ThemeMode.dark;
  bool get isSystem => _themeMode == ThemeMode.system;

  void setLight() => _setTheme(ThemeMode.light);
  void setDark() => _setTheme(ThemeMode.dark);
  void setSystem() => _setTheme(ThemeMode.system);

  void setThemeFromString(String mode) {
    switch (mode) {
      case 'light':
        _setTheme(ThemeMode.light);
        break;
      case 'dark':
        _setTheme(ThemeMode.dark);
        break;
      default:
        _setTheme(ThemeMode.system);
    }
  }

  void _setTheme(ThemeMode mode) {
    if (_themeMode == mode) return; // no unnecessary rebuilds
    _themeMode = mode;
    notifyListeners();
  }
}
