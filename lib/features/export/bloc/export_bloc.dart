// lib/features/export/bloc/export_bloc.dart
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:food_inventory/common/services/error_handler.dart';
import 'package:food_inventory/features/export/services/export_service.dart';

// Events
abstract class ExportEvent extends Equatable {
  const ExportEvent();

  @override
  List<Object?> get props => [];
}

class SetCustomExportDirectory extends ExportEvent {
  final String directoryPath;

  const SetCustomExportDirectory(this.directoryPath);

  @override
  List<Object?> get props => [directoryPath];
}

class StartExport extends ExportEvent {
  final ExportFormat format;

  const StartExport(this.format);

  @override
  List<Object?> get props => [format];
}

class ToggleIncludeImages extends ExportEvent {
  final bool include;

  const ToggleIncludeImages(this.include);

  @override
  List<Object?> get props => [include];
}

class ToggleIncludeHistory extends ExportEvent {
  final bool include;

  const ToggleIncludeHistory(this.include);

  @override
  List<Object?> get props => [include];
}

class ToggleExportAllData extends ExportEvent {
  final bool exportAll;

  const ToggleExportAllData(this.exportAll);

  @override
  List<Object?> get props => [exportAll];
}

// States
abstract class ExportState extends Equatable {
  final bool includeImages;
  final bool includeHistory;
  final bool exportAllData;
  final String? customExportDir;

  const ExportState({
    this.includeImages = false,
    this.includeHistory = true,
    this.exportAllData = false,
    this.customExportDir,
  });

  @override
  List<Object?> get props => [includeImages, includeHistory, exportAllData, customExportDir];
}

class ExportInitial extends ExportState {
  const ExportInitial({
    super.includeImages,
    super.includeHistory,
    super.exportAllData,
    super.customExportDir
  });
}

class ExportLoading extends ExportState {
  final ExportFormat format;

  const ExportLoading({
    required this.format,
    super.includeImages,
    super.includeHistory,
    super.exportAllData,
    super.customExportDir,
  });

  @override
  List<Object?> get props => [format, includeImages, includeHistory, exportAllData, customExportDir];
}

class ExportSuccess extends ExportState {
  final String filePath;
  final ExportFormat format;

  const ExportSuccess({
    required this.filePath,
    required this.format,
    super.includeImages,
    super.includeHistory,
    super.exportAllData,
    super.customExportDir,
  });

  @override
  List<Object?> get props => [filePath, format, includeImages, includeHistory, exportAllData, customExportDir];
}

class ExportError extends ExportState {
  final AppError error;

  const ExportError({
    required this.error,
    super.includeImages,
    super.includeHistory,
    super.exportAllData,
    super.customExportDir,
  });

  @override
  List<Object?> get props => [error, includeImages, includeHistory, exportAllData, customExportDir];
}

// BLoC
class ExportBloc extends Bloc<ExportEvent, ExportState> {
  final ExportService _exportService;

  ExportBloc(this._exportService) : super(const ExportInitial()) {
    on<StartExport>(_onStartExport);
    on<ToggleIncludeImages>(_onToggleIncludeImages);
    on<ToggleIncludeHistory>(_onToggleIncludeHistory);
    on<ToggleExportAllData>(_onToggleExportAllData);
    on<SetCustomExportDirectory>(_onSetCustomExportDirectory);
  }

  void _onSetCustomExportDirectory(
    SetCustomExportDirectory event,
    Emitter<ExportState> emit,
  ) {
    emit(ExportInitial(
      includeImages: state.includeImages,
      includeHistory: state.includeHistory,
      exportAllData: state.exportAllData,
      customExportDir: event.directoryPath,
    ));
  }

  Future<void> _onStartExport(
    StartExport event,
    Emitter<ExportState> emit,
  ) async {
    try {
      emit(ExportLoading(
        format: event.format,
        includeImages: state.includeImages,
        includeHistory: state.includeHistory,
        exportAllData: state.exportAllData,
        customExportDir: state.customExportDir,
      ));

      final filePath = await _performExport(event.format);

      emit(ExportSuccess(
        filePath: filePath,
        format: event.format,
        includeImages: state.includeImages,
        includeHistory: state.includeHistory,
        exportAllData: state.exportAllData,
        customExportDir: state.customExportDir,
      ));
    } catch (e, stackTrace) {
      final error = AppError(
        message: 'Failed to export data',
        error: e,
        stackTrace: stackTrace,
        source: 'ExportBloc',
      );

      ErrorHandler.logError(error.message, e, stackTrace, 'ExportBloc');

      emit(ExportError(
        error: error,
        includeImages: state.includeImages,
        includeHistory: state.includeHistory,
        exportAllData: state.exportAllData,
        customExportDir: state.customExportDir,
      ));
    }
  }

  void _onToggleIncludeImages(
    ToggleIncludeImages event,
    Emitter<ExportState> emit,
  ) {
    emit(ExportInitial(
      includeImages: event.include,
      includeHistory: state.includeHistory,
      exportAllData: state.exportAllData,
      customExportDir: state.customExportDir,
    ));
  }

  void _onToggleIncludeHistory(
    ToggleIncludeHistory event,
    Emitter<ExportState> emit,
  ) {
    emit(ExportInitial(
      includeImages: state.includeImages,
      includeHistory: event.include,
      exportAllData: state.exportAllData,
      customExportDir: state.customExportDir,
    ));
  }

  void _onToggleExportAllData(
    ToggleExportAllData event,
    Emitter<ExportState> emit,
  ) {
    emit(ExportInitial(
      includeImages: state.includeImages,
      includeHistory: state.includeHistory,
      exportAllData: event.exportAll,
      customExportDir: state.customExportDir,
    ));
  }

  Future<String> _performExport(ExportFormat format) async {
    switch (format) {
      case ExportFormat.csv:
        return await _exportService.exportToCSV(
          includeImages: state.includeImages,
          includeHistory: state.includeHistory,
          exportAllData: state.exportAllData,
          customExportDir: state.customExportDir,
        );
      case ExportFormat.json:
        return await _exportService.exportToJSON(
          includeImages: state.includeImages,
          includeHistory: state.includeHistory,
          exportAllData: state.exportAllData,
          customExportDir: state.customExportDir,
        );
      case ExportFormat.sqlite:
        return await _exportService.exportDatabaseFile(
          includeImages: state.includeImages,
          customExportDir: state.customExportDir,
        );
      case ExportFormat.excel:
        return await _exportService.exportToExcel(
          includeImages: state.includeImages,
          includeHistory: state.includeHistory,
          exportAllData: state.exportAllData,
          customExportDir: state.customExportDir,
        );
    }
  }
}