import 'package:flutter/material.dart';
import 'package:food_inventory/features/analytics/models/expiration_analytics_data.dart';
import 'package:food_inventory/features/analytics/widgets/expiration/expiration_analytics_view.dart';

/// A component that displays expiration analytics data.
/// This is now a wrapper around the ExpirationAnalyticsView which uses separated components.
class ExpirationAnalyticsChart extends StatelessWidget {
  final ExpirationAnalyticsData? data;
  final bool isLoading;

  const ExpirationAnalyticsChart({
    super.key,
    this.data,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ExpirationAnalyticsView(
      data: data,
      isLoading: isLoading,
    );
  }
}