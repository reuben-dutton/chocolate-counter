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
  late ExpirationAnalyticsBloc _expirationAnalyticsBloc;
  bool _showDetailView = false;

  @override
  bool get wantKeepAlive => true;

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
    super.build(context);
    final theme = Theme.of(context);
    
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
          // Create the segmented button for the title
          final segmentedButton = SizedBox(
            width: 160,
            child: SegmentedButton<bool>(
              showSelectedIcon: false,
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.resolveWith<Color>(
                  (Set<MaterialState> states) {
                    if (states.contains(MaterialState.selected)) {
                      return theme.colorScheme.primary.withOpacity(0.1);
                    }
                    return Colors.transparent;
                  },
                ),
                foregroundColor: MaterialStateProperty.resolveWith<Color>(
                  (Set<MaterialState> states) {
                    if (states.contains(MaterialState.selected)) {
                      return theme.colorScheme.primary;
                    }
                    return theme.colorScheme.onSurface.withOpacity(0.6);
                  },
                ),
                padding: MaterialStateProperty.all(
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 0)
                ),
                visualDensity: VisualDensity.standard,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                minimumSize: MaterialStateProperty.all(const Size(0, 36)),
                side: MaterialStateProperty.all(
                  BorderSide(
                    color: theme.colorScheme.primary.withOpacity(0.2),
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