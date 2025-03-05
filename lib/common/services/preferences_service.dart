import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService extends ChangeNotifier {
  // Consistent key for theme preference
  static const String _themeKey = 'app_theme_mode';
  
  // Private instance of SharedPreferences
  late SharedPreferences _prefs;
  
  // Store the current theme mode
  ThemeMode _themeMode = ThemeMode.system;
  
  // Getter for theme mode
  ThemeMode get themeMode => _themeMode;
  
  // Initialize the preferences service
  Future<void> initialize() async {
    try {
      // Ensure SharedPreferences is initialized
      _prefs = await SharedPreferences.getInstance();
      
      // Retrieve the saved theme mode
      final savedThemeIndex = _prefs.getInt(_themeKey);
      
      // Set theme mode, defaulting to system if not previously set
      if (savedThemeIndex != null) {
        _themeMode = ThemeMode.values[savedThemeIndex];
      } else {
        _themeMode = ThemeMode.system;
      }
    } catch (e) {
      // Log error and fall back to system theme
      print('Error initializing preferences: $e');
      _themeMode = ThemeMode.system;
    }
  }
  
  // Method to change and persist theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    try {
      // Update the current theme mode
      _themeMode = mode;
      
      // Persist the theme mode
      await _prefs.setInt(_themeKey, mode.index);
      
      // Notify listeners of the change
      notifyListeners();
    } catch (e) {
      print('Error saving theme mode: $e');
    }
  }
}