import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:food_inventory/common/services/error_handler.dart';
import 'package:food_inventory/features/export/models/export_mode.dart';
import 'package:food_inventory/features/export/services/export_service.dart';

// Define events
abstract class ExportEvent extends Equatable {
  const ExportEvent();

  @override
  List<Object?> get props => [];
}

class SetExportMode extends ExportEvent {
  final ExportMode mode;
  
  const SetExportMode(this.mode);
  
  @override
  List<Object?> get props => [mode];
}

class SetIncludeImages extends ExportEvent {
  final bool includeImages;
  
  const SetIncludeImages(this.includeImages);
  
  @override
  List<Object?> get props => [includeImages];
}

class SetOutputDirectory extends ExportEvent {
  final String outputDirectory;
  
  const SetOutputDirectory(this.outputDirectory);
  
  @override
  List<Object?> get props => [outputDirectory];
}

class StartExport extends ExportEvent {
  const StartExport();
}

// Define state
abstract class ExportState extends Equatable {
  final AppError? error;
  
  const ExportState({this.error});
  
  @override
  List<Object?> get props => [error];
}

class ExportInitial extends ExportState {
  const ExportInitial();
}

class ExportLoading extends ExportState {
  const ExportLoading();
}

class ExportConfigured extends ExportState {
  final ExportMode? mode;
  final bool includeImages;
  final String? outputDirectory;
  
  const ExportConfigured({
    required this.mode,
    required this.includeImages,
    required this.outputDirectory,
    super.error,
  });
  
  @override
  List<Object?> get props => [mode, includeImages, outputDirectory, error];
  
  ExportConfigured copyWith({
    ExportMode? mode,
    bool? includeImages,
    String? outputDirectory,
    AppError? error,
  }) {
    return ExportConfigured(
      mode: mode ?? this.mode,
      includeImages: includeImages ?? this.includeImages,
      outputDirectory: outputDirectory ?? this.outputDirectory,
      error: error ?? this.error,
    );
  }
}

class ExportSuccess extends ExportState {
  final String exportPath;
  
  const ExportSuccess({
    required this.exportPath,
    super.error,
  });
  
  @override
  List<Object?> get props => [exportPath, error];
}

class ExportBloc extends Bloc<ExportEvent, ExportState> {
  final ExportService _exportService;

  ExportBloc(this._exportService) : super(const ExportInitial()) {
    on<SetExportMode>(_onSetExportMode);
    on<SetIncludeImages>(_onSetIncludeImages);
    on<SetOutputDirectory>(_onSetOutputDirectory);
    on<StartExport>(_onStartExport);
    
    // Initialize with default values
    add(const SetExportMode(ExportMode.csv));
    add(const SetIncludeImages(true));
  }

  void _onSetExportMode(SetExportMode event, Emitter<ExportState> emit) {
    if (state is ExportLoading) return;
    
    if (state is ExportConfigured) {
      emit((state as ExportConfigured).copyWith(mode: event.mode));
    } else {
      emit(ExportConfigured(
        mode: event.mode,
        includeImages: false,
        outputDirectory: null,
      ));
    }
  }

  void _onSetIncludeImages(SetIncludeImages event, Emitter<ExportState> emit) {
    if (state is ExportLoading) return;
    
    if (state is ExportConfigured) {
      emit((state as ExportConfigured).copyWith(includeImages: event.includeImages));
    } else {
      emit(ExportConfigured(
        mode: null,
        includeImages: event.includeImages,
        outputDirectory: null,
      ));
    }
  }

  void _onSetOutputDirectory(SetOutputDirectory event, Emitter<ExportState> emit) {
    if (state is ExportLoading) return;
    
    if (state is ExportConfigured) {
      emit((state as ExportConfigured).copyWith(outputDirectory: event.outputDirectory));
    } else {
      emit(ExportConfigured(
        mode: null,
        includeImages: false,
        outputDirectory: event.outputDirectory,
      ));
    }
  }

  Future<void> _onStartExport(StartExport event, Emitter<ExportState> emit) async {
    if (state is! ExportConfigured) return;
    
    final configuredState = state as ExportConfigured;
    
    // Validate configuration
    if (configuredState.mode == null || configuredState.outputDirectory == null) {
      emit(configuredState.copyWith(
        error: AppError(
          message: 'Export configuration is incomplete',
          source: 'ExportBloc',
        ),
      ));
      return;
    }
    
    try {
      emit(const ExportLoading());
      
      // Perform the export
      final exportPath = await _exportService.exportData(
        mode: configuredState.mode!,
        includeImages: configuredState.includeImages,
        outputDirectory: configuredState.outputDirectory!,
      );
      
      emit(ExportSuccess(exportPath: exportPath));
      
    } catch (e, stackTrace) {
      ErrorHandler.logError('Error during export', e, stackTrace, 'ExportBloc');
      emit(ExportConfigured(
        mode: configuredState.mode,
        includeImages: configuredState.includeImages,
        outputDirectory: configuredState.outputDirectory,
        error: AppError(
          message: 'Export failed: ${e.toString()}',
          error: e,
          stackTrace: stackTrace,
          source: 'ExportBloc',
        ),
      ));
    }
  }
}