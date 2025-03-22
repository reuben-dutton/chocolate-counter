import 'package:flutter/material.dart';

class ExpirationIndicator extends StatelessWidget {
  final Color color;
  final double size;

  const ExpirationIndicator({
    super.key,
    required this.color,
    this.size = 10.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).scaffoldBackgroundColor,
          width: 1,
        ),
      ),
    );
  }
}