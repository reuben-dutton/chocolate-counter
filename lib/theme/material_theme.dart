import 'package:flutter/material.dart';
import 'package:food_inventory/theme/theme_loader.dart';

class MaterialTheme {
  final TextTheme textTheme;

  const MaterialTheme(this.textTheme);

  ThemeData light(String themeName) {
    final theme = ThemeLoader.getTheme(themeName);
    return _createTheme(theme.lightScheme);
  }

  ThemeData dark(String themeName) {
    final theme = ThemeLoader.getTheme(themeName);
    return _createTheme(theme.darkScheme);
  }

  ThemeData _createTheme(ColorScheme colorScheme) => ThemeData(
     useMaterial3: true,
     brightness: colorScheme.brightness,
     colorScheme: colorScheme,
     textTheme: textTheme.apply(
       bodyColor: colorScheme.onSurface,
       displayColor: colorScheme.onSurface,
     ),
     scaffoldBackgroundColor: colorScheme.surface,
     canvasColor: colorScheme.surface,
  );
}