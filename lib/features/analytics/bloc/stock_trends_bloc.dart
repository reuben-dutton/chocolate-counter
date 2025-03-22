import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:food_inventory/common/services/error_handler.dart';
import 'package:food_inventory/features/analytics/models/stock_trends_data.dart';
import 'package:food_inventory/features/analytics/models/time_period.dart';
import 'package:food_inventory/features/analytics/services/analytics_service.dart';

/// State for operation results
class OperationResult extends StockTrendsState {
  final bool success;
  final OperationType operationType;
  
  const OperationResult({
    required this.success,
    required this.operationType,
    super.error,
  });
  
  @override
  List<Object?> get props => [success, operationType, error];
}

enum OperationType { update, create, delete }

// Define events
abstract class StockTrendsEvent extends Equatable {
  const StockTrendsEvent();

  @override
  List<Object?> get props => [];
}

class LoadStockTrendsData extends StockTrendsEvent {
  final TimePeriod timePeriod;
  
  const LoadStockTrendsData({this.timePeriod = TimePeriod.allTime});
  
  @override
  List<Object?> get props => [timePeriod];
}

class ChangeTimePeriod extends StockTrendsEvent {
  final TimePeriod timePeriod;
  
  const ChangeTimePeriod(this.timePeriod);
  
  @override
  List<Object?> get props => [timePeriod];
}

class ClearOperationState extends StockTrendsEvent {
  const ClearOperationState();
}

// Define state
class StockTrendsState extends Equatable {
  final AppError? error;
  final TimePeriod timePeriod;
  
  const StockTrendsState({
    this.error, 
    this.timePeriod = TimePeriod.allTime,
  });
  
  @override
  List<Object?> get props => [error, timePeriod];
}

/// Initial state
class StockTrendsInitial extends StockTrendsState {
  const StockTrendsInitial();
}

/// Loading state
class StockTrendsLoading extends StockTrendsState {
  const StockTrendsLoading({TimePeriod timePeriod = TimePeriod.allTime}) 
      : super(timePeriod: timePeriod);
}

/// State when data is loaded
class StockTrendsLoaded extends StockTrendsState {
  final StockTrendsData data;
  
  const StockTrendsLoaded(
    this.data, {
    super.error,
    super.timePeriod = TimePeriod.allTime
  });
  
  @override
  List<Object?> get props => [data, error, timePeriod];
  
  StockTrendsLoaded copyWith({
    StockTrendsData? data,
    AppError? error,
    TimePeriod? timePeriod,
  }) {
    return StockTrendsLoaded(
      data ?? this.data,
      error: error ?? this.error,
      timePeriod: timePeriod ?? this.timePeriod,
    );
  }
}

/// BLoC for stock trends analytics
class StockTrendsBloc extends Bloc<StockTrendsEvent, StockTrendsState> {
  final AnalyticsService _analyticsService;

  StockTrendsBloc(this._analyticsService) : super(const StockTrendsInitial()) {
    on<LoadStockTrendsData>(_onLoadStockTrendsData);
    on<ChangeTimePeriod>(_onChangeTimePeriod);
    on<ClearOperationState>(_onClearOperationState);
  }

  Future<void> _onLoadStockTrendsData(
    LoadStockTrendsData event,
    Emitter<StockTrendsState> emit,
  ) async {
    try {
      emit(StockTrendsLoading(timePeriod: event.timePeriod));
      
      final data = await _getDataForTimePeriod(event.timePeriod);
      
      emit(StockTrendsLoaded(data, timePeriod: event.timePeriod));
    } catch (e, stackTrace) {
      ErrorHandler.logError('Error loading stock trends data', e, stackTrace, 'StockTrendsBloc');
      
      // If we already had data loaded, keep it but add the error
      if (state is StockTrendsLoaded) {
        emit((state as StockTrendsLoaded).copyWith(
          error: AppError(
            message: 'Failed to load stock trends data',
            error: e,
            stackTrace: stackTrace,
            source: 'StockTrendsBloc'
          ),
        ));
      } else {
        emit(StockTrendsLoaded(
          const StockTrendsData(trendData: []),
          error: AppError(
            message: 'Failed to load stock trends data',
            error: e,
            stackTrace: stackTrace,
            source: 'StockTrendsBloc'
          ),
          timePeriod: event.timePeriod,
        ));
      }
    }
  }

  Future<void> _onChangeTimePeriod(
    ChangeTimePeriod event,
    Emitter<StockTrendsState> emit,
  ) async {
    if (state.timePeriod != event.timePeriod) {
      // Update state and reload data with new time period
      add(LoadStockTrendsData(timePeriod: event.timePeriod));
    }
  }

  void _onClearOperationState(
    ClearOperationState event,
    Emitter<StockTrendsState> emit,
  ) {
    if (state is OperationResult) {
      emit(const StockTrendsInitial());
    }
  }

  /// Get data for the selected time period
  Future<StockTrendsData> _getDataForTimePeriod(TimePeriod period) async {
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
    
    return _analyticsService.getStockTrendsData(startDate: startDate);
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