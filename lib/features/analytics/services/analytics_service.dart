import 'package:food_inventory/features/analytics/models/analytics_data.dart';
import 'package:food_inventory/features/analytics/repositories/analytics_repository.dart';
import 'package:sqflite/sqflite.dart';

/// Service for analytics-related operations
class AnalyticsService {
  final AnalyticsRepository _analyticsRepository;

  AnalyticsService(this._analyticsRepository);

  /// Get data for most popular (most sold) items
  Future<AnalyticsData> getPopularItemsData({Transaction? txn}) async {
    return _withTransactionIfNeeded(txn, (transaction) async {
      final rawData = await _analyticsRepository.getPopularItems(txn: transaction);
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