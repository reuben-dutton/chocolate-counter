import 'package:equatable/equatable.dart';

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

/// Event to clear operation state
class ClearOperationState extends AnalyticsEvent {
  const ClearOperationState();
}