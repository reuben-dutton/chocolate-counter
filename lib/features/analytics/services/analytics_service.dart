import 'package:food_inventory/features/analytics/models/analytics_data.dart';
import 'package:food_inventory/features/analytics/repositories/analytics_repository.dart';
import 'package:sqflite/sqflite.dart';

/// Service for analytics-related operations
class AnalyticsService {
  final AnalyticsRepository _analyticsRepository;

  AnalyticsService(this._analyticsRepository);

  /// Get data for most popular (most sold) items
  Future<AnalyticsData> getPopularItemsData({Transaction? txn}) async {
    final rawData = await _analyticsRepository.getPopularItems(txn: txn);
    
    final List<PopularItemData> popularItems = [];
    
    for (final item in rawData) {
      final itemName = item['itemName'] as String;
      final salesCount = item['salesCount'] as int;
      
      popularItems.add(PopularItemData(
        itemName: itemName,
        salesCount: salesCount,
      ));
    }
    
    return AnalyticsData(popularItems: popularItems);
  }
}