import 'package:flutter/material.dart';

/// Color mapping for order statuses.
class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  static Color colorForStatus(String status) {
    switch (status) {
      case '待接单':
        return const Color(0xFF9E9E9E);
      case '进行中':
        return const Color(0xFF2196F3);
      case '已交付':
        return const Color(0xFFFF9800);
      case '已收款':
        return const Color(0xFF4CAF50);
      case '已关闭':
        return const Color(0xFF616161);
      case '取消':
        return const Color(0xFFF44336);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  static String labelForStatus(String status) => status;

  static const List<String> allStatuses = [
    '待接单',
    '进行中',
    '已交付',
    '已收款',
    '已关闭',
    '取消',
  ];

  @override
  Widget build(BuildContext context) {
    final color = colorForStatus(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
