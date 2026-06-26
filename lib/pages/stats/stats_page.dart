import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:order_system/providers/stats_provider.dart';

class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(statsPeriodProvider);
    final statsAsync = ref.watch(statsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('统计总览')),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('加载失败：$e'), const SizedBox(height: 12),
            FilledButton(onPressed: () => ref.invalidate(statsProvider), child: const Text('重试')),
          ]),
        ),
        data: (stats) {
          if (stats == null) return const Center(child: Text('暂无数据'));
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(statsProvider),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _PeriodToggle(current: period),
                const SizedBox(height: 12),
                _SummaryCards(stats: stats),
                const SizedBox(height: 16),
                _BarChartSection(period: stats.period, periodLabel: stats.periodLabel),
                const SizedBox(height: 16),
                _TotalRow(stats: stats),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PeriodToggle extends ConsumerWidget {
  final StatsPeriod current;
  const _PeriodToggle({required this.current});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(children: [
      for (final p in StatsPeriod.values) ...[
        Expanded(
          child: ChoiceChip(
            label: Text(p == StatsPeriod.day ? '日' : p == StatsPeriod.month ? '月' : '年'),
            selected: current == p,
            onSelected: (_) => ref.read(statsPeriodProvider.notifier).state = p,
          ),
        ),
        if (p != StatsPeriod.year) const SizedBox(width: 8),
      ],
    ]);
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
              Text(stats.periodLabel, style: const TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 4),
              Text('${stats.periodOrders}', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
              const Text('单', style: TextStyle(fontSize: 14, color: Colors.grey)),
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
              Text(stats.periodLabel, style: const TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 4),
              Text(fmt.format(stats.periodRevenue).replaceFirst('¥', ''),
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green)),
              Row(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
                const Text('¥', style: TextStyle(fontSize: 14, color: Colors.green)),
                const Text(' 营收', style: TextStyle(fontSize: 14, color: Colors.grey)),
              ]),
            ]),
          ),
        ),
      ),
    ]);
  }
}

class _BarChartSection extends StatelessWidget {
  final List<PeriodStat> period;
  final String periodLabel;
  const _BarChartSection({required this.period, required this.periodLabel});

  @override
  Widget build(BuildContext context) {
    final maxCount = period.fold<double>(0, (m, s) => s.count > m ? s.count.toDouble() : m);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$periodLabel 订单量', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Row(children: [
            Text('共 ${period.fold<int>(0, (s, p) => s + p.count)} 单',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
            const Spacer(),
            Text('¥${NumberFormat.currency(symbol: '', decimalDigits: 0).format(period.fold<double>(0, (s, p) => s + p.revenue))}',
                style: TextStyle(fontSize: 14, color: Colors.red.shade400, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                maxY: (maxCount + 1).clamp(3, double.infinity),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final s = period[group.x.toInt()];
                      return BarTooltipItem('${s.label}\n${s.count}单 ¥${s.revenue.toStringAsFixed(0)}',
                          const TextStyle(color: Colors.white, fontSize: 12));
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true, reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= period.length) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(period[i].label, style: const TextStyle(fontSize: 10)),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true, reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        if (value == value.roundToDouble()) {
                          return Text('${value.toInt()}', style: const TextStyle(fontSize: 10));
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
                barGroups: period.asMap().entries.map((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value.count.toDouble(),
                        color: Theme.of(context).colorScheme.primary,
                        width: period.length > 20 ? 4 : 16,
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

class _TotalRow extends StatelessWidget {
  final StatsData stats;
  const _TotalRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: '¥', decimalDigits: 0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _StatItem(label: '总订单', value: '${stats.totalOrders}'),
          _StatItem(label: '总营收', value: fmt.format(stats.totalRevenue)),
          _StatItem(label: '均价', value: stats.totalOrders > 0
              ? fmt.format(stats.totalRevenue / stats.totalOrders) : '--'),
        ]),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label, value;
  const _StatItem({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
    ]);
  }
}
