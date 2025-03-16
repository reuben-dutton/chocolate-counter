import 'dart:io';
import 'package:flutter/material.dart';
import 'package:food_inventory/common/services/config_service.dart';

/// Error model for standardized error information
class AppError {
  final String message;
  final ErrorSeverity severity;
  final Object? error;
  final StackTrace? stackTrace;
  final String? source;

  AppError({
    required this.message,
    this.severity = ErrorSeverity.standard,
    this.error,
    this.stackTrace,
    this.source,
  });

  @override
  String toString() {
    final errorDetails = error != null ? ': ${ErrorHandler._formatError(error!)}' : '';
    final sourceDetails = source != null ? ' [$source]' : '';
    return '$message$errorDetails$sourceDetails';
  }
}

/// Severity levels for errors
enum ErrorSeverity {
  debug,     // Minor issues, debugging info
  standard,  // Regular errors, recoverable
  critical,  // Serious errors that may impact functionality
  fatal      // Severe errors that require app restart
}

/// A service for handling and displaying errors consistently throughout the application
class ErrorHandler {
  /// Show a snackbar with an error message
  static void showErrorSnackBar(BuildContext context, String message, {Object? error}) {
    final errorDetails = error != null ? ': ${_formatError(error)}' : '';
    final completeMessage = '$message$errorDetails';
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(completeMessage),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: ConfigService.snackBarDuration,
      ),
    );
  }
  
  /// Show a snackbar with a success message
  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: ConfigService.snackBarDuration,
      ),
    );
  }
  
  /// Show a dialog with detailed error information
  static Future<void> showErrorDialog(BuildContext context, String title, String message, {Object? error}) async {
    final errorDetails = error != null ? _formatError(error) : null;
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            if (errorDetails != null) ...[
              const SizedBox(height: ConfigService.mediumPadding),
              const Text(
                'Technical details:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: ConfigService.tinyPadding),
              Text(
                errorDetails,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  /// Log an error to the console with structured information
  static void logError(String message, Object error, [StackTrace? stackTrace, String? source]) {
    final appError = AppError(
      message: message,
      error: error,
      stackTrace: stackTrace,
      source: source
    );
    
    print('ERROR: ${appError.message}');
    print('Details: ${_formatError(error)}');
    if (stackTrace != null) {
      print('Stack trace: $stackTrace');
    }
    if (source != null) {
      print('Source: $source');
    }
    
    // Here you could add code to log to a remote error reporting service
  }
  
  /// Format an error object to a readable string
  static String _formatError(Object error) {
    if (error is Exception) {
      return 'Exception: $error';
    } else if (error is Error) {
      return 'Error: $error';
    } else if (error is HttpException) {
      return 'Network error: $error';
    } else {
      return error.toString();
    }
  }
  
  /// Handle database operation errors
  static Future<void> handleDatabaseError(BuildContext context, Object error, {String? operation, StackTrace? stackTrace}) async {
    final operationText = operation != null ? ' during $operation' : '';
    logError('Database error$operationText', error, stackTrace, 'Database');
    showErrorSnackBar(context, 'Database error$operationText', error: error);
  }
  
  /// Handle file operation errors
  static Future<void> handleFileError(BuildContext context, Object error, {String? operation, StackTrace? stackTrace}) async {
    final operationText = operation != null ? ' during $operation' : '';
    logError('File error$operationText', error, stackTrace, 'File');
    showErrorSnackBar(context, 'File error$operationText', error: error);
  }
  
  /// Handle service operation errors
  static Future<void> handleServiceError(BuildContext context, Object error, {String? service, String? operation, StackTrace? stackTrace}) async {
    final serviceText = service != null ? '$service service' : 'Service';
    final operationText = operation != null ? ' during $operation' : '';
    logError('$serviceText error$operationText', error, stackTrace, serviceText);
    showErrorSnackBar(context, '$serviceText error$operationText', error: error);
  }
  
  /// Handle BLoC operation errors
  static Future<void> handleBlocError(BuildContext context, Object error, {String? bloc, String? operation, StackTrace? stackTrace}) async {
    final blocText = bloc != null ? '$bloc BLoC' : 'BLoC';
    final operationText = operation != null ? ' during $operation' : '';
    logError('$blocText error$operationText', error, stackTrace, blocText);
    showErrorSnackBar(context, '$blocText error$operationText', error: error);
  }
}