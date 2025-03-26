// lib/features/export/widgets/export_progress_bottom_sheet.dart - Updated with export progress tracking

import 'package:flutter/material.dart';
import 'package:food_inventory/common/services/config_service.dart';
import 'package:food_inventory/common/widgets/modal_bottom_sheet.dart';
import 'package:food_inventory/features/export/services/export_service.dart';

class ExportProgressBottomSheet extends StatefulWidget {
  final ExportFormat format;
  final String formatName;
  final ExportProgressController controller;

  const ExportProgressBottomSheet({
    Key? key,
    required this.format,
    required this.formatName,
    required this.controller,
  }) : super(key: key);

  @override
  State<ExportProgressBottomSheet> createState() => _ExportProgressBottomSheetState();
}

class _ExportProgressBottomSheetState extends State<ExportProgressBottomSheet> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onProgressUpdate);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onProgressUpdate);
    super.dispose();
  }

  void _onProgressUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Choose icon based on format
    IconData formatIcon;
    switch (widget.format) {
      case ExportFormat.csv:
        formatIcon = Icons.view_list;
        break;
      case ExportFormat.json:
        formatIcon = Icons.description;
        break;
      case ExportFormat.sqlite:
        formatIcon = Icons.dataset;
        break;
      case ExportFormat.excel:
        formatIcon = Icons.horizontal_split;
        break;
    }
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ModalBottomSheet.buildHeader(
          context: context,
          title: 'Exporting to ${widget.formatName}',
          icon: formatIcon,
          iconColor: theme.colorScheme.primary,
          // No close button during export
        ),
        
        SizedBox(height: ConfigService.mediumPadding),
        
        // Export steps with progress
        _buildExportSteps(theme),
        
        SizedBox(height: ConfigService.largePadding),
        
        Center(
          child: Column(
            children: [
              widget.controller.isCompleted
                  ? Icon(Icons.check_circle, color: Colors.green, size: 48)
                  : SizedBox(
                      height: 48,
                      width: 48,
                      child: CircularProgressIndicator(
                        value: widget.controller.determinate ? widget.controller.progress : null,
                      ),
                    ),
              SizedBox(height: ConfigService.defaultPadding),
              Text(
                widget.controller.statusMessage,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        
        SizedBox(height: ConfigService.largePadding),
      ],
    );
  }
  
  Widget _buildExportSteps(ThemeData theme) {
    final steps = [
      ExportStep('Preparing data', ExportStage.preparing),
      ExportStep('Exporting files', ExportStage.exporting),
      ExportStep('Creating export package', ExportStage.packaging),
      ExportStep('Finalizing export', ExportStage.finalizing),
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: steps.map((step) {
        StepStatus status;
        
        if (widget.controller.currentStage.index > step.stage.index) {
          status = StepStatus.completed;
        } else if (widget.controller.currentStage.index == step.stage.index) {
          status = StepStatus.inProgress;
        } else {
          status = StepStatus.pending;
        }
        
        return _buildStep(theme, step.title, status);
      }).toList(),
    );
  }
  
  Widget _buildStep(ThemeData theme, String title, StepStatus status) {
    IconData icon;
    Color color;
    
    switch (status) {
      case StepStatus.pending:
        icon = Icons.circle_outlined;
        color = theme.colorScheme.onSurface.withAlpha(ConfigService.alphaDefault);
        break;
      case StepStatus.inProgress:
        icon = Icons.timelapse;
        color = theme.colorScheme.primary;
        break;
      case StepStatus.completed:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
    }
    
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: ConfigService.tinyPadding,
        horizontal: ConfigService.defaultPadding,
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: ConfigService.smallIconSize),
          SizedBox(width: ConfigService.defaultPadding),
          Text(
            title,
            style: TextStyle(
              color: status == StepStatus.pending
                  ? theme.colorScheme.onSurface.withAlpha(ConfigService.alphaDefault)
                  : theme.colorScheme.onSurface,
              fontWeight: status == StepStatus.inProgress ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

// Status of export steps
enum StepStatus {
  pending,
  inProgress,
  completed,
}

// Export stages
enum ExportStage {
  preparing,
  exporting,
  packaging,
  finalizing,
  completed,
}

// Step data for visualization
class ExportStep {
  final String title;
  final ExportStage stage;
  
  ExportStep(this.title, this.stage);
}

// Progress controller to update bottom sheet
class ExportProgressController extends ChangeNotifier {
  ExportStage _currentStage = ExportStage.preparing;
  bool _determinate = false;
  double _progress = 0.0;
  String _statusMessage = 'Preparing export data...';
  bool _isCompleted = false;
  
  ExportStage get currentStage => _currentStage;
  bool get determinate => _determinate;
  double get progress => _progress;
  String get statusMessage => _statusMessage;
  bool get isCompleted => _isCompleted;
  
  void updateProgress({
    ExportStage? stage,
    bool? determinate,
    double? progress,
    String? message,
  }) {
    bool hasChanges = false;
    
    if (stage != null && _currentStage != stage) {
      _currentStage = stage;
      hasChanges = true;
    }
    
    if (determinate != null && _determinate != determinate) {
      _determinate = determinate;
      hasChanges = true;
    }
    
    if (progress != null && _progress != progress) {
      _progress = progress;
      hasChanges = true;
    }
    
    if (message != null && _statusMessage != message) {
      _statusMessage = message;
      hasChanges = true;
    }
    
    if (hasChanges) {
      notifyListeners();
    }
  }
  
  void setStage(ExportStage stage, {String? message}) {
    _currentStage = stage;
    if (message != null) {
      _statusMessage = message;
    } else {
      // Update default message based on stage
      switch (stage) {
        case ExportStage.preparing:
          _statusMessage = 'Preparing export data...';
          break;
        case ExportStage.exporting:
          _statusMessage = 'Exporting files...';
          break;
        case ExportStage.packaging:
          _statusMessage = 'Creating export package...';
          break;
        case ExportStage.finalizing:
          _statusMessage = 'Finalizing export...';
          break;
        case ExportStage.completed:
          _statusMessage = 'Export completed successfully!';
          _isCompleted = true;
          break;
      }
    }
    notifyListeners();
  }
  
  void reset() {
    _currentStage = ExportStage.preparing;
    _determinate = false;
    _progress = 0.0;
    _statusMessage = 'Preparing export data...';
    _isCompleted = false;
    notifyListeners();
  }
}

// Helper method to show the bottom sheet
Future<ExportProgressController> showExportProgressBottomSheet(
  BuildContext context, 
  ExportFormat format,
) {
  String formatName;
  switch (format) {
    case ExportFormat.csv:
      formatName = 'CSV';
      break;
    case ExportFormat.json:
      formatName = 'JSON';
      break;
    case ExportFormat.sqlite:
      formatName = 'SQLite';
      break;
    case ExportFormat.excel:
      formatName = 'Excel';
      break;
  }
  
  final controller = ExportProgressController();
  
  ModalBottomSheet.show(
    context: context,
    isDismissible: false,
    enableDrag: false,
    builder: (context) => ExportProgressBottomSheet(
      format: format,
      formatName: formatName,
      controller: controller,
    ),
  );
  
  return Future.value(controller);
}