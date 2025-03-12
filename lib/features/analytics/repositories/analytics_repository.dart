// In lib/features/analytics/repositories/analytics_repository.dart

import 'package:food_inventory/common/services/database_service.dart';
import 'package:food_inventory/data/models/inventory_movement.dart';
import 'package:sqflite/sqflite.dart';

/// Repository for analytics data access
class AnalyticsRepository {
  final DatabaseService _databaseService;

  AnalyticsRepository(this._databaseService);

  /// Get most popular items based on sales history
  Future<List<Map<String, dynamic>>> getPopularItems({Transaction? txn}) async {
    return _withTransactionIfNeeded(txn, (db) async {
      // Query to get most sold items based on inventory movements
      final results = await db.rawQuery('''
        SELECT 
          id.name as itemName, 
          SUM(im.quantity) as salesCount
        FROM 
          ${DatabaseService.tableInventoryMovements} im
        JOIN 
          ${DatabaseService.tableItemDefinitions} id 
        ON 
          im.itemDefinitionId = id.id
        WHERE 
          im.type = ${MovementType.stockSale.index}
        GROUP BY 
          im.itemDefinitionId
        ORDER BY 
          salesCount DESC
        LIMIT 10
      ''');
      
      return results;
    });
  }
  
  /// Run a function within a transaction
  Future<R> withTransaction<R>(Future<R> Function(Transaction txn) action) async {
    final db = _databaseService.database;
    return await db.transaction(action);
  }
  
  // Helper method for transaction management
  Future<T> _withTransactionIfNeeded<T>(
    Transaction? txn,
    Future<T> Function(DatabaseExecutor db) operation
  ) async {
    if (txn != null) {
      return await operation(txn);
    } else {
      return await withTransaction((transaction) => operation(transaction));
    }
  }
}