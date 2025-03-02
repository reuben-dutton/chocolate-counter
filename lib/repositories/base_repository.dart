import 'package:food_inventory/services/database_service.dart';

/// Generic repository interface for CRUD operations
abstract class BaseRepository<T> {
  /// DatabaseService instance for database operations
  final DatabaseService databaseService;
  
  /// Table name in the database
  final String tableName;

  /// Constructor requiring database service and table name
  BaseRepository(this.databaseService, this.tableName);

  /// Convert entity to database map
  Map<String, dynamic> toMap(T entity);
  
  /// Create entity from database map
  T fromMap(Map<String, dynamic> map);
  
  /// Get ID from entity (for update operations)
  int? getId(T entity);

  /// Get all entities
  Future<List<T>> getAll({String? orderBy}) async {
    final db = databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      orderBy: orderBy,
    );
    
    return List.generate(maps.length, (i) => fromMap(maps[i]));
  }

  /// Get entity by ID
  Future<T?> getById(int id) async {
    final db = databaseService.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (maps.isEmpty) {
      return null;
    }
    
    return fromMap(maps.first);
  }

  /// Create new entity
  Future<int> create(T entity) async {
    final db = databaseService.database;
    final map = toMap(entity);
    
    // Remove ID field if it's null (for auto-increment)
    if (map.containsKey('id') && map['id'] == null) {
      map.remove('id');
    }
    
    return await db.insert(tableName, map);
  }

  /// Update existing entity
  Future<int> update(T entity) async {
    final db = databaseService.database;
    final id = getId(entity);
    
    if (id == null) {
      throw Exception('Cannot update entity without ID');
    }
    
    return await db.update(
      tableName,
      toMap(entity),
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete entity by ID
  Future<int> delete(int id) async {
    final db = databaseService.database;
    
    return await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  /// Get all entities with custom where clause
  Future<List<T>> getWhere({
    required String where,
    required List<dynamic> whereArgs,
    String? orderBy,
  }) async {
    final db = databaseService.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
    );
    
    return List.generate(maps.length, (i) => fromMap(maps[i]));
  }

  /// Execute a raw query
  Future<List<T>> rawQuery(String query, [List<dynamic>? arguments]) async {
    final db = databaseService.database;
    
    final List<Map<String, dynamic>> maps = await db.rawQuery(query, arguments);
    
    return List.generate(maps.length, (i) => fromMap(maps[i]));
  }
}