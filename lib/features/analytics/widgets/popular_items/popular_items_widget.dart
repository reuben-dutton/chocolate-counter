import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:food_inventory/common/services/config_service.dart';
import 'package:food_inventory/common/services/error_handler.dart';
import 'package:food_inventory/features/analytics/bloc/analytics_bloc.dart';
import 'package:food_inventory/features/analytics/models/time_period.dart';
import 'package:food_inventory/features/analytics/widgets/analytics_card.dart';
import 'package:food_inventory/features/analytics/widgets/popular_items/popular_items_chart.dart';
import 'package:food_inventory/features/analytics/widgets/popular_items/popular_items_skeleton.dart';
import 'package:food_inventory/features/analytics/widgets/time_period_selectors.dart';

class PopularItemsWidget extends StatelessWidget {
  const PopularItemsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AnalyticsBloc, AnalyticsState>(
      buildWhen: (previous, current) => 
        (current is AnalyticsLoading && previous is! AnalyticsLoading) || 
        (current is AnalyticsLoaded && (previous is! AnalyticsLoaded || 
            previous.props != current.props)),
      builder: (context, state) {
        // Create time period selector
        final periodSelector = BlocBuilder<AnalyticsBloc, AnalyticsState>(
          buildWhen: (previous, current) => previous.timePeriod != current.timePeriod,
          builder: (context, state) {
            return CompactTimePeriodSelector(
              selectedPeriod: state.timePeriod,
              onPeriodChanged: (period) {
                context.read<AnalyticsBloc>().add(ChangeTimePeriod(period));
              },
            );
          },
        );

        if (state is AnalyticsLoading) {
          return AnalyticsCard(
            title: 'At A Glance',
            icon: Icons.bar_chart,
            titleChild: periodSelector,
            child: const PopularItemsSkeleton(),
          );
        }
        
        if (state is AnalyticsLoaded) {
          return AnalyticsCard(
            title: 'At A Glance',
            icon: Icons.bar_chart,
            titleChild: periodSelector,
            child: PopularItemsChart(
              popularItems: state.data.popularItems,
              totalStockCount: state.data.totalStockCount,
            ),
          );
        }
        
        return AnalyticsCard(
          title: 'At A Glance',
          icon: Icons.bar_chart,
          titleChild: periodSelector,
          child: const Center(
            heightFactor: 2,
            child: Text('No data available'),
          ),
        );
      },
    );
  }
}