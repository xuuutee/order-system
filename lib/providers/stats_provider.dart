import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum StatsPeriod { day, month, year }

class PeriodStat {
  final String label;
  final int count;
  final double revenue;
  const PeriodStat({required this.label, required this.count, required this.revenue});
}

class StatsData {
  final List<PeriodStat> period;
  final int totalOrders;
  final double totalRevenue;
  final int periodOrders;
  final double periodRevenue;
  final String periodLabel;

  const StatsData({
    required this.period,
    required this.totalOrders,
    required this.totalRevenue,
    required this.periodOrders,
    required this.periodRevenue,
    required this.periodLabel,
  });
}

final statsPeriodProvider = StateProvider<StatsPeriod>((ref) => StatsPeriod.day);

final statsProvider = FutureProvider<StatsData?>((ref) async {
  final period = ref.watch(statsPeriodProvider);
  return StatsService.fetch(period);
});

class StatsService {
  static final _supabase = Supabase.instance.client;

  static Future<StatsData> fetch(StatsPeriod period) async {
    DateTime start;
    int bins;
    String Function(DateTime) labelFn;
    String periodLabel;

    final now = DateTime.now();
    switch (period) {
      case StatsPeriod.day:
        start = now.subtract(const Duration(days: 6));
        bins = 7;
        labelFn = (d) => '${d.month}/${d.day}';
        periodLabel = '近 7 天';
        break;
      case StatsPeriod.month:
        start = DateTime(now.year, now.month, 1);
        bins = now.day;
        labelFn = (d) => '${d.month}/${d.day}';
        periodLabel = '本月';
        break;
      case StatsPeriod.year:
        start = DateTime(now.year, 1, 1);
        bins = 12;
        labelFn = (d) => '${d.month}月';
        periodLabel = '本年';
        break;
    }

    // 初始化所有区间
    final Map<String, PeriodStat> map = {};
    if (period == StatsPeriod.year) {
      for (int m = 1; m <= 12; m++) {
        final key = '$m';
        map[key] = PeriodStat(label: '${m}月', count: 0, revenue: 0);
      }
    } else if (period == StatsPeriod.month) {
      for (int d = 1; d <= now.day; d++) {
        final date = DateTime(now.year, now.month, d);
        final key = date.toIso8601String().substring(0, 10);
        map[key] = PeriodStat(label: labelFn(date), count: 0, revenue: 0);
      }
    } else {
      for (int i = bins - 1; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final key = date.toIso8601String().substring(0, 10);
        map[key] = PeriodStat(label: labelFn(date), count: 0, revenue: 0);
      }
    }

    final orders = await _supabase
        .from('orders')
        .select('created_at, price')
        .gte('created_at', start.toIso8601String())
        .order('created_at');

    final list = orders as List;
    int totalOrders = list.length;
    double totalRevenue = 0;

    for (final row in list) {
      final createdAt = row['created_at'] as String? ?? '';
      final price = (row['price'] as num?)?.toDouble() ?? 0;
      totalRevenue += price;

      final dt = DateTime.tryParse(createdAt) ?? now;
      String key;
      if (period == StatsPeriod.year) {
        key = '${dt.month}';
      } else {
        key = dt.toIso8601String().substring(0, 10);
      }

      if (map.containsKey(key)) {
        final old = map[key]!;
        map[key] = PeriodStat(label: old.label, count: old.count + 1, revenue: old.revenue + price);
      }
    }

    int periodOrders = 0;
    double periodRevenue = 0;
    final today = now.toIso8601String().substring(0, 10);
    for (final entry in map.entries) {
      if (period != StatsPeriod.year && entry.key == today) {
        periodOrders = entry.value.count;
        periodRevenue = entry.value.revenue;
      }
    }
    if (period == StatsPeriod.year) {
      periodOrders = totalOrders;
      periodRevenue = totalRevenue;
    }

    return StatsData(
      period: map.values.toList(),
      totalOrders: totalOrders,
      totalRevenue: totalRevenue,
      periodOrders: periodOrders,
      periodRevenue: periodRevenue,
      periodLabel: periodLabel,
    );
  }
}
