import 'package:equatable/equatable.dart';
import 'package:food_inventory/features/analytics/bloc/analytics_state.dart';

/// Base class for analytics events
abstract class AnalyticsEvent extends Equatable {
  const AnalyticsEvent();

  @override
  List<Object?> get props => [];
}

/// Event to initialize analytics screen
class InitializeAnalyticsScreen extends AnalyticsEvent {
  const InitializeAnalyticsScreen();
}

/// Event to load popular items data
class LoadPopularItemsData extends AnalyticsEvent {
  const LoadPopularItemsData();
}

/// Event to load stock trends data
class LoadStockTrendsData extends AnalyticsEvent {
  const LoadStockTrendsData();
}

/// Event to clear operation state
class ClearOperationState extends AnalyticsEvent {
  const ClearOperationState();
}

/// Event to change analytics type
class ChangeAnalyticsType extends AnalyticsEvent {
  final AnalyticsType type;
  
  const ChangeAnalyticsType(this.type);

  @override
  List<Object?> get props => [type];
}