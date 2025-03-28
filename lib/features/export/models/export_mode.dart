import 'package:flutter/material.dart';

/// Represents the available export formats
enum ExportMode {
  csv,
  excel,
  sqlite,
  json;
  
  String get displayName {
    switch (this) {
      case ExportMode.csv:
        return 'CSV';
      case ExportMode.excel:
        return 'Excel';
      case ExportMode.sqlite:
        return 'SQLite';
      case ExportMode.json:
        return 'JSON';
    }
  }
  
  String get description {
    switch (this) {
      case ExportMode.csv:
        return 'Export as a set of CSV files (comma-separated values)';
      case ExportMode.excel:
        return 'Export as a single Excel spreadsheet with multiple sheets';
      case ExportMode.sqlite:
        return 'Export as a SQLite database file';
      case ExportMode.json:
        return 'Export as a set of JSON files';
    }
  }
  
  IconData get icon {
    switch (this) {
      case ExportMode.csv:
        return Icons.article_outlined;
      case ExportMode.excel:
        return Icons.table_chart;
      case ExportMode.sqlite:
        return Icons.storage;
      case ExportMode.json:
        return Icons.code;
    }
  }
}