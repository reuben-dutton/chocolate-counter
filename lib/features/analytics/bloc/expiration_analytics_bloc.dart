import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:food_inventory/common/services/error_handler.dart';
import 'package:food_inventory/features/analytics/models/expiration_analytics_data.dart';
import 'package:food_inventory/features/analytics/services/analytics_service.dart';

/// State for operation results
class OperationResult extends ExpirationAnalyticsState {
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
abstract class ExpirationAnalyticsEvent extends Equatable {
  const ExpirationAnalyticsEvent();

  @override
  List<Object?> get props => [];
}

class LoadExpirationAnalyticsData extends ExpirationAnalyticsEvent {
  const LoadExpirationAnalyticsData();
}

class ClearOperationState extends ExpirationAnalyticsEvent {
  const ClearOperationState();
}

// Define state
class ExpirationAnalyticsState extends Equatable {
  final AppError? error;
  
  const ExpirationAnalyticsState({
    this.error,
  });
  
  @override
  List<Object?> get props => [error];
}

/// Initial state
class ExpirationAnalyticsInitial extends ExpirationAnalyticsState {
  const ExpirationAnalyticsInitial();
}

/// Loading state
class ExpirationAnalyticsLoading extends ExpirationAnalyticsState {
  const ExpirationAnalyticsLoading();
}

/// State when data is loaded
class ExpirationAnalyticsLoaded extends ExpirationAnalyticsState {
  final ExpirationAnalyticsData data;
  
  const ExpirationAnalyticsLoaded(this.data, {super.error});
  
  @override
  List<Object?> get props => [data, error];
  
  ExpirationAnalyticsLoaded copyWith({
    ExpirationAnalyticsData? data,
    AppError? error,
  }) {
    return ExpirationAnalyticsLoaded(
      data ?? this.data,
      error: error ?? this.error,
    );
  }
}

/// BLoC for expiration analytics
class ExpirationAnalyticsBloc extends Bloc<ExpirationAnalyticsEvent, ExpirationAnalyticsState> {
  final AnalyticsService _analyticsService;

  ExpirationAnalyticsBloc(this._analyticsService) : super(const ExpirationAnalyticsInitial()) {
    on<LoadExpirationAnalyticsData>(_onLoadExpirationAnalyticsData);
    on<ClearOperationState>(_onClearOperationState);
  }

  Future<void> _onLoadExpirationAnalyticsData(
    LoadExpirationAnalyticsData event,
    Emitter<ExpirationAnalyticsState> emit,
  ) async {
    try {
      emit(const ExpirationAnalyticsLoading());
      
      final data = await _analyticsService.getExpirationAnalyticsData();
      
      emit(ExpirationAnalyticsLoaded(data));
    } catch (e, stackTrace) {
      ErrorHandler.logError('Error loading expiration analytics data', e, stackTrace, 'ExpirationAnalyticsBloc');
      
      // If we already had data loaded, keep it but add the error
      if (state is ExpirationAnalyticsLoaded) {
        emit((state as ExpirationAnalyticsLoaded).copyWith(
          error: AppError(
            message: 'Failed to load expiration analytics data',
            error: e,
            stackTrace: stackTrace,
            source: 'ExpirationAnalyticsBloc'
          ),
        ));
      } else {
        // Create a minimal valid data structure to avoid null errors in the UI
        final emptyData = ExpirationAnalyticsData(
          thisWeekCount: 0,
          nextWeekCount: 0,
          thisMonthCount: 0,
          nextMonthCount: 0,
          beyondCount: 0,
          expiredCount: 0,
          thisWeekItems: const [],
          nextWeekItems: const [],
          thisMonthItems: const [],
          nextMonthItems: const [],
          beyondItems: const [],
          expiredItems: const [],
        );
        
        emit(ExpirationAnalyticsLoaded(
          emptyData,
          error: AppError(
            message: 'Failed to load expiration analytics data',
            error: e,
            stackTrace: stackTrace,
            source: 'ExpirationAnalyticsBloc'
          ),
        ));
      }
    }
  }

  void _onClearOperationState(
    ClearOperationState event,
    Emitter<ExpirationAnalyticsState> emit,
  ) {
    if (state is OperationResult) {
      emit(const ExpirationAnalyticsInitial());
    }
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