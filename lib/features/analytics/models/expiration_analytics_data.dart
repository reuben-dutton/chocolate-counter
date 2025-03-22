/// Data model for expiration analytics
class ExpirationAnalyticsData {
  final int thisWeekCount;
  final int nextWeekCount;
  final int thisMonthCount;
  final int nextMonthCount;
  final int beyondCount;
  
  final List<Map<String, dynamic>> thisWeekItems;
  final List<Map<String, dynamic>> nextWeekItems;
  final List<Map<String, dynamic>> thisMonthItems;
  final List<Map<String, dynamic>> nextMonthItems;
  final List<Map<String, dynamic>> beyondItems;

  ExpirationAnalyticsData({
    required this.thisWeekCount,
    required this.nextWeekCount,
    required this.thisMonthCount,
    required this.nextMonthCount,
    required this.beyondCount,
    required this.thisWeekItems,
    required this.nextWeekItems,
    required this.thisMonthItems,
    required this.nextMonthItems,
    required this.beyondItems,
  });
  
  int get totalItemsCount => thisWeekCount + nextWeekCount + thisMonthCount + nextMonthCount + beyondCount;
  
  int get criticalCount => thisWeekCount;
  int get warningCount => nextWeekCount;
  
  List<Map<String, dynamic>> get allItems {
    return [
      ...thisWeekItems,
      ...nextWeekItems,
      ...thisMonthItems,
      ...nextMonthItems,
      ...beyondItems,
    ];
  }
  
  /// Get items with status tag for display purposes
  List<Map<String, dynamic>> getItemsWithStatus() {
    final result = <Map<String, dynamic>>[];
    
    // Process this week's items as critical
    for (final item in thisWeekItems) {
      final newItem = Map<String, dynamic>.from(item);
      newItem['status'] = 'critical';
      result.add(newItem);
    }
    
    // Process next week's items as warning
    for (final item in nextWeekItems) {
      final newItem = Map<String, dynamic>.from(item);
      newItem['status'] = 'warning';
      result.add(newItem);
    }
    
    // Process this month's items as normal
    for (final item in thisMonthItems) {
      final newItem = Map<String, dynamic>.from(item);
      newItem['status'] = 'normal';
      result.add(newItem);
    }
    
    // Process next month's items as normal
    for (final item in nextMonthItems) {
      final newItem = Map<String, dynamic>.from(item);
      newItem['status'] = 'normal';
      result.add(newItem);
    }
    
    // Process items beyond as safe
    for (final item in beyondItems) {
      final newItem = Map<String, dynamic>.from(item);
      newItem['status'] = 'safe';
      result.add(newItem);
    }
    
    // Sort by expiration date
    result.sort((a, b) {
      final aDate = a['expirationDate'] as int;
      final bDate = b['expirationDate'] as int;
      return aDate.compareTo(bDate);
    });
    
    return result;
  }
  
  /// Get expiration timeline data for charts
  List<Map<String, dynamic>> getTimelineData() {
    return [
      {
        'category': 'This Week',
        'count': thisWeekCount,
        'color': '#ef4444',  // red
      },
      {
        'category': 'Next Week',
        'count': nextWeekCount,
        'color': '#f97316',  // orange
      },
      {
        'category': 'This Month',
        'count': thisMonthCount,
        'color': '#f59e0b',  // amber
      },
      {
        'category': 'Next Month',
        'count': nextMonthCount,
        'color': '#84cc16',  // lime
      },
      {
        'category': 'Later',
        'count': beyondCount,
        'color': '#22c55e',  // green
      },
    ];
  }
}