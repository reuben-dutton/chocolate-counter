// lib/features/analytics/models/time_period.dart

/// Defines time periods for data filtering in analytics
enum TimePeriod {
  allTime,
  lastSixMonths,
  lastMonth,
  lastWeek
}

/// Helper to get a display label for each time period
String getTimePeriodLabel(TimePeriod period) {
  switch (period) {
    case TimePeriod.allTime:
      return 'All Time';
    case TimePeriod.lastSixMonths:
      return 'Last 6 Months';
    case TimePeriod.lastMonth:
      return 'Last Month';
    case TimePeriod.lastWeek:
      return 'Last Week';
  }
}