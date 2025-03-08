import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:food_inventory/common/services/error_handler.dart';
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
            actions: [
              IconButton(
                icon: const Icon(Icons.settings, size: 24),
                onPressed: () => _openSettings(context),
              ),
            ],
          ),
          body: Builder(
            builder: (context) {
              return RefreshIndicator(
                onRefresh: () async {
                  BlocProvider.of<AnalyticsBloc>(context).add(const LoadPopularItemsData());
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Popular Items Chart
                        BlocBuilder<AnalyticsBloc, AnalyticsState>(
                          buildWhen: (previous, current) => 
                            current is AnalyticsLoaded || 
                            current is AnalyticsLoading && previous is! AnalyticsLoading,
                          builder: (context, state) {
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
                                ),
                              );
                            }
                            
                            // Initial state or error state
                            return const AnalyticsCard(
                              title: 'Most Popular Items',
                              icon: Icons.bar_chart,
                              child: Center(
                                heightFactor: 2,
                                child: Text('No data available'),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
          ),
        ),
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