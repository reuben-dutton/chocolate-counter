import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:food_inventory/common/services/error_handler.dart';
import 'package:food_inventory/features/analytics/bloc/analytics_event.dart';
import 'package:food_inventory/features/analytics/bloc/analytics_state.dart';
import 'package:food_inventory/features/analytics/models/analytics_data.dart';
import 'package:food_inventory/features/analytics/services/analytics_service.dart';

/// BLoC for analytics management
class AnalyticsBloc extends Bloc<AnalyticsEvent, AnalyticsState> {
  final AnalyticsService _analyticsService;

  AnalyticsBloc(this._analyticsService) : super(const AnalyticsInitial()) {
    on<InitializeAnalyticsScreen>(_onInitializeAnalyticsScreen);
    on<LoadPopularItemsData>(_onLoadPopularItemsData);
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
      emit(const AnalyticsLoading());
      
      final data = await _analyticsService.getPopularItemsData();
      
      emit(AnalyticsLoaded(data));
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
        ));
      }
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

  /// Handle an error with a BuildContext for UI feedback
  void handleError(BuildContext context, AppError error) {
    ErrorHandler.showErrorSnackBar(
      context, 
      error.message,
      error: error.error
    );
  }
}