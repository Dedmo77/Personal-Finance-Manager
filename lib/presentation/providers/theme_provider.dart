import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const _key = 'isDarkMode';
  final SharedPreferences _prefs;
  bool _isDarkMode;

  ThemeProvider(this._prefs) : _isDarkMode = _prefs.getBool(_key) ?? false;

  bool get isDarkMode => _isDarkMode;

  Future<void> setDarkMode(bool value) async {
    if (_isDarkMode == value) return;
    _isDarkMode = value;
    await _prefs.setBool(_key, value);
    notifyListeners();
  }
}