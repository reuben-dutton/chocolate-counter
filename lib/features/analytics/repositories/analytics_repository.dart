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
  
  /// Get stock trend data by month for visualization
  Future<List<Map<String, dynamic>>> getStockTrends({DateTime? startDate, Transaction? txn}) async {
    return _withTransactionIfNeeded(txn, (db) async {
      // Base query to get stock and inventory counts grouped by month
      String query = '''
        SELECT 
          strftime('%Y-%m-01', datetime(timestamp / 1000, 'unixepoch')) as month_label,
          strftime('%s', strftime('%Y-%m-01', datetime(timestamp / 1000, 'unixepoch'))) * 1000 as month_start,
          SUM(CASE WHEN type = ${MovementType.stockSale.index} THEN quantity ELSE 0 END) as sales_count,
          (SELECT COALESCE(SUM(quantity), 0) FROM ${DatabaseService.tableItemInstances} WHERE isInStock = 1) as stock_count,
          (SELECT COALESCE(SUM(quantity), 0) FROM ${DatabaseService.tableItemInstances} WHERE isInStock = 0) as inventory_count
        FROM 
          ${DatabaseService.tableInventoryMovements}
      ''';
      
      // Add date filtering if needed
      List<dynamic> args = [];
      if (startDate != null) {
        query += ' WHERE timestamp >= ?';
        args.add(startDate.millisecondsSinceEpoch);
      }
      
      // Complete the query
      query += '''
        GROUP BY 
          month_label
        ORDER BY 
          month_start ASC
      ''';
      
      final results = await db.rawQuery(query, args);
      return results;
    });
  }
  
  /// Get items expiring within a specified date range
  Future<List<Map<String, dynamic>>> getExpiringItems(
    DateTime startDate, 
    DateTime? endDate, 
    {Transaction? txn}
  ) async {
    return _withTransactionIfNeeded(txn, (db) async {
      // Convert dates to milliseconds
      final startMillis = startDate.millisecondsSinceEpoch;
      final endMillis = endDate?.millisecondsSinceEpoch;
      
      // Base query to get items with expiration dates in the given range
      String query = '''
        SELECT 
          ii.id,
          ii.quantity,
          ii.expirationDate,
          ii.isInStock,
          id.name as itemName,
          id.imageUrl
        FROM 
          ${DatabaseService.tableItemInstances} ii
        JOIN 
          ${DatabaseService.tableItemDefinitions} id 
        ON 
          ii.itemDefinitionId = id.id
        WHERE 
          ii.expirationDate >= ?
      ''';
      
      // Add end date filtering if needed
      List<dynamic> args = [startMillis];
      if (endMillis != null) {
        query += ' AND ii.expirationDate <= ?';
        args.add(endMillis);
      }
      
      // Complete the query
      query += '''
        ORDER BY 
          ii.expirationDate ASC
      ''';
      
      final results = await db.rawQuery(query, args);
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