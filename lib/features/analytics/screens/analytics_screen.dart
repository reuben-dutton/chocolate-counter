import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:food_inventory/common/services/error_handler.dart';
import 'package:food_inventory/features/analytics/bloc/analytics_bloc.dart';
import 'package:food_inventory/features/analytics/bloc/analytics_event.dart';
import 'package:food_inventory/features/analytics/bloc/analytics_state.dart';
import 'package:food_inventory/features/analytics/services/analytics_service.dart';
import 'package:food_inventory/features/analytics/widgets/analytics_card.dart';
import 'package:food_inventory/features/analytics/widgets/popular_items_chart.dart';
import 'package:provider/provider.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  late AnalyticsBloc _analyticsBloc;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final analyticsService = Provider.of<AnalyticsService>(context, listen: false);
    _analyticsBloc = AnalyticsBloc(analyticsService);
    _analyticsBloc.add(const LoadPopularItemsData());
  }

  @override
  void dispose() {
    _analyticsBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocProvider<AnalyticsBloc>.value(
      value: _analyticsBloc,
      child: BlocListener<AnalyticsBloc, AnalyticsState>(
        listenWhen: (previous, current) => current.error != null && previous.error != current.error,
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
                  BlocProvider.of<AnalyticsBloc>(context).add(const LoadPopularItemsData());
                },
                child: Column(
                  children: [
                    // Main content
                    Expanded(
                      child: CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: BlocBuilder<AnalyticsBloc, AnalyticsState>(
                                builder: (context, state) {
                                  switch (state.selectedType) {
                                    case AnalyticsType.popularItems:
                                      return _buildPopularItemsContent(context, state);
                                    case AnalyticsType.stockTrends:
                                      return _buildStockTrendsContent();
                                    case AnalyticsType.expirationAnalytics:
                                      return _buildExpirationAnalyticsContent();
                                    case AnalyticsType.salesHistory:
                                      return _buildSalesHistoryContent();
                                  }
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
                        color: theme.colorScheme.surface,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(13),
                            offset: const Offset(0, -2),
                            blurRadius: 4,
                          )
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      child: _buildAnalyticsTypeSelector(context, theme),
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

  Widget _buildAnalyticsTypeSelector(BuildContext context, ThemeData theme) {
    return BlocBuilder<AnalyticsBloc, AnalyticsState>(
      builder: (context, state) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey.withAlpha(25),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: AnalyticsType.values.map((type) {
              final isSelected = state.selectedType == type;
              return Expanded(
                child: GestureDetector(
                  onTap: () => context.read<AnalyticsBloc>().add(ChangeAnalyticsType(type)),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? theme.colorScheme.primary 
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getAnalyticsTypeLabel(type),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isSelected 
                            ? theme.colorScheme.onPrimary 
                            : theme.colorScheme.onSurface,
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
    if (state is AnalyticsLoading) {
      return const AnalyticsCard(
        title: 'Most Popular Items',
        icon: Icons.bar_chart,
        child: Center(
          heightFactor: 2,
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (state is AnalyticsLoaded) {
      return AnalyticsCard(
        title: 'Most Popular Items',
        icon: Icons.bar_chart,
        child: PopularItemsChart(
          popularItems: state.data.popularItems,
          totalStockCount: state.data.totalStockCount,
        ),
      );
    }
    
    return const AnalyticsCard(
      title: 'Most Popular Items',
      icon: Icons.bar_chart,
      child: Center(
        heightFactor: 2,
        child: Text('No data available'),
      ),
    );
  }

  Widget _buildStockTrendsContent() {
    return const AnalyticsCard(
      title: 'Stock Trends',
      icon: Icons.trending_up,
      child: Center(
        heightFactor: 2,
        child: Text('Stock Trends Coming Soon'),
      ),
    );
  }

  Widget _buildExpirationAnalyticsContent() {
    return const AnalyticsCard(
      title: 'Expiration Analytics',
      icon: Icons.event_busy,
      child: Center(
        heightFactor: 2,
        child: Text('Expiration Analytics Coming Soon'),
      ),
    );
  }

  Widget _buildSalesHistoryContent() {
    return const AnalyticsCard(
      title: 'Sales History',
      icon: Icons.attach_money,
      child: Center(
        heightFactor: 2,
        child: Text('Sales History Coming Soon'),
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