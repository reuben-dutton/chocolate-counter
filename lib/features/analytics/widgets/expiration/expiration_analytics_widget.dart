import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:food_inventory/common/services/config_service.dart';
import 'package:food_inventory/common/services/error_handler.dart';
import 'package:food_inventory/features/analytics/bloc/expiration_analytics_bloc.dart';
import 'package:food_inventory/features/analytics/services/analytics_service.dart';
import 'package:food_inventory/features/analytics/widgets/analytics_card.dart';
import 'package:food_inventory/features/analytics/widgets/expiration/expiration_analytics_chart.dart';
import 'package:provider/provider.dart';

class ExpirationAnalyticsWidget extends StatefulWidget {
  const ExpirationAnalyticsWidget({super.key});

  @override
  State<ExpirationAnalyticsWidget> createState() => _ExpirationAnalyticsWidgetState();
}

class _ExpirationAnalyticsWidgetState extends State<ExpirationAnalyticsWidget> {
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
      child: BlocConsumer<ExpirationAnalyticsBloc, ExpirationAnalyticsState>(
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
        builder: (context, state) {
          return AnalyticsCard(
            title: 'Expiration Analytics',
            icon: Icons.event_busy,
            isLoading: state is ExpirationAnalyticsLoading,
            child: state is ExpirationAnalyticsLoaded
                ? ExpirationAnalyticsChart(data: state.data)
                : ExpirationAnalyticsChart(),
          );
        },
      ),
    );
  }
}