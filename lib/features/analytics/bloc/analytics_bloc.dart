import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:food_inventory/common/services/error_handler.dart';
import 'package:food_inventory/features/analytics/models/analytics_data.dart';
import 'package:food_inventory/features/analytics/models/time_period.dart';
import 'package:food_inventory/features/analytics/services/analytics_service.dart';

// Define events
abstract class AnalyticsEvent extends Equatable {
  const AnalyticsEvent();

  @override
  List<Object?> get props => [];
}

class InitializeAnalyticsScreen extends AnalyticsEvent {
  const InitializeAnalyticsScreen();
}

class LoadPopularItemsData extends AnalyticsEvent {
  final TimePeriod timePeriod;
  
  const LoadPopularItemsData({this.timePeriod = TimePeriod.allTime});
  
  @override
  List<Object?> get props => [timePeriod];
}

class ChangeAnalyticsType extends AnalyticsEvent {
  final AnalyticsType type;
  
  const ChangeAnalyticsType(this.type);
  
  @override
  List<Object?> get props => [type];
}

class ChangeTimePeriod extends AnalyticsEvent {
  final TimePeriod timePeriod;
  
  const ChangeTimePeriod(this.timePeriod);
  
  @override
  List<Object?> get props => [timePeriod];
}

class ClearOperationState extends AnalyticsEvent {
  const ClearOperationState();
}

// Define state
enum AnalyticsType {
  popularItems,
  stockTrends,
  expirationAnalytics,
  salesHistory
}

class AnalyticsState extends Equatable {
  final AppError? error;
  final AnalyticsType selectedType;
  final TimePeriod timePeriod;
  
  const AnalyticsState({
    this.error, 
    this.selectedType = AnalyticsType.popularItems,
    this.timePeriod = TimePeriod.allTime,
  });
  
  @override
  List<Object?> get props => [error, selectedType, timePeriod];
}

/// Initial state
class AnalyticsInitial extends AnalyticsState {
  const AnalyticsInitial();
}

/// Loading state
class AnalyticsLoading extends AnalyticsState {
  const AnalyticsLoading({TimePeriod timePeriod = TimePeriod.allTime}) 
      : super(timePeriod: timePeriod);
}

/// State when data is loaded
class AnalyticsLoaded extends AnalyticsState {
  final AnalyticsData data;
  
  const AnalyticsLoaded(
    this.data, {
    super.error,
    super.timePeriod = TimePeriod.allTime
  });
  
  @override
  List<Object?> get props => [data, error, timePeriod];
  
  AnalyticsLoaded copyWith({
    AnalyticsData? data,
    AppError? error,
    TimePeriod? timePeriod,
  }) {
    return AnalyticsLoaded(
      data ?? this.data,
      error: error ?? this.error,
      timePeriod: timePeriod ?? this.timePeriod,
    );
  }
}

/// State for operation results
class OperationResult extends AnalyticsState {
  final bool success;
  
  const OperationResult({
    required this.success,
    super.error,
  });
  
  @override
  List<Object?> get props => [success, error];
}

class AnalyticsBloc extends Bloc<AnalyticsEvent, AnalyticsState> {
  final AnalyticsService _analyticsService;

  AnalyticsBloc(this._analyticsService) : super(const AnalyticsState()) {
    on<InitializeAnalyticsScreen>(_onInitializeAnalyticsScreen);
    on<LoadPopularItemsData>(_onLoadPopularItemsData);
    on<ChangeAnalyticsType>(_onChangeAnalyticsType);
    on<ChangeTimePeriod>(_onChangeTimePeriod);
    on<ClearOperationState>(_onClearOperationState);
  }

  Future<void> _onInitializeAnalyticsScreen(
    InitializeAnalyticsScreen event,
    Emitter<AnalyticsState> emit,
  ) async {
    // Only load if we're not already loading and don't have data
    if (state is! AnalyticsLoaded && state is! AnalyticsLoading) {
      add(const LoadPopularItemsData());
    }
  }

  Future<void> _onLoadPopularItemsData(
    LoadPopularItemsData event,
    Emitter<AnalyticsState> emit,
  ) async {
    try {
      emit(AnalyticsLoading(timePeriod: event.timePeriod));
      
      final data = await _getDataForTimePeriod(event.timePeriod);
      
      emit(AnalyticsLoaded(data, timePeriod: event.timePeriod));
    } catch (e, stackTrace) {
      ErrorHandler.logError('Error loading analytics data', e, stackTrace, 'AnalyticsBloc');
      
      // If we already had data loaded, keep it but add the error
      if (state is AnalyticsLoaded) {
        emit((state as AnalyticsLoaded).copyWith(
          error: AppError(
            message: 'Failed to load analytics data',
            error: e,
            stackTrace: stackTrace,
            source: 'AnalyticsBloc'
          ),
        ));
      } else {
        emit(AnalyticsLoaded(
          const AnalyticsData(popularItems: []),
          error: AppError(
            message: 'Failed to load analytics data',
            error: e,
            stackTrace: stackTrace,
            source: 'AnalyticsBloc'
          ),
          timePeriod: event.timePeriod,
        ));
      }
    }
  }

  Future<void> _onChangeAnalyticsType(
    ChangeAnalyticsType event,
    Emitter<AnalyticsState> emit,
  ) async {
    // Preserve the current time period when changing analytics type
    final currentTimePeriod = state.timePeriod;
    emit(AnalyticsState(selectedType: event.type, timePeriod: currentTimePeriod));
    
    // Load data for the specific analytics type
    switch (event.type) {
      case AnalyticsType.popularItems:
        add(LoadPopularItemsData(timePeriod: currentTimePeriod));
      default:
        // Add placeholder loading methods for other types later
        break;
    }
  }

  Future<void> _onChangeTimePeriod(
    ChangeTimePeriod event,
    Emitter<AnalyticsState> emit,
  ) async {
    if (state.timePeriod != event.timePeriod) {
      // Update state and reload data with new time period
      add(LoadPopularItemsData(timePeriod: event.timePeriod));
    }
  }

  void _onClearOperationState(
    ClearOperationState event,
    Emitter<AnalyticsState> emit,
  ) {
    // If we're in OperationResult state, go back to initial state
    // to avoid sticky operation result
    if (state is OperationResult) {
      emit(const AnalyticsInitial());
    }
  }

  /// Get data for the selected time period
  Future<AnalyticsData> _getDataForTimePeriod(TimePeriod period) async {
    DateTime? startDate;
    
    final now = DateTime.now();
    
    switch (period) {
      case TimePeriod.lastWeek:
        startDate = now.subtract(const Duration(days: 7));
      case TimePeriod.lastMonth:
        startDate = DateTime(now.year, now.month - 1, now.day);
      case TimePeriod.lastSixMonths:
        startDate = DateTime(now.year, now.month - 6, now.day);
      case TimePeriod.allTime:
        startDate = null; // No filter
    }
    
    return _analyticsService.getPopularItemsData(startDate: startDate);
  }

  /// Handle an error with a BuildContext for UI feedback
  void handleError(BuildContext context, AppError error) {
    ErrorHandler.showErrorSnackBar(
      context, 
      error.message,
      error: error.error
    );
  }
}