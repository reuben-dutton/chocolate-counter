import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:food_inventory/common/services/config_service.dart';
import 'package:food_inventory/common/services/error_handler.dart';
import 'package:food_inventory/features/analytics/bloc/expiration_analytics_bloc.dart';
import 'package:food_inventory/features/analytics/services/analytics_service.dart';
import 'package:food_inventory/features/analytics/widgets/analytics_card.dart';
import 'package:food_inventory/features/analytics/widgets/expiration_analytics_chart.dart';
import 'package:provider/provider.dart';

class ExpirationAnalyticsScreen extends StatefulWidget {
  const ExpirationAnalyticsScreen({super.key});

  @override
  State<ExpirationAnalyticsScreen> createState() => _ExpirationAnalyticsScreenState();
}

class _ExpirationAnalyticsScreenState extends State<ExpirationAnalyticsScreen> {
  late ExpirationAnalyticsBloc _expirationAnalyticsBloc;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final analyticsService = Provider.of<AnalyticsService>(context, listen: false);
    _expirationAnalyticsBloc = ExpirationAnalyticsBloc(analyticsService);
    _expirationAnalyticsBloc.add(const LoadExpirationAnalyticsData());
  }

  @override
  void dispose() {
    _expirationAnalyticsBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ExpirationAnalyticsBloc>.value(
      value: _expirationAnalyticsBloc,
      child: BlocListener<ExpirationAnalyticsBloc, ExpirationAnalyticsState>(
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
              _expirationAnalyticsBloc.add(const LoadExpirationAnalyticsData());
            },
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return BlocBuilder<ExpirationAnalyticsBloc, ExpirationAnalyticsState>(
      builder: (context, state) {
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(ConfigService.tinyPadding),
                child: AnalyticsCard(
                  title: 'Expiration Analytics',
                  icon: Icons.event_busy,
                  child: state is ExpirationAnalyticsLoading
                      ? ExpirationAnalyticsChart(isLoading: true)
                      : state is ExpirationAnalyticsLoaded
                          ? ExpirationAnalyticsChart(data: state.data)
                          : ExpirationAnalyticsChart(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}