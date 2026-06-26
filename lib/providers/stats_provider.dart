import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DailyStat {
  final DateTime date;
  final int count;
  final double revenue;
  const DailyStat({required this.date, required this.count, required this.revenue});
}

class TypeStat {
  final String typeName;
  final int count;
  const TypeStat({required this.typeName, required this.count});
}

final statsProvider = FutureProvider<StatsData?>((ref) async {
  return StatsService.fetch();
});

class StatsData {
  final List<DailyStat> daily;
  final List<TypeStat> byType;
  final int totalOrders;
  final double totalRevenue;
  final int todayOrders;
  final double todayRevenue;

  const StatsData({
    required this.daily,
    required this.byType,
    required this.totalOrders,
    required this.totalRevenue,
    required this.todayOrders,
    required this.todayRevenue,
  });
}

class StatsService {
  static final _supabase = Supabase.instance.client;

  static Future<StatsData> fetch() async {
    // 最近 7 天每日统计
    final sevenDaysAgo = DateTime.now()
        .subtract(const Duration(days: 6))
        .toIso8601String()
        .substring(0, 10);

    final orders = await _supabase
        .from('orders')
        .select('created_at, price, type_id, order_types(name)')
        .gte('created_at', sevenDaysAgo)
        .order('created_at');

    final list = orders as List;

    // 按天分组
    final dayMap = <String, DailyStat>{};
    for (int i = 6; i >= 0; i--) {
      final d = DateTime.now().subtract(Duration(days: i));
      final key = d.toIso8601String().substring(0, 10);
      dayMap[key] = DailyStat(date: d, count: 0, revenue: 0);
    }

    // 按类型分组
    final typeMap = <String, int>{};
    double totalRevenue = 0;
    int totalOrders = list.length;
    int todayOrders = 0;
    double todayRevenue = 0;
    final today = DateTime.now().toIso8601String().substring(0, 10);

    for (final row in list) {
      final createdAt = row['created_at'] as String? ?? '';
      final dayKey = createdAt.substring(0, 10);
      final price = (row['price'] as num?)?.toDouble() ?? 0;
      final orderTypes = row['order_types'] as Map?;
      final typeName = (orderTypes != null ? orderTypes['name'] as String? : null) ?? '未知';

      if (dayMap.containsKey(dayKey)) {
        dayMap[dayKey] = DailyStat(
          date: dayMap[dayKey]!.date,
          count: dayMap[dayKey]!.count + 1,
          revenue: dayMap[dayKey]!.revenue + price,
        );
      }

      typeMap[typeName] = (typeMap[typeName] ?? 0) + 1;
      totalRevenue += price;

      if (dayKey == today) {
        todayOrders++;
        todayRevenue += price;
      }
    }

    return StatsData(
      daily: dayMap.values.toList(),
      byType: typeMap.entries
          .map((e) => TypeStat(typeName: e.key, count: e.value))
          .toList(),
      totalOrders: totalOrders,
      totalRevenue: totalRevenue,
      todayOrders: todayOrders,
      todayRevenue: todayRevenue,
    );
  }
}
