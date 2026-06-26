import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:order_system/providers/stats_provider.dart';

class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(statsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('统计总览')),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('加载失败：$e'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => ref.invalidate(statsProvider),
              child: const Text('重试'),
            ),
          ]),
        ),
        data: (stats) {
          if (stats == null) return const Center(child: Text('暂无数据'));
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(statsProvider),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SummaryCards(stats: stats),
                const SizedBox(height: 20),
                _BarChartSection(daily: stats.daily),
                const SizedBox(height: 20),
                _PieChartSection(byType: stats.byType),
                const SizedBox(height: 20),
                _TotalSection(stats: stats),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryCards extends StatelessWidget {
  final StatsData stats;
  const _SummaryCards({required this.stats});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: '¥', decimalDigits: 0);
    return Row(children: [
      Expanded(
        child: Card(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              const Text('今日订单', style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 4),
              Text('${stats.todayOrders}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            ]),
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Card(
          color: Colors.green.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              const Text('今日营收', style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 4),
              Text(fmt.format(stats.todayRevenue),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
            ]),
          ),
        ),
      ),
    ]);
  }
}

class _BarChartSection extends StatelessWidget {
  final List<DailyStat> daily;
  const _BarChartSection({required this.daily});

  @override
  Widget build(BuildContext context) {
    final maxY = daily.map((d) => d.count.toDouble()).reduce((a, b) => a > b ? a : b);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('近 7 天订单量', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                maxY: (maxY + 1).clamp(3, double.infinity),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final d = daily[group.x.toInt()];
                      return BarTooltipItem(
                        '${DateFormat('MM/dd').format(d.date)}\n${d.count}单',
                        const TextStyle(color: Colors.white, fontSize: 12),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= daily.length) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(DateFormat('MM/dd').format(daily[i].date),
                              style: const TextStyle(fontSize: 10)),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        if (value == value.roundToDouble()) {
                          return Text('${value.toInt()}',
                              style: const TextStyle(fontSize: 10));
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: daily.asMap().entries.map((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value.count.toDouble(),
                        color: Theme.of(context).colorScheme.primary,
                        width: 20,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _PieChartSection extends StatelessWidget {
  final List<TypeStat> byType;
  const _PieChartSection({required this.byType});

  @override
  Widget build(BuildContext context) {
    final colors = [Colors.blue, Colors.orange, Colors.green, Colors.red, Colors.purple, Colors.teal];
    final total = byType.fold<int>(0, (s, t) => s + t.count);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('订单类型分布', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: Row(children: [
              Expanded(
                flex: 3,
                child: PieChart(
                  PieChartData(
                    sections: byType.asMap().entries.map((e) {
                      final pct = total > 0 ? (e.value.count / total * 100) : 0;
                      return PieChartSectionData(
                        color: colors[e.key % colors.length],
                        value: e.value.count.toDouble(),
                        title: '${pct.toStringAsFixed(0)}%',
                        titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                        radius: 60,
                      );
                    }).toList(),
                    sectionsSpace: 2,
                    centerSpaceRadius: 30,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: byType.asMap().entries.map((e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(width: 10, height: 10,
                          decoration: BoxDecoration(color: colors[e.key % colors.length], shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Expanded(child: Text(e.value.typeName,
                          style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                      Text('${e.value.count}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ]),
                  )).toList(),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _TotalSection extends StatelessWidget {
  final StatsData stats;
  const _TotalSection({required this.stats});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: '¥', decimalDigits: 0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _StatItem(label: '总订单', value: '${stats.totalOrders}'),
          _StatItem(label: '总营收', value: fmt.format(stats.totalRevenue)),
          _StatItem(label: '日均', value: '${(stats.totalOrders / 7).toStringAsFixed(1)}单'),
        ]),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
    ]);
  }
}
