/// Data model for popular item analytics
class PopularItemData {
  final String itemName;
  final int salesCount;

  PopularItemData({
    required this.itemName,
    required this.salesCount,
  });
}

/// Container for all analytics data
class AnalyticsData {
  final List<PopularItemData> popularItems;
  
  const AnalyticsData({
    required this.popularItems,
  });
}