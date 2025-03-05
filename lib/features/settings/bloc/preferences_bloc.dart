import 'dart:async';

import 'package:flutter/material.dart';
import 'package:food_inventory/common/bloc/bloc_base.dart';
import 'package:food_inventory/common/services/preferences_service.dart';

/// BLoC for application preferences
class PreferencesBloc extends BlocBase {
  final PreferencesService _preferencesService;

  // Stream for theme mode
  final _themeModeController = StreamController<ThemeMode>.broadcast();
  Stream<ThemeMode> get themeMode => _themeModeController.stream;

  PreferencesBloc(this._preferencesService) {
    // Initialize with current theme from service
    _themeModeController.add(_preferencesService.themeMode);
    
    // Listen to changes in the preferences service
    _preferencesService.addListener(_onPreferencesChanged);
  }

  void _onPreferencesChanged() {
    // Update the stream when preferences change
    _themeModeController.add(_preferencesService.themeMode);
  }

  /// Set theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    await _preferencesService.setThemeMode(mode);
    // No need to manually add to stream, the service listener will handle it
  }

  @override
  void dispose() {
    _themeModeController.close();
    _preferencesService.removeListener(_onPreferencesChanged);
  }
}