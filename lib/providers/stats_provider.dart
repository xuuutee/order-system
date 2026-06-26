import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

class TypeStat {
  final String name;
  final int count;
  final double amount;
  const TypeStat({required this.name, this.count = 0, this.amount = 0});
}

class TrendPoint {
  final String date; // MM-dd
  final int count;
  final double amount;
  const TrendPoint({required this.date, this.count = 0, this.amount = 0});
}

class StatsData {
  final double totalRevenue;    // 总营业额
  final double pendingAmount;   // 应收尾款（进行中+待接单）
  final int totalOrders;        // 总订单量
  final double avgPrice;        // 平均客单价
  final int inProgressCount;    // 进行中
  final int pendingDelivery;    // 待交付
  final List<TrendPoint> trend; // 趋势数据
  final List<TypeStat> typeStats; // 类型统计

  const StatsData({
    this.totalRevenue = 0,
    this.pendingAmount = 0,
    this.totalOrders = 0,
    this.avgPrice = 0,
    this.inProgressCount = 0,
    this.pendingDelivery = 0,
    this.trend = const [],
    this.typeStats = const [],
  });
}

enum StatsRange { month, year, all }

final statsProvider = StateNotifierProvider<StatsNotifier, AsyncValue<StatsData>>((ref) {
  return StatsNotifier();
});

class StatsNotifier extends StateNotifier<AsyncValue<StatsData>> {
  StatsNotifier() : super(const AsyncValue.loading()) { loadStats(); }

  static const _url = 'http://123.207.255.76:8000';
  static const _anonKey =
      'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIn0.tiSYBtsxALGOt22WxGEVpvzHN3lW6Sgs7AopMpeAfA0';

  StatsRange _range = StatsRange.month;
  StatsRange get range => _range;

  Future<void> loadStats({StatsRange? range}) async {
    if (range != null) _range = range;
    state = const AsyncValue.loading();

    try {
      final now = DateTime.now();
      String dateFilter;
      switch (_range) {
        case StatsRange.month:
          dateFilter = 'created_at=gte.${now.year}-${now.month.toString().padLeft(2, '0')}-01';
          break;
        case StatsRange.year:
          dateFilter = 'created_at=gte.${now.year}-01-01';
          break;
        case StatsRange.all:
          dateFilter = '';
          break;
      }

      // Fetch all orders + type names in parallel
      final results = await Future.wait([
        _fetch('orders?select=status,type_id,price,created_at&order=created_at.asc${dateFilter.isNotEmpty ? '&$dateFilter' : ''}'),
        _fetch('order_types?select=id,name&order=name'),
      ]);

      final orders = results[0];
      final types = results[1];
      final typeNameMap = {for (final t in types) t['id'] as String: t['name'] as String? ?? '未知'};

      _compute(orders, typeNameMap);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void _compute(List<Map<String, dynamic>> orders, Map<String, String> typeNames) {
    double totalRevenue = 0;
    double pendingAmount = 0;
    int inProgressCount = 0;
    int pendingDelivery = 0;
    final trendMap = <String, TrendPoint>{};
    final typeMap = <String, TypeStat>{};

    for (final o in orders) {
      final price = _parseDouble(o['price']);
      final status = (o['status'] as String?) ?? '';
      final typeId = (o['type_id'] as String?) ?? '';
      final date = _parseDate(o['created_at']);

      // Revenue (all orders with price)
      totalRevenue += price;

      // Pending balance (进行中 + 待接单)
      if (status == '进行中' || status == '待接单') pendingAmount += price;

      // Counts
      if (status == '进行中') inProgressCount++;
      if (status == '已交付') pendingDelivery++; // 已交付但未收款

      // Trend (by day)
      if (date != null) {
        final existing = trendMap[date];
        if (existing != null) {
          trendMap[date] = TrendPoint(date: date, count: existing.count + 1, amount: existing.amount + price);
        } else {
          trendMap[date] = TrendPoint(date: date, count: 1, amount: price);
        }
      }

      // Type stats
      final tName = typeNames[typeId] ?? typeId;
      final ts = typeMap[tName];
      if (ts != null) {
        typeMap[tName] = TypeStat(name: tName, count: ts.count + 1, amount: ts.amount + price);
      } else {
        typeMap[tName] = TypeStat(name: tName, count: 1, amount: price);
      }
    }

    final trend = trendMap.values.toList()..sort((a, b) => a.date.compareTo(b.date));
    final typeStats = typeMap.values.toList()..sort((a, b) => b.amount.compareTo(a.amount));

    state = AsyncValue.data(StatsData(
      totalRevenue: totalRevenue,
      pendingAmount: pendingAmount,
      totalOrders: orders.length,
      avgPrice: orders.isNotEmpty ? totalRevenue / orders.length : 0,
      inProgressCount: inProgressCount,
      pendingDelivery: pendingDelivery,
      trend: trend,
      typeStats: typeStats,
    ));
  }

  double _parseDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  String? _parseDate(dynamic v) {
    if (v == null) return null;
    final s = v.toString();
    return s.length >= 10 ? s.substring(5, 10) : null; // MM-dd
  }

  Future<List<Map<String, dynamic>>> _fetch(String path) async {
    try {
      final r = await http.get(Uri.parse('$_url/rest/v1/$path'), headers: {'apikey': _anonKey});
      if (r.statusCode == 200) return (jsonDecode(r.body) as List).cast<Map<String, dynamic>>();
    } catch (_) {}
    return [];
  }
}
