import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService extends ChangeNotifier {
  static const String themeKey = 'theme_mode';
  
  late SharedPreferences _prefs;
  late ThemeMode _themeMode;
  
  ThemeMode get themeMode => _themeMode;
  
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    
    // Load theme preference with a safety check
    int themeIndex;
    try {
      themeIndex = _prefs.getInt(themeKey) ?? ThemeMode.system.index;
    } catch (e) {
      // If there's an error, reset to default and clear the problematic value
      themeIndex = ThemeMode.system.index;
      await _prefs.remove(themeKey);
    }
    
    _themeMode = ThemeMode.values[themeIndex];
  }
  
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _prefs.setInt(themeKey, mode.index);
    notifyListeners();
  }
}