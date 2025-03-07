import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService extends ChangeNotifier {
  // Keys for preferences
  static const String _themeKey = 'app_theme_mode';
  static const String _hardwareAccelerationKey = 'hardware_acceleration';
  
  // Private instance of SharedPreferences
  late SharedPreferences _prefs;
  
  // Store the current theme mode
  ThemeMode _themeMode = ThemeMode.system;
  
  // Store hardware acceleration preference
  bool _hardwareAcceleration = true;
  
  // Getters
  ThemeMode get themeMode => _themeMode;
  bool get hardwareAcceleration => _hardwareAcceleration;
  
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

      // Retrieve hardware acceleration setting, default to true if not set
      _hardwareAcceleration = _prefs.getBool(_hardwareAccelerationKey) ?? true;
    } catch (e) {
      // Log error and fall back to default values
      print('Error initializing preferences: $e');
      _themeMode = ThemeMode.system;
      _hardwareAcceleration = true;
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

  // Method to change and persist hardware acceleration setting
  Future<void> setHardwareAcceleration(bool enabled) async {
    try {
      // Update the current setting
      _hardwareAcceleration = enabled;
      
      // Persist the setting
      await _prefs.setBool(_hardwareAccelerationKey, enabled);
      
      // Notify listeners of the change
      notifyListeners();
    } catch (e) {
      print('Error saving hardware acceleration setting: $e');
    }
  }
}