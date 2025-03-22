/// Data model for stock trends analytics
class StockTrendData {
  final String month;
  final int stockCount;
  final int inventoryCount;
  final DateTime date;

  StockTrendData({
    required this.month,
    required this.stockCount,
    required this.inventoryCount,
    required this.date,
  });
  
  int get totalCount => stockCount + inventoryCount;
  
  double get stockPercentage => totalCount > 0 ? stockCount / totalCount * 100 : 0;
  double get inventoryPercentage => totalCount > 0 ? inventoryCount / totalCount * 100 : 0;
}