import 'dart:io';
import 'package:flutter/material.dart';
import 'package:food_inventory/common/services/config_service.dart';

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
              const SizedBox(height: 12),
              const Text(
                'Technical details:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: 4),
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
  
  /// Log an error to the console
  static void logError(String message, Object error, StackTrace? stackTrace) {
    print('ERROR: $message');
    print('Details: ${_formatError(error)}');
    if (stackTrace != null) {
      print('Stack trace: $stackTrace');
    }
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
  static Future<void> handleDatabaseError(BuildContext context, Object error, {String? operation}) async {
    final operationText = operation != null ? ' during $operation' : '';
    logError('Database error$operationText', error, null);
    showErrorSnackBar(context, 'Database error$operationText', error: error);
  }
  
  /// Handle file operation errors
  static Future<void> handleFileError(BuildContext context, Object error, {String? operation}) async {
    final operationText = operation != null ? ' during $operation' : '';
    logError('File error$operationText', error, null);
    showErrorSnackBar(context, 'File error$operationText', error: error);
  }
}