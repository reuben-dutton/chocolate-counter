import 'package:flutter/material.dart';

/// Service for application configuration and constants
class ConfigService extends ChangeNotifier {
  // App metadata
  static const String appName = 'Food Inventory';
  static const String appVersion = '1.0.0';
  
  // Database constants
  static const int dbVersion = 3; // Updated version for unitPrice field
  
  // UI constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double tinyPadding = 4.0;
  static const double mediumPadding = 12.0;
  static const double largePadding = 24.0;

  // static const double defaultPadding = 8.0;
  // static const double smallPadding = 4.0;
  // static const double tinyPadding = 2.0;
  // static const double mediumPadding = 6.0;
  // static const double largePadding = 12.0;
  
  // Border radius constants
  static const double defaultBorderRadius = 8.0;
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 10.0; 
  static const double borderRadiusLarge = 20.0;
  
  // Icon sizes
  static const double tinyIconSize = 12.0;
  static const double smallIconSize = 16.0;
  static const double mediumIconSize = 18.0;
  static const double defaultIconSize = 20.0;
  static const double largeIconSize = 48.0;
  static const double xLargeIconSize = 64.0;
  static const double xxLargeIconSize = 80.0;
  
  // Alpha values
  static const int alphaLight = 25;
  static const int alphaMedium = 75;
  static const int alphaModerate = 100;
  static const int alphaDefault = 128;
  static const int alphaHigh = 175;
  
  // Default durations
  static const Duration snackBarDuration = Duration(seconds: 3);
  static const Duration animationDurationFast = Duration(milliseconds: 150);
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration animationDurationSlow = Duration(milliseconds: 500);
  
  // Image constants
  static const double avatarRadiusSmall = 16.0;
  static const double avatarRadiusMedium = 24.0;
  static const double avatarRadiusLarge = 36.0;
  
  // Expiration thresholds
  static const int expirationWarningDays = 7; // Show warning if expiring within this many days
  static const int expirationCriticalDays = 2; // Show critical warning if expiring within this many days
  
  // Dynamic properties that can be changed at runtime
  double _uiScale = 1.0;
  
  // Getters for dynamic properties
  double get uiScale => _uiScale;
  
  // Computed values based on scale
  double get scaledPadding => defaultPadding * _uiScale;
  double get scaledSmallPadding => smallPadding * _uiScale;
  double get scaledMediumPadding => mediumPadding * _uiScale;
  double get scaledLargePadding => largePadding * _uiScale;
  
  // Methods to update dynamic properties
  void setUiScale(double scale) {
    if (_uiScale != scale) {
      _uiScale = scale;
      notifyListeners();
    }
  }
  
  // Color utility methods
  static Color getExpirationColor(BuildContext context, DateTime? expirationDate) {
    if (expirationDate == null) {
      return Colors.grey;
    }
    
    final daysUntil = expirationDate.difference(DateTime.now()).inDays;
    
    if (daysUntil < 0) {
      // Expired
      return Colors.red;
    } else if (daysUntil < expirationCriticalDays) {
      // Critical
      return Colors.orange;
    } else if (daysUntil < expirationWarningDays) {
      // Warning
      return Colors.amber;
    } else {
      // Good
      return Colors.green;
    }
  }
  
  // Input validation
  static String? validateRequiredField(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    return null;
  }
  
  static String? validatePositiveNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    final number = int.tryParse(value);
    if (number == null) {
      return 'Please enter a valid number';
    }
    if (number <= 0) {
      return 'Please enter a positive number';
    }
    return null;
  }
  
  // Date formats
  static String formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
  
  static String formatDateTime(DateTime date) {
    return '${formatDate(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
  
  // Currency format
  static String formatCurrency(double value) {
    return '\$${value.toStringAsFixed(2)}';
  }
}