import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:food_inventory/common/services/preferences_service.dart';

// Define events
abstract class PreferencesEvent extends Equatable {
  const PreferencesEvent();

  @override
  List<Object?> get props => [];
}

class SetThemeMode extends PreferencesEvent {
  final ThemeMode themeMode;

  const SetThemeMode(this.themeMode);

  @override
  List<Object?> get props => [themeMode];
}

class SetHardwareAcceleration extends PreferencesEvent {
  final bool enabled;

  const SetHardwareAcceleration(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

// Define state
class PreferencesState extends Equatable {
  final ThemeMode themeMode;
  final bool hardwareAcceleration;

  const PreferencesState({
    this.themeMode = ThemeMode.system,
    this.hardwareAcceleration = true,
  });

  PreferencesState copyWith({
    ThemeMode? themeMode,
    bool? hardwareAcceleration,
  }) {
    return PreferencesState(
      themeMode: themeMode ?? this.themeMode,
      hardwareAcceleration: hardwareAcceleration ?? this.hardwareAcceleration,
    );
  }

  @override
  List<Object?> get props => [themeMode, hardwareAcceleration];
}

/// BLoC for application preferences
class PreferencesBloc extends Bloc<PreferencesEvent, PreferencesState> {
  final PreferencesService _preferencesService;

  PreferencesBloc(this._preferencesService) 
      : super(PreferencesState(
          themeMode: _preferencesService.themeMode,
          hardwareAcceleration: _preferencesService.hardwareAcceleration,
        )) {
    // Set up listener for preferences changes
    _preferencesService.addListener(_onPreferencesChanged);
    
    // Event handlers
    on<SetThemeMode>(_onSetThemeMode);
    on<SetHardwareAcceleration>(_onSetHardwareAcceleration);
  }

  void _onPreferencesChanged() {
    // Update the state when preferences change externally
    emit(state.copyWith(
      themeMode: _preferencesService.themeMode,
      hardwareAcceleration: _preferencesService.hardwareAcceleration,
    ));
  }

  Future<void> _onSetThemeMode(
    SetThemeMode event, 
    Emitter<PreferencesState> emit,
  ) async {
    // Update the service
    await _preferencesService.setThemeMode(event.themeMode);
    
    // Note: We don't need to emit here as the service listener will handle it
  }

  Future<void> _onSetHardwareAcceleration(
    SetHardwareAcceleration event, 
    Emitter<PreferencesState> emit,
  ) async {
    // Update the service
    await _preferencesService.setHardwareAcceleration(event.enabled);
    
    // Note: We don't need to emit here as the service listener will handle it
  }

  @override
  Future<void> close() {
    // Remove listener when bloc is closed
    _preferencesService.removeListener(_onPreferencesChanged);
    return super.close();
  }
}