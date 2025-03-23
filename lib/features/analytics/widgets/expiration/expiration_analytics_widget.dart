import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:food_inventory/common/services/config_service.dart';
import 'package:food_inventory/common/services/error_handler.dart';
import 'package:food_inventory/features/analytics/bloc/expiration_analytics_bloc.dart';
import 'package:food_inventory/features/analytics/services/analytics_service.dart';
import 'package:food_inventory/features/analytics/widgets/analytics_card.dart';
import 'package:food_inventory/features/analytics/widgets/expiration/expiration_analytics_view.dart';
import 'package:provider/provider.dart';

class ExpirationAnalyticsWidget extends StatefulWidget {
  const ExpirationAnalyticsWidget({super.key});

  @override
  State<ExpirationAnalyticsWidget> createState() => _ExpirationAnalyticsWidgetState();
}

class _ExpirationAnalyticsWidgetState extends State<ExpirationAnalyticsWidget> with AutomaticKeepAliveClientMixin {
  bool _showDetailView = false;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final analyticsService = Provider.of<AnalyticsService>(context, listen: false);
    
    return BlocProvider(
      create: (context) => ExpirationAnalyticsBloc(analyticsService)..add(const LoadExpirationAnalyticsData()),
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
          // Create the segmented button for the title
          final segmentedButton = SizedBox(
            width: 160,
            child: SegmentedButton<bool>(
              showSelectedIcon: false,
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith<Color>(
                  (Set<WidgetState> states) {
                    if (states.contains(WidgetState.selected)) {
                      return theme.colorScheme.primary.withAlpha(ConfigService.alphaLight);
                    }
                    return Colors.transparent;
                  },
                ),
                foregroundColor: WidgetStateProperty.resolveWith<Color>(
                  (Set<WidgetState> states) {
                    if (states.contains(WidgetState.selected)) {
                      return theme.colorScheme.primary;
                    }
                    return theme.colorScheme.onSurface.withAlpha(ConfigService.alphaModerate);
                  },
                ),
                padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 0)
                ),
                visualDensity: VisualDensity.standard,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                minimumSize: WidgetStateProperty.all(const Size(0, 36)),
                side: WidgetStateProperty.all(
                  BorderSide(
                    color: theme.colorScheme.primary.withAlpha(ConfigService.alphaLight),
                    width: 1,
                  )
                ),
              ),
              segments: const [
                ButtonSegment<bool>(
                  value: false,
                  label: Text('Summary', style: TextStyle(fontSize: 13)),
                ),
                ButtonSegment<bool>(
                  value: true,
                  label: Text('Expiring', style: TextStyle(fontSize: 13)),
                ),
              ],
              selected: {_showDetailView},
              onSelectionChanged: (Set<bool> selection) {
                if (selection.isNotEmpty) {
                  setState(() {
                    _showDetailView = selection.first;
                  });
                }
              },
            ),
          );
          
          return AnalyticsCard(
            title: 'Expiration Analytics',
            icon: Icons.event_busy,
            titleChild: segmentedButton,
            isLoading: state is ExpirationAnalyticsLoading,
            child: state is ExpirationAnalyticsLoaded
                ? ExpirationAnalyticsView(
                    data: state.data,
                    showDetailView: _showDetailView,
                  )
                : ExpirationAnalyticsView(
                    isLoading: state is ExpirationAnalyticsLoading,
                    showDetailView: _showDetailView,
                  ),
          );
        },
      ),
    );
  }
}