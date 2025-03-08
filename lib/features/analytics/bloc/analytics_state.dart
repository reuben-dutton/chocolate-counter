import 'package:equatable/equatable.dart';
import 'package:food_inventory/common/services/error_handler.dart';
import 'package:food_inventory/features/analytics/models/analytics_data.dart';

/// Base class for analytics states
abstract class AnalyticsState extends Equatable {
  final AppError? error;
  
  const AnalyticsState({this.error});
  
  @override
  List<Object?> get props => [error];
}

/// Initial state
class AnalyticsInitial extends AnalyticsState {
  const AnalyticsInitial();
}

/// Loading state
class AnalyticsLoading extends AnalyticsState {
  const AnalyticsLoading();
}

/// State when data is loaded
class AnalyticsLoaded extends AnalyticsState {
  final AnalyticsData data;
  
  const AnalyticsLoaded(this.data, {super.error});
  
  @override
  List<Object?> get props => [data, error];
  
  AnalyticsLoaded copyWith({
    AnalyticsData? data,
    AppError? error,
  }) {
    return AnalyticsLoaded(
      data ?? this.data,
      error: error ?? this.error,
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