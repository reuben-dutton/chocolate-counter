import 'package:food_inventory/features/analytics/models/analytics_data.dart';
import 'package:food_inventory/features/analytics/models/stock_trend_data.dart';
import 'package:food_inventory/features/analytics/models/stock_trends_data.dart';
import 'package:food_inventory/features/analytics/models/expiration_analytics_data.dart';
import 'package:food_inventory/features/analytics/repositories/analytics_repository.dart';
import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';

/// Service for analytics-related operations
class AnalyticsService {
  final AnalyticsRepository _analyticsRepository;
  // Set this to true to simulate loading delay
  final bool _simulateDelay = false;
  // Adjust this duration as needed for testing
  final Duration _delayDuration = const Duration(seconds: 3);

  AnalyticsService(this._analyticsRepository);

  /// Get data for most popular (most sold) items with optional time period filter
  Future<AnalyticsData> getPopularItemsData({DateTime? startDate, Transaction? txn}) async {
    // Add artificial delay for testing the skeleton loader
    if (_simulateDelay) {
      await Future.delayed(_delayDuration);
    }
    
    return _withTransactionIfNeeded(txn, (transaction) async {
      final rawData = await _analyticsRepository.getPopularItems(
        startDate: startDate,
        txn: transaction
      );
      final totalStockCount = await _analyticsRepository.getTotalStockCount(txn: transaction);
      
      final List<PopularItemData> popularItems = [];
      
      for (final item in rawData) {
        final itemName = item['itemName'] as String;
        final salesCount = item['salesCount'] as int;
        
        popularItems.add(PopularItemData(
          itemName: itemName,
          salesCount: salesCount,
        ));
      }
      
      return AnalyticsData(
        popularItems: popularItems,
        totalStockCount: totalStockCount,
      );
    });
  }
  
  /// Get stock trends data with optional time period filter
  Future<StockTrendsData> getStockTrendsData({DateTime? startDate, Transaction? txn}) async {
    // Add artificial delay for testing the skeleton loader
    if (_simulateDelay) {
      await Future.delayed(_delayDuration);
    }
    
    return _withTransactionIfNeeded(txn, (transaction) async {
      final rawData = await _analyticsRepository.getStockTrends(
        startDate: startDate,
        txn: transaction
      );
      
      // Format a date formatter for month names
      final dateFormat = DateFormat('MMM');
      
      final List<StockTrendData> trendData = [];
      
      for (final row in rawData) {
        final date = DateTime.fromMillisecondsSinceEpoch(row['month_start'] as int);
        final stockCount = row['stock_count'] as int;
        final inventoryCount = row['inventory_count'] as int;
        
        trendData.add(StockTrendData(
          month: dateFormat.format(date),
          stockCount: stockCount,
          inventoryCount: inventoryCount,
          date: date,
        ));
      }
      
      return StockTrendsData(trendData: trendData);
    });
  }
  
  /// Get expiration analytics data with optional time period filter
  Future<ExpirationAnalyticsData> getExpirationAnalyticsData({Transaction? txn}) async {
    // Add artificial delay for testing the skeleton loader
    if (_simulateDelay) {
      await Future.delayed(_delayDuration);
    }
    
    return _withTransactionIfNeeded(txn, (transaction) async {
      final now = DateTime.now();
      
      // Get expired items (past)
      final expiredItems = await _analyticsRepository.getExpiringItems(
        now.subtract(const Duration(days: 365 * 5)), // 5 years ago as a reasonable limit
        now,
        txn: transaction
      );
      
      final itemsExpiringThisWeek = await _analyticsRepository.getExpiringItems(
        now,
        now.add(const Duration(days: 7)),
        txn: transaction
      );
      
      final itemsExpiringNextWeek = await _analyticsRepository.getExpiringItems(
        now.add(const Duration(days: 7)),
        now.add(const Duration(days: 14)),
        txn: transaction
      );
      
      final itemsExpiringThisMonth = await _analyticsRepository.getExpiringItems(
        now.add(const Duration(days: 14)),
        now.add(const Duration(days: 30)),
        txn: transaction
      );
      
      final itemsExpiringNextMonth = await _analyticsRepository.getExpiringItems(
        now.add(const Duration(days: 30)),
        now.add(const Duration(days: 60)),
        txn: transaction
      );
      
      final itemsExpiringBeyond = await _analyticsRepository.getExpiringItems(
        now.add(const Duration(days: 60)),
        null, // No end date
        txn: transaction
      );
      
      // Calculate total quantities for each category
      int expiredCount = 0;
      for (final item in expiredItems) {
        expiredCount += item['quantity'] as int;
      }
      
      int thisWeekCount = 0;
      for (final item in itemsExpiringThisWeek) {
        thisWeekCount += item['quantity'] as int;
      }
      
      int nextWeekCount = 0;
      for (final item in itemsExpiringNextWeek) {
        nextWeekCount += item['quantity'] as int;
      }
      
      int thisMonthCount = 0;
      for (final item in itemsExpiringThisMonth) {
        thisMonthCount += item['quantity'] as int;
      }
      
      int nextMonthCount = 0;
      for (final item in itemsExpiringNextMonth) {
        nextMonthCount += item['quantity'] as int;
      }
      
      int beyondCount = 0;
      for (final item in itemsExpiringBeyond) {
        beyondCount += item['quantity'] as int;
      }
      
      return ExpirationAnalyticsData(
        expiredCount: expiredCount,
        thisWeekCount: thisWeekCount,
        nextWeekCount: nextWeekCount,
        thisMonthCount: thisMonthCount,
        nextMonthCount: nextMonthCount,
        beyondCount: beyondCount,
        expiredItems: expiredItems,
        thisWeekItems: itemsExpiringThisWeek,
        nextWeekItems: itemsExpiringNextWeek,
        thisMonthItems: itemsExpiringThisMonth,
        nextMonthItems: itemsExpiringNextMonth,
        beyondItems: itemsExpiringBeyond,
      );
    });
  }
  
  /// Run a function within a transaction
  Future<R> withTransaction<R>(Future<R> Function(Transaction txn) action) async {
    return _analyticsRepository.withTransaction(action);
  }
  
  // Helper method for transaction management
  Future<T> _withTransactionIfNeeded<T>(
    Transaction? txn,
    Future<T> Function(Transaction) operation
  ) async {
    if (txn != null) {
      return await operation(txn);
    } else {
      return await withTransaction(operation);
    }
  }
}