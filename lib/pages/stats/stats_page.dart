import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:order_system/providers/stats_provider.dart';

class StatsPage extends ConsumerStatefulWidget {
  const StatsPage({super.key});
  @override
  ConsumerState<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends ConsumerState<StatsPage> {
  bool _typeByAmount = true;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(statsProvider);
    final ntf = ref.read(statsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('统计总览')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('加载失败'), const SizedBox(height: 12),
            FilledButton(onPressed: () => ntf.loadStats(), child: const Text('重试')),
          ]),
        ),
        data: (s) => RefreshIndicator(
          onRefresh: () => ntf.loadStats(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // ═══ 时间筛选 ═══
              _TimeFilter(range: ntf.range, onChanged: (r) => ntf.loadStats(range: r)),
              const SizedBox(height: 14),

              // ═══ 核心指标卡 ═══
              _TopCards(s: s),
              const SizedBox(height: 20),

              // ═══ 双轴趋势图 ═══
              if (s.trend.isNotEmpty) ...[
                const Text('营收与订单趋势', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                const Text('柱=交易额  |  折线=订单量', style: TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 200,
                  child: _TrendChart(data: s.trend),
                ),
                const SizedBox(height: 20),
              ],

              // ═══ 环形图 ═══
              if (s.typeStats.isNotEmpty) ...[
                Row(children: [
                  const Text('订单类型占比', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  _ToggleChip(
                    labels: const ['按交易额', '按订单量'],
                    selectedIndex: _typeByAmount ? 0 : 1,
                    onChanged: (i) => setState(() => _typeByAmount = i == 0),
                  ),
                ]),
                const SizedBox(height: 8),
                SizedBox(
                  height: 200,
                  child: _DonutChart(
                    data: s.typeStats,
                    byAmount: _typeByAmount,
                    totalOrders: s.totalOrders,
                    totalAmount: s.totalRevenue,
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // ═══ 关键看板 ═══
              const Text('关键指标', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              _DashboardRow(s: s),

              const SizedBox(height: 60),
            ]),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// 时间筛选
// ═══════════════════════════════════════════

class _TimeFilter extends StatelessWidget {
  final StatsRange range;
  final void Function(StatsRange) onChanged;
  const _TimeFilter({required this.range, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<StatsRange>(
      segments: const [
        ButtonSegment(value: StatsRange.month, label: Text('本月')),
        ButtonSegment(value: StatsRange.year, label: Text('本年')),
        ButtonSegment(value: StatsRange.all, label: Text('全部')),
      ],
      selected: {range},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final void Function(int) onChanged;
  const _ToggleChip({required this.labels, required this.selectedIndex, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      for (int i = 0; i < labels.length; i++) ...[
        if (i > 0) const SizedBox(width: 4),
        GestureDetector(
          onTap: () => onChanged(i),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: i == selectedIndex ? Theme.of(context).colorScheme.primary : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(labels[i], style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w500,
              color: i == selectedIndex ? Colors.white : Colors.grey.shade700,
            )),
          ),
        ),
      ],
    ]);
  }
}

// ═══════════════════════════════════════════
// 顶部指标卡
// ═══════════════════════════════════════════

class _TopCards extends StatelessWidget {
  final StatsData s;
  const _TopCards({required this.s});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: '¥', decimalDigits: 0);
    return Row(children: [
      _KpiCard(label: '总营业额', value: fmt.format(s.totalRevenue), color: Colors.green, icon: Icons.trending_up),
      const SizedBox(width: 8),
      _KpiCard(label: '应收尾款', value: fmt.format(s.pendingAmount), color: Colors.orange, icon: Icons.pending),
      const SizedBox(width: 8),
      _KpiCard(label: '总订单量', value: '${s.totalOrders}单', color: Colors.blue, icon: Icons.receipt_long),
    ]);
  }
}

class _KpiCard extends StatelessWidget {
  final String label, value;
  final Color color;
  final IconData icon;
  const _KpiCard({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withAlpha(18),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Column(children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: color.withAlpha(180))),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// 双轴趋势图（柱=交易额，线=订单量）
// ═══════════════════════════════════════════

class _TrendChart extends StatelessWidget {
  final List<TrendPoint> data;
  const _TrendChart({required this.data});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _TrendPainter(data: data),
    );
  }
}

class _TrendPainter extends CustomPainter {
  final List<TrendPoint> data;
  _TrendPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final w = size.width;
    final h = size.height;
    final pad = const EdgeInsets.only(left: 44, top: 16, right: 12, bottom: 28);
    final cw = w - pad.left - pad.right;
    final ch = h - pad.top - pad.bottom;

    final maxAmount = data.map((d) => d.amount).reduce(max);
    final maxCount = data.map((d) => d.count).reduce(max);
    if (maxAmount == 0 && maxCount == 0) return;

    final barPaint = Paint()..color = Colors.blue.withAlpha(100);
    final linePaint = Paint()..color = Colors.red..strokeWidth = 2..style = PaintingStyle.stroke;
    final dotPaint = Paint()..color = Colors.red..style = PaintingStyle.fill;
    final textStyle = TextStyle(fontSize: 10, color: Colors.grey.shade600);

    // Bars
    final barW = (cw / data.length) * 0.6;
    for (int i = 0; i < data.length; i++) {
      final x = pad.left + (cw / data.length) * i + (cw / data.length - barW) / 2;
      final barH = maxAmount > 0 ? (data[i].amount / maxAmount) * ch : 0.0;
      canvas.drawRRect(
        RRect.fromLTRBR(x, pad.top + ch - barH, x + barW, pad.top + ch, const Radius.circular(2)),
        barPaint,
      );
      // Label
      if (data.length <= 31) {
        final tp = TextPainter(text: TextSpan(text: data[i].date, style: textStyle), textDirection: ui.TextDirection.ltr);
        tp.layout();
        tp.paint(canvas, Offset(x + barW / 2 - tp.width / 2, pad.top + ch + 4));
      }
    }

    // Line
    final path = Path();
    for (int i = 0; i < data.length; i++) {
      final x = pad.left + (cw / data.length) * i + cw / data.length / 2;
      final y = pad.top + ch - (maxCount > 0 ? (data[i].count / maxCount) * ch : 0.0);
      if (i == 0) { path.moveTo(x, y); } else { path.lineTo(x, y); }
    }
    canvas.drawPath(path, linePaint);

    // Dot on last point
    final lx = pad.left + (cw / data.length) * (data.length - 1) + cw / data.length / 2;
    final ly = pad.top + ch - (maxCount > 0 ? (data.last.count / maxCount) * ch : 0.0);
    canvas.drawCircle(Offset(lx, ly), 4, dotPaint);

    // Axis labels
    final amtTp = TextPainter(text: TextSpan(text: '${maxAmount.toInt()}', style: textStyle), textDirection: ui.TextDirection.ltr)..layout();
    amtTp.paint(canvas, Offset(pad.left - amtTp.width - 4, pad.top - 5));
    final cntTp = TextPainter(text: TextSpan(text: '${maxCount}单', style: textStyle), textDirection: ui.TextDirection.ltr)..layout();
    cntTp.paint(canvas, Offset(pad.left - cntTp.width - 4, pad.top + ch));
  }

  @override
  bool shouldRepaint(covariant _TrendPainter old) => old.data != data;
}

// ═══════════════════════════════════════════
// 环形图
// ═══════════════════════════════════════════

class _DonutChart extends StatelessWidget {
  final List<TypeStat> data;
  final bool byAmount;
  final int totalOrders;
  final double totalAmount;
  const _DonutChart({required this.data, required this.byAmount, required this.totalOrders, required this.totalAmount});

  static const _colors = [
    Colors.blue, Colors.green, Colors.orange, Colors.purple,
    Colors.red, Colors.teal, Colors.pink, Colors.indigo,
    Colors.amber, Colors.cyan,
  ];

  @override
  Widget build(BuildContext context) {
    final total = byAmount ? totalAmount : totalOrders.toDouble();
    return Row(children: [
      // Donut
      SizedBox(
        width: 140, height: 140,
        child: CustomPaint(
          painter: _DonutPainter(
            segments: data.map((t) => _DonutSegment(
              label: t.name,
              value: byAmount ? t.amount : t.count.toDouble(),
              color: _colors[data.indexOf(t) % _colors.length],
            )).toList(),
            total: total,
            centerText: byAmount ? '${totalAmount.toInt()}' : '$totalOrders',
            centerSub: byAmount ? '交易额' : '订单量',
          ),
        ),
      ),
      const SizedBox(width: 12),
      // Legend
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: data.take(8).map((t) {
            final v = byAmount ? t.amount : t.count.toDouble();
            final pct = total > 0 ? (v / total * 100).toStringAsFixed(0) : '0';
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(
                  color: _colors[data.indexOf(t) % _colors.length], shape: BoxShape.circle,
                )),
                const SizedBox(width: 6),
                Expanded(child: Text(t.name, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                Text('$pct%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ]),
            );
          }).toList(),
        ),
      ),
    ]);
  }
}

class _DonutSegment {
  final String label;
  final double value;
  final Color color;
  const _DonutSegment({required this.label, required this.value, required this.color});
}

class _DonutPainter extends CustomPainter {
  final List<_DonutSegment> segments;
  final double total;
  final String centerText;
  final String centerSub;
  _DonutPainter({required this.segments, required this.total, required this.centerText, required this.centerSub});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = min(cx, cy) - 8;
    final innerRadius = radius * 0.58;

    double startAngle = -pi / 2;
    final effectiveTotal = total > 0 ? total : 1.0;

    for (final seg in segments) {
      final sweep = (seg.value / effectiveTotal) * 2 * pi;
      final paint = Paint()..color = seg.color..style = PaintingStyle.fill;
      canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: radius), startAngle, sweep, true, paint);
      startAngle += sweep;
    }

    // Inner circle (white center)
    final innerPaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), innerRadius, innerPaint);

    // Center text
    final tp1 = TextPainter(
      text: TextSpan(text: centerText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    tp1.paint(canvas, Offset(cx - tp1.width / 2, cy - tp1.height));

    final tp2 = TextPainter(
      text: TextSpan(text: centerSub, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    tp2.paint(canvas, Offset(cx - tp2.width / 2, cy + 4));
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) => old.segments != segments;
}

// ═══════════════════════════════════════════
// 关键指标看板
// ═══════════════════════════════════════════

class _DashboardRow extends StatelessWidget {
  final StatsData s;
  const _DashboardRow({required this.s});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: '¥', decimalDigits: 0);
    return Wrap(spacing: 10, runSpacing: 10, children: [
      _DashItem(icon: Icons.hourglass_empty, label: '进行中', value: '${s.inProgressCount} 单', color: Colors.blue),
      _DashItem(icon: Icons.check_circle_outline, label: '已交付', value: '${s.pendingDelivery} 单', color: Colors.orange),
      _DashItem(icon: Icons.monetization_on_outlined, label: '平均客单价', value: fmt.format(s.avgPrice), color: Colors.green),
      _DashItem(icon: Icons.trending_up, label: '趋势', value: s.totalOrders > 0 ? '${(s.inProgressCount / s.totalOrders * 100).toInt()}%完成率' : '-', color: Colors.purple),
    ]);
  }
}

class _DashItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _DashItem({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color)),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ]),
      ]),
    );
  }
}
