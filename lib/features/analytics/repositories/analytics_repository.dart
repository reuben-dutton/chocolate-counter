import 'package:food_inventory/common/services/database_service.dart';
import 'package:food_inventory/data/models/inventory_movement.dart';
import 'package:sqflite/sqflite.dart';

/// Repository for analytics data access
class AnalyticsRepository {
  final DatabaseService _databaseService;

  AnalyticsRepository(this._databaseService);

  /// Get most popular items based on sales history
  Future<List<Map<String, dynamic>>> getPopularItems({Transaction? txn}) async {
    final db = txn ?? _databaseService.database;
    
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
  }
}