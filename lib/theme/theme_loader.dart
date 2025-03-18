import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AppThemeData {
  final String name;
  final String description;
  final IconData icon;
  final ColorScheme lightScheme;
  final ColorScheme darkScheme;

  AppThemeData({
    required this.name,
    required this.description,
    required this.icon,
    required this.lightScheme,
    required this.darkScheme,
  });
}

class ThemeLoader {
  static const String _themeDirectory = 'assets/themes/';
  static final Map<String, AppThemeData> _cachedThemes = {};
  
  // List of available theme files
  static final List<String> _themeFiles = [
    'standard-theme.json',
    'evening-theme.json',
    'desert-theme.json',
    'iceberg-theme.json',
    'petrichor-theme.json',
    'cacao-theme.json'
  ];
  
  // Get list of available themes
  static List<String> get availableThemes => _themeFiles
      .map((file) => file.replaceAll('-theme.json', ''))
      .toList();
  
  // Load a specific theme by name
  static Future<AppThemeData> loadTheme(String themeName) async {
    // Check if theme is already cached
    if (_cachedThemes.containsKey(themeName)) {
      return _cachedThemes[themeName]!;
    }
    
    final fileName = '$themeName-theme.json';
    final jsonString = await rootBundle.loadString('$_themeDirectory$fileName');
    final Map<String, dynamic> jsonData = json.decode(jsonString);
    
    // Parse the theme data
    final name = jsonData['name'] ?? themeName;
    final description = jsonData['description'] ?? 'Custom theme';
    
    // Default icon based on theme name
    IconData icon;
    switch (themeName) {
      case 'standard':
        icon = Icons.circle;
      case 'evening':
        icon = FontAwesomeIcons.cloudMoon;
      case 'desert':
        icon = FontAwesomeIcons.hourglassHalf;
      case 'iceberg':
        icon = FontAwesomeIcons.icicles;
      case 'petrichor':
        icon = Icons.water_drop;
      case 'cacao':
        icon = FontAwesomeIcons.mugHot;
      default:
        icon = Icons.color_lens;
    }

    // Parse light scheme from new format
    final lightSchemeData = jsonData['schemes']['light'];
    final lightScheme = _parseColorScheme(lightSchemeData, Brightness.light);
    
    // Parse dark scheme from new format
    final darkSchemeData = jsonData['schemes']['dark'];
    final darkScheme = _parseColorScheme(darkSchemeData, Brightness.dark);
    
    // Create the theme data
    final themeData = AppThemeData(
      name: name,
      description: description,
      icon: icon,
      lightScheme: lightScheme,
      darkScheme: darkScheme,
    );
    
    // Cache the theme data
    _cachedThemes[themeName] = themeData;
    
    return themeData;
  }

  // Parse color scheme from new format
  static ColorScheme _parseColorScheme(Map<String, dynamic> schemeData, Brightness brightness) {
    return ColorScheme(
      brightness: brightness,
      primary: _parseColor(schemeData['primary']),
      surfaceTint: _parseColor(schemeData['surfaceTint']),
      onPrimary: _parseColor(schemeData['onPrimary']),
      primaryContainer: _parseColor(schemeData['primaryContainer']),
      onPrimaryContainer: _parseColor(schemeData['onPrimaryContainer']),
      secondary: _parseColor(schemeData['secondary']),
      onSecondary: _parseColor(schemeData['onSecondary']),
      secondaryContainer: _parseColor(schemeData['secondaryContainer']),
      onSecondaryContainer: _parseColor(schemeData['onSecondaryContainer']),
      tertiary: _parseColor(schemeData['tertiary']),
      onTertiary: _parseColor(schemeData['onTertiary']),
      tertiaryContainer: _parseColor(schemeData['tertiaryContainer']),
      onTertiaryContainer: _parseColor(schemeData['onTertiaryContainer']),
      error: _parseColor(schemeData['error']),
      onError: _parseColor(schemeData['onError']),
      errorContainer: _parseColor(schemeData['errorContainer']),
      onErrorContainer: _parseColor(schemeData['onErrorContainer']),
      surface: _parseColor(schemeData['surface']),
      onSurface: _parseColor(schemeData['onSurface']),
      surfaceContainerLowest: _parseColor(schemeData['surfaceContainerLowest']),
      surfaceContainerLow: _parseColor(schemeData['surfaceContainerLow']),
      surfaceContainer: _parseColor(schemeData['surfaceContainer']),
      surfaceContainerHigh: _parseColor(schemeData['surfaceContainerHigh']),
      surfaceContainerHighest: _parseColor(schemeData['surfaceContainerHighest']),
      outline: _parseColor(schemeData['outline']),
      outlineVariant: _parseColor(schemeData['outlineVariant']),
      shadow: _parseColor(schemeData['shadow']),
      scrim: _parseColor(schemeData['scrim']),
      inverseSurface: _parseColor(schemeData['inverseSurface']),
      onInverseSurface: _parseColor(schemeData['inverseOnSurface']),
      inversePrimary: _parseColor(schemeData['inversePrimary']),
      surfaceDim: _parseColor(schemeData['surfaceDim']),
      surfaceBright: _parseColor(schemeData['surfaceBright']),
    );
  }
  
  // Parse color from hex string
  static Color _parseColor(String hexString) {
    if (hexString.startsWith('#')) {
      if (hexString.length == 7) {
        // Format #RRGGBB
        return Color(int.parse('FF${hexString.substring(1)}', radix: 16));
      } else if (hexString.length == 9) {
        // Format #AARRGGBB
        return Color(int.parse(hexString.substring(1), radix: 16));
      }
    }
    // Default fallback
    return Colors.black;
  }
  
  // Initialize all themes at app startup
  static Future<void> preloadThemes() async {
    for (final themeName in availableThemes) {
      await loadTheme(themeName);
    }
  }
  
  // Get a theme by name
  static AppThemeData getTheme(String themeName) {
    if (!_cachedThemes.containsKey(themeName)) {
      // return _cachedThemes['standard']!;
      throw Exception('Theme not loaded: $themeName');
    }
    return _cachedThemes[themeName]!;
  }
  
  // Get all loaded themes
  static Map<String, AppThemeData> get themes => _cachedThemes;
}