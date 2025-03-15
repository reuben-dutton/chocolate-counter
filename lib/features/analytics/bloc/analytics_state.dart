import 'package:equatable/equatable.dart';
import 'package:food_inventory/common/services/error_handler.dart';
import 'package:food_inventory/features/analytics/models/analytics_data.dart';

enum AnalyticsType {
  popularItems,
  stockTrends,
  expirationAnalytics,
  salesHistory
}

class AnalyticsState extends Equatable {
  final AppError? error;
  final AnalyticsType selectedType;
  
  const AnalyticsState({
    this.error, 
    this.selectedType = AnalyticsType.popularItems
  });
  
  @override
  List<Object?> get props => [error, selectedType];
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
  List<Object?> get props => [data, error, selectedType];
  
  AnalyticsLoaded copyWith({
    AnalyticsData? data,
    AppError? error,
    AnalyticsType? selectedType,
  }) {
    return AnalyticsLoaded(
      data ?? this.data,
      error: error ?? this.error,
    );
  }

  // Helper getters for data components
  int get totalStockCount => data.totalStockCount;
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