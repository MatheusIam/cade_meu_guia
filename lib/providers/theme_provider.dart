import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ThemeProvider class to manage the theme state
class ThemeProvider with ChangeNotifier {
  static const _prefThemeMode = 'theme_mode';
  static const _prefSeedColor = 'seed_color';

  ThemeMode _themeMode = ThemeMode.system; // padrão
  Color _seedColor = Colors.orange; // cor inicial
  bool _loaded = false;

  ThemeMode get themeMode => _themeMode;
  Color get seedColor => _seedColor;
  bool get isLoaded => _loaded;

  ThemeProvider() {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeIndex = prefs.getInt(_prefThemeMode);
      final colorValue = prefs.getInt(_prefSeedColor);
      if (modeIndex != null && modeIndex >= 0 && modeIndex < ThemeMode.values.length) {
        _themeMode = ThemeMode.values[modeIndex];
      }
      if (colorValue != null) {
        _seedColor = Color(colorValue);
      }
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefThemeMode, _themeMode.index);
    await prefs.setInt(_prefSeedColor, _seedColor.value);
  }

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    _persist();
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    if (mode == _themeMode) return;
    _themeMode = mode;
    _persist();
    notifyListeners();
  }

  // Conveniência usada em telas existentes
  void setSystemTheme() => setThemeMode(ThemeMode.system);

  void setSeedColor(Color color) {
    if (color == _seedColor) return;
    _seedColor = color;
    _persist();
    notifyListeners();
  }
}
