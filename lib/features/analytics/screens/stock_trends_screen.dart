import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:food_inventory/common/services/config_service.dart';
import 'package:food_inventory/common/services/error_handler.dart';
import 'package:food_inventory/features/analytics/bloc/stock_trends_bloc.dart';
import 'package:food_inventory/features/analytics/models/time_period.dart';
import 'package:food_inventory/features/analytics/services/analytics_service.dart';
import 'package:food_inventory/features/analytics/widgets/analytics_card.dart';
import 'package:food_inventory/features/analytics/widgets/stock_trends_chart.dart';
import 'package:food_inventory/features/analytics/widgets/time_period_selectors.dart';
import 'package:provider/provider.dart';

class StockTrendsScreen extends StatefulWidget {
  const StockTrendsScreen({super.key});

  @override
  State<StockTrendsScreen> createState() => _StockTrendsScreenState();
}

class _StockTrendsScreenState extends State<StockTrendsScreen> {
  late StockTrendsBloc _stockTrendsBloc;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final analyticsService = Provider.of<AnalyticsService>(context, listen: false);
    _stockTrendsBloc = StockTrendsBloc(analyticsService);
    _stockTrendsBloc.add(const LoadStockTrendsData());
  }

  @override
  void dispose() {
    _stockTrendsBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<StockTrendsBloc>.value(
      value: _stockTrendsBloc,
      child: BlocListener<StockTrendsBloc, StockTrendsState>(
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
          body: RefreshIndicator(
            onRefresh: () async {
              // Preserve the current time period when refreshing
              final currentState = context.read<StockTrendsBloc>().state;
              context.read<StockTrendsBloc>().add(
                LoadStockTrendsData(timePeriod: currentState.timePeriod)
              );
            },
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return BlocBuilder<StockTrendsBloc, StockTrendsState>(
      builder: (context, state) {
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(ConfigService.tinyPadding),
                child: AnalyticsCard(
                  title: 'Stock Trends',
                  icon: Icons.trending_up,
                  titleChild: _buildTimePeriodSelector(context, state),
                  child: state is StockTrendsLoading
                      ? const StockTrendsChart(trendsData: [], isLoading: true)
                      : state is StockTrendsLoaded
                          ? StockTrendsChart(trendsData: state.data.trendData)
                          : const Center(
                              heightFactor: 2,
                              child: Text('No data available'),
                            ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTimePeriodSelector(BuildContext context, StockTrendsState state) {
    return BlocBuilder<StockTrendsBloc, StockTrendsState>(
      buildWhen: (previous, current) => previous.timePeriod != current.timePeriod,
      builder: (context, state) {
        return CompactTimePeriodSelector(
          selectedPeriod: state.timePeriod,
          onPeriodChanged: (period) {
            context.read<StockTrendsBloc>().add(ChangeTimePeriod(period));
          },
        );
      },
    );
  }
}