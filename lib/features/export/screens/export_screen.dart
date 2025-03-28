import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:food_inventory/common/services/config_service.dart';
import 'package:food_inventory/common/services/error_handler.dart';
import 'package:food_inventory/features/export/bloc/export_bloc.dart';
import 'package:food_inventory/features/export/models/export_mode.dart';
import 'package:food_inventory/features/export/services/export_service.dart';
import 'package:food_inventory/features/export/widgets/export_mode_selector.dart';
import 'package:food_inventory/features/export/widgets/export_options.dart';
import 'package:food_inventory/features/export/widgets/export_summary.dart';
import 'package:food_inventory/features/export/widgets/folder_selector.dart';
import 'package:provider/provider.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  late ExportBloc _exportBloc;
  int _currentStep = 0;
  final int _totalSteps = 4;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Get export service from provider
    final exportService = Provider.of<ExportService>(context, listen: false);
    
    // Initialize bloc
    _exportBloc = ExportBloc(exportService);
  }

  @override
  void dispose() {
    _exportBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return BlocProvider.value(
      value: _exportBloc,
      child: BlocListener<ExportBloc, ExportState>(
        listenWhen: (previous, current) => 
          current.error != null && previous.error != current.error ||
          current is ExportSuccess,
        listener: (context, state) {
          if (state.error != null) {
            ErrorHandler.showErrorSnackBar(
              context, 
              state.error!.message, 
              error: state.error!.error
            );
          }
          
          if (state is ExportSuccess) {
            ErrorHandler.showSuccessSnackBar(
              context, 
              'Export completed successfully to ${state.exportPath}'
            );
            
            // Reset the flow
            setState(() {
              _currentStep = 0;
            });
          }
        },
        child: Scaffold(
          body: Column(
            children: [
              // Progress indicator
              Container(
                padding: EdgeInsets.symmetric(vertical: ConfigService.smallPadding),
                child: Row(
                  children: List.generate(_totalSteps, (index) {
                    return Expanded(
                      child: Container(
                        height: 4,
                        color: index <= _currentStep
                            ? theme.colorScheme.primary
                            : theme.colorScheme.surfaceContainerHighest,
                      ),
                    );
                  }),
                ),
              ),
              
              // Step title
              Padding(
                padding: EdgeInsets.all(ConfigService.mediumPadding),
                child: Text(
                  _getStepTitle(),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              // Main content
              Expanded(
                child: BlocBuilder<ExportBloc, ExportState>(
                  builder: (context, state) {
                    if (state is ExportLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    // Show the appropriate step content
                    return Padding(
                      padding: EdgeInsets.all(ConfigService.mediumPadding),
                      child: _buildStepContent(),
                    );
                  },
                ),
              ),
              
              // Navigation buttons
              Container(
                padding: EdgeInsets.all(ConfigService.mediumPadding),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(ConfigService.alphaLight),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: BlocBuilder<ExportBloc, ExportState>(
                  builder: (context, state) {
                    final bool canProceed = _canProceedToNextStep(state);
                    final bool isLastStep = _currentStep == _totalSteps - 1;
                    
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.arrow_back, size: ConfigService.smallIconSize),
                          label: const Text('Back'),
                          onPressed: _currentStep > 0
                              ? () => setState(() {
                                  _currentStep--;
                                })
                              : null,
                        ),
                        ElevatedButton.icon(
                          icon: Icon(
                            isLastStep ? Icons.download : Icons.arrow_forward,
                            size: ConfigService.smallIconSize,
                          ),
                          label: Text(isLastStep ? 'Export' : 'Next'),
                          onPressed: state is ExportLoading || !canProceed
                              ? null
                              : () {
                                  if (isLastStep) {
                                    // Start the export process
                                    _startExport(context);
                                  } else {
                                    // Move to next step
                                    setState(() {
                                      _currentStep++;
                                    });
                                  }
                                },
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'Select Export Format';
      case 1:
        return 'Export Options';
      case 2:
        return 'Choose Destination';
      case 3:
        return 'Export Summary';
      default:
        return 'Export';
    }
  }
  
  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return const ExportModeSelector();
      case 1:
        return const ExportOptions();
      case 2:
        return const FolderSelector();
      case 3:
        return const ExportSummary();
      default:
        return const SizedBox();
    }
  }
  
  bool _canProceedToNextStep(ExportState state) {
    if (state is! ExportConfigured) return false;
    
    switch (_currentStep) {
      case 0:
        // Need to have a mode selected
        return state.mode != null;
      case 1:
        // Always can proceed from options
        return true;
      case 2:
        // Need to have a folder selected
        return state.outputDirectory != null;
      case 3:
        // Always can proceed from summary
        return true;
      default:
        return false;
    }
  }
  
  void _startExport(BuildContext context) {
    _exportBloc.add(StartExport());
  }
}