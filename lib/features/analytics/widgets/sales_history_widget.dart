import 'package:flutter/material.dart';
import 'package:food_inventory/features/analytics/widgets/analytics_card.dart';

class SalesHistoryWidget extends StatelessWidget {
  const SalesHistoryWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const AnalyticsCard(
      title: 'Sales History',
      icon: Icons.attach_money,
      child: Center(
        heightFactor: 2,
        child: Text('Sales History Coming Soon'),
      ),
    );
  }
}