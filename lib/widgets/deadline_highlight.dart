import 'package:flutter/material.dart';

/// Highlights deadline text with color: red if overdue, orange if within 3 days.
class DeadlineHighlight extends StatelessWidget {
  final DateTime deadline;

  const DeadlineHighlight({super.key, required this.deadline});

  Color _color() {
    final now = DateTime.now();
    if (deadline.isBefore(now)) {
      return const Color(0xFFF44336); // red — overdue
    }
    final diff = deadline.difference(now);
    if (diff.inDays < 3) {
      return const Color(0xFFFF9800); // orange — approaching
    }
    return Colors.grey;
  }

  String _text() {
    final now = DateTime.now();
    final diff = deadline.difference(now);
    if (diff.isNegative) {
      return '已超期 ${-diff.inDays}天';
    }
    if (diff.inDays == 0) {
      return '今天截止';
    }
    if (diff.inDays < 3) {
      return '${diff.inDays}天后截止';
    }
    return '${deadline.month}/${deadline.day} 截止';
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _text(),
      style: TextStyle(
        color: _color(),
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
