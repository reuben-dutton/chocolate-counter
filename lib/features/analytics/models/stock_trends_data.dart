import 'package:food_inventory/features/analytics/models/stock_trend_data.dart';

/// Container for stock trends analytics data
class StockTrendsData {
  final List<StockTrendData> trendData;
  
  const StockTrendsData({
    required this.trendData,
  });
}