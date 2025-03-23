// lib/features/analytics/screens/analytics_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:food_inventory/common/services/config_service.dart';
import 'package:food_inventory/common/services/error_handler.dart';
import 'package:food_inventory/features/analytics/bloc/analytics_bloc.dart';
import 'package:food_inventory/features/analytics/services/analytics_service.dart';
import 'package:food_inventory/features/analytics/widgets/analytics_card.dart';
import 'package:food_inventory/features/analytics/widgets/expiration/expiration_analytics_widget.dart';
import 'package:food_inventory/features/analytics/widgets/popular_items/popular_items_chart.dart';
import 'package:food_inventory/features/analytics/widgets/popular_items/popular_items_skeleton.dart';
import 'package:food_inventory/features/analytics/widgets/sales_history_widget.dart';
import 'package:food_inventory/features/analytics/widgets/stock_trends/stock_trends_widget.dart';
import 'package:food_inventory/features/analytics/widgets/time_period_selectors.dart';
import 'package:provider/provider.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  late AnalyticsBloc _analyticsBloc;

  @override
  void initState() {
    super.initState();
    final analyticsService = Provider.of<AnalyticsService>(context, listen: false);
    _analyticsBloc = AnalyticsBloc(analyticsService);
    _analyticsBloc.add(const InitializeAnalyticsScreen());
  }

  @override
  void dispose() {
    _analyticsBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _analyticsBloc,
      child: BlocListener<AnalyticsBloc, AnalyticsState>(
        listenWhen: (previous, current) => 
          current.error != null && previous.error != current.error,
        listener: (context, state) {
          if (state.error != null) {
            ErrorHandler.showErrorSnackBar(
              context, 
              state.error!.message, 
              error: state.error!.error
            );
          }
        },
        child: Scaffold(
          body: Builder(
            builder: (context) {
              return RefreshIndicator(
                onRefresh: () async {
                  // Preserve the current time period when refreshing
                  final currentState = context.read<AnalyticsBloc>().state;
                  context.read<AnalyticsBloc>().add(
                    LoadPopularItemsData(timePeriod: currentState.timePeriod)
                  );
                },
                child: Column(
                  children: [
                    // Main content
                    Expanded(
                      child: CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.all(ConfigService.tinyPadding),
                              child: BlocBuilder<AnalyticsBloc, AnalyticsState>(
                                buildWhen: (previous, current) => 
                                  previous.selectedType != current.selectedType || 
                                  previous is! AnalyticsLoaded && current is AnalyticsLoaded || 
                                  previous.timePeriod != current.timePeriod,
                                builder: (context, state) {
                                  return IndexedStack(
                                    index: state.selectedType.index,
                                    children: [
                                      _buildPopularItemsContent(context, state), // Popular Items
                                      StockTrendsWidget(),                      // Stock Trends
                                      ExpirationAnalyticsWidget(),              // Expiration Analytics  
                                      SalesHistoryWidget(),                     // Sales History
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Analytics type selector at the bottom
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(13),
                            offset: const Offset(0, -2),
                            blurRadius: 4,
                          )
                        ],
                      ),
                      padding: EdgeInsets.symmetric(vertical: ConfigService.smallPadding, horizontal: ConfigService.smallPadding),
                      child: _buildAnalyticsTypeSelector(context),
                    ),
                  ],
                ),
              );
            }
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsTypeSelector(BuildContext context) {
    return BlocBuilder<AnalyticsBloc, AnalyticsState>(
      builder: (context, state) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey.withAlpha(ConfigService.alphaLight),
            borderRadius: BorderRadius.circular(ConfigService.borderRadiusLarge),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: AnalyticsType.values.map((type) {
              final isSelected = state.selectedType == type;
              return Expanded(
                child: GestureDetector(
                  onTap: () => context.read<AnalyticsBloc>().add(ChangeAnalyticsType(type)),
                  child: AnimatedContainer(
                    duration: ConfigService.animationDurationFast,
                    padding: EdgeInsets.symmetric(vertical: ConfigService.mediumPadding, horizontal: ConfigService.smallPadding),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? Theme.of(context).colorScheme.primary 
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(ConfigService.borderRadiusLarge),
                    ),
                    child: Text(
                      _getAnalyticsTypeLabel(type),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isSelected 
                            ? Theme.of(context).colorScheme.onPrimary 
                            : Theme.of(context).colorScheme.onSurface,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildPopularItemsContent(BuildContext context, AnalyticsState state) {
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
  }

  String _getAnalyticsTypeLabel(AnalyticsType type) {
    switch (type) {
      case AnalyticsType.popularItems:
        return 'Popular';
      case AnalyticsType.stockTrends:
        return 'Stock';
      case AnalyticsType.expirationAnalytics:
        return 'Expiry';
      case AnalyticsType.salesHistory:
        return 'Sales';
    }
  }
}