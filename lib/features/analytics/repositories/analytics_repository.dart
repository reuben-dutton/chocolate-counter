import 'package:food_inventory/common/services/database_service.dart';
import 'package:food_inventory/data/models/inventory_movement.dart';
import 'package:sqflite/sqflite.dart';

/// Repository for analytics data access
class AnalyticsRepository {
  final DatabaseService _databaseService;

  AnalyticsRepository(this._databaseService);

  /// Get most popular items based on sales history with optional date filtering
  Future<List<Map<String, dynamic>>> getPopularItems({DateTime? startDate, Transaction? txn}) async {
    return _withTransactionIfNeeded(txn, (db) async {
      // Base query to get most sold items based on inventory movements
      String query = '''
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
      ''';
      
      // Add date filtering if needed
      List<dynamic> args = [];
      if (startDate != null) {
        query += ' AND im.timestamp >= ?';
        args.add(startDate.millisecondsSinceEpoch);
      }
      
      // Complete the query
      query += '''
        GROUP BY 
          im.itemDefinitionId
        ORDER BY 
          salesCount DESC
        LIMIT 10
      ''';
      
      final results = await db.rawQuery(query, args);
      return results;
    });
  }

  /// Get total stock count for all items
  Future<int> getTotalStockCount({Transaction? txn}) async {
    return _withTransactionIfNeeded(txn, (db) async {
      final result = await db.rawQuery('''
        SELECT 
          COALESCE(SUM(quantity), 0) as totalStock
        FROM 
          ${DatabaseService.tableItemInstances}
        WHERE 
          isInStock = 1
      ''');
      
      return result.first['totalStock'] as int? ?? 0;
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