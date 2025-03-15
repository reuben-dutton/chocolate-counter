import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:food_inventory/common/services/error_handler.dart';
import 'package:food_inventory/common/utils/gesture_handler.dart';
import 'package:food_inventory/common/utils/navigation_utils.dart';
import 'package:food_inventory/features/analytics/bloc/analytics_bloc.dart';
import 'package:food_inventory/features/analytics/bloc/analytics_event.dart';
import 'package:food_inventory/features/analytics/bloc/analytics_state.dart';
import 'package:food_inventory/features/analytics/services/analytics_service.dart';
import 'package:food_inventory/features/analytics/widgets/analytics_card.dart';
import 'package:food_inventory/features/analytics/widgets/popular_items_chart.dart';
import 'package:food_inventory/features/settings/screens/settings_screen.dart';
import 'package:provider/provider.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  late AnalyticsBloc _analyticsBloc;
  bool _isFilterVisible = false;

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
          appBar: AppBar(
            title: const Text('Analytics'),
          ),
          body: _buildGestureHandler(context, theme),
        ),
      ),
    );
  }
  
  Widget _buildGestureHandler(BuildContext context, ThemeData theme) {
    // Create gesture handler for this screen
    final gestureHandler = GestureHandler(
      onCreateAction: _handleCreateReport,
      onFilterAction: _toggleFilterPanel,
      onSettingsAction: () => _openSettings(context),
    );
    
    return gestureHandler.wrapWithGestures(
      context,
      _buildContent(context, theme),
      // Disable horizontal swipes since parent handles that
      enableHorizontalSwipe: false, 
    );
  }

  Widget _buildContent(BuildContext context, ThemeData theme) {
    return Builder(
      builder: (context) {
        return Stack(
          children: [
            RefreshIndicator(
              onRefresh: () async {
                BlocProvider.of<AnalyticsBloc>(context).add(const LoadPopularItemsData());
              },
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    floating: true,
                    snap: true,
                    backgroundColor: theme.colorScheme.surface,
                    foregroundColor: theme.colorScheme.onSurface,
                    elevation: 0,
                    automaticallyImplyLeading: false,
                    flexibleSpace: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: _buildAnalyticsTypeSelector(context, theme),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: BlocBuilder<AnalyticsBloc, AnalyticsState>(
                        builder: (context, state) {
                          switch (state.selectedType) {
                            case AnalyticsType.popularItems:
                              return _buildPopularItemsContent(context, state);
                            case AnalyticsType.stockTrends:
                              return _buildStockTrendsContent(context, state);
                            case AnalyticsType.expirationAnalytics:
                              return _buildExpirationAnalyticsContent(context, state);
                            case AnalyticsType.salesHistory:
                              return _buildSalesHistoryContent(context, state);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Filter panel overlay
            if (_isFilterVisible)
              _buildFilterPanel(context, theme),
          ],
        );
      }
    );
  }

  Widget _buildAnalyticsTypeSelector(BuildContext context, ThemeData theme) {
    return BlocBuilder<AnalyticsBloc, AnalyticsState>(
      builder: (context, state) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(30),
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
                      borderRadius: BorderRadius.circular(30),
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
        totalStockCount: 0,
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
        totalStockCount: state.totalStockCount,
        child: PopularItemsChart(
          popularItems: state.data.popularItems,
          totalStockCount: state.data.totalStockCount
        ),
      );
    }
    
    return const AnalyticsCard(
      title: 'Most Popular Items',
      icon: Icons.bar_chart,
      totalStockCount: 0,
      child: Center(
        heightFactor: 2,
        child: Text('No data available'),
      ),
    );
  }

  Widget _buildStockTrendsContent(BuildContext context, AnalyticsState state) {
    int totalStock = 0;
    if (state is AnalyticsLoaded) {
      totalStock = state.totalStockCount;
    }
    
    return AnalyticsCard(
      title: 'Stock Trends',
      icon: Icons.trending_up,
      totalStockCount: totalStock,
      child: const Center(
        heightFactor: 2,
        child: Text('Stock Trends Coming Soon'),
      ),
    );
  }

  Widget _buildExpirationAnalyticsContent(BuildContext context, AnalyticsState state) {
    int totalStock = 0;
    if (state is AnalyticsLoaded) {
      totalStock = state.totalStockCount;
    }
    
    return AnalyticsCard(
      title: 'Expiration Analytics',
      icon: Icons.event_busy,
      totalStockCount: totalStock,
      child: const Center(
        heightFactor: 2,
        child: Text('Expiration Analytics Coming Soon'),
      ),
    );
  }

  Widget _buildSalesHistoryContent(BuildContext context, AnalyticsState state) {
    int totalStock = 0;
    if (state is AnalyticsLoaded) {
      totalStock = state.totalStockCount;
    }
    
    return AnalyticsCard(
      title: 'Sales History',
      icon: Icons.attach_money,
      totalStockCount: totalStock,
      child: const Center(
        heightFactor: 2,
        child: Text('Sales History Coming Soon'),
      ),
    );
  }

  Widget _buildFilterPanel(BuildContext context, ThemeData theme) {
    return GestureDetector(
      onTap: _toggleFilterPanel, // Close panel when tapping outside
      child: Container(
        color: Colors.black.withAlpha(127),
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 100, left: 16, right: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(127),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filter Analytics',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: _toggleFilterPanel,
                    ),
                  ],
                ),
                const Divider(),
                const Text('Date Range:'),
                // Add filter options here
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _toggleFilterPanel,
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        _toggleFilterPanel();
                        // Apply filters here
                      },
                      child: const Text('Apply'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
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
  
  void _toggleFilterPanel() {
    setState(() {
      _isFilterVisible = !_isFilterVisible;
    });
  }
  
  void _handleCreateReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Create custom report feature coming soon'),
        duration: Duration(seconds: 2),
      ),
    );
  }
  
  void _openSettings(BuildContext context) {
    NavigationUtils.navigateWithSlide(
      context,
      const SettingsScreen(),
    );
  }
}