// UI Preview — standalone, no Supabase needed. Run with:
// flutter run -t lib/main_preview.dart -d chrome

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:order_system/widgets/status_badge.dart';
import 'package:order_system/widgets/deadline_highlight.dart';
import 'package:order_system/widgets/dynamic_form_fields.dart';
import 'package:order_system/models/order_type.dart';

void main() {
  runApp(const PreviewApp());
}

class PreviewApp extends StatelessWidget {
  const PreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '订单管理 - 预览',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: true),
      ),
      home: const PreviewHome(),
    );
  }
}

// ═══════════════════════════════════════════
// Mock Data
// ═══════════════════════════════════════════

const _mockOrders = [
  {'orderNo': 'OD20260625001', 'type': '网课代修', 'title': '高等数学网课代修', 'customer': '张三', 'status': '进行中', 'price': 1200.0, 'deadline': '2026-07-01'},
  {'orderNo': 'OD20260625002', 'type': 'PPT制作', 'title': '毕业论文答辩PPT', 'customer': '李四', 'status': '待接单', 'price': 500.0, 'deadline': '2026-06-28'},
  {'orderNo': 'OD20260624003', 'type': '文档排版', 'title': '期刊论文LaTeX排版', 'customer': '王五', 'status': '已交付', 'price': 800.0, 'deadline': '2026-06-20'},
  {'orderNo': 'OD20260623004', 'type': '网课代修', 'title': '线性代数刷课', 'customer': '赵六', 'status': '已收款', 'price': 1500.0, 'deadline': '2026-06-30'},
  {'orderNo': 'OD20260622005', 'type': 'PPT制作', 'title': '项目路演PPT美化', 'customer': '陈七', 'status': '取消', 'price': 300.0, 'deadline': '2026-06-25'},
];

final _mockFieldsSchema = [
  const FieldSchema(key: 'course_platform', label: '课程平台', type: 'text', required: true),
  const FieldSchema(key: 'course_name', label: '课程名称', type: 'text', required: true),
  const FieldSchema(key: 'language', label: '语言', type: 'select', options: ['中文', '英文']),
  const FieldSchema(key: 'page_count', label: '页数', type: 'number', required: true),
];

// ═══════════════════════════════════════════
// Home Shell
// ═══════════════════════════════════════════

class PreviewHome extends StatefulWidget {
  const PreviewHome({super.key});

  @override
  State<PreviewHome> createState() => _PreviewHomeState();
}

class _PreviewHomeState extends State<PreviewHome> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    const pages = [
      _PreviewOrderList(),
      _PreviewOrderForm(),
      _PreviewStats(),
      _PreviewProfile(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.list_alt), selectedIcon: Icon(Icons.list_alt, color: Colors.blue), label: '订单列表'),
          NavigationDestination(icon: Icon(Icons.add_circle_outline, size: 28), selectedIcon: Icon(Icons.add_circle, color: Colors.blue, size: 28), label: '新建订单'),
          NavigationDestination(icon: Icon(Icons.bar_chart), selectedIcon: Icon(Icons.bar_chart, color: Colors.blue), label: '统计总览'),
          NavigationDestination(icon: Icon(Icons.person), selectedIcon: Icon(Icons.person, color: Colors.blue), label: '我的'),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
// Tab 1: Order List
// ═══════════════════════════════════════════

class _PreviewOrderList extends StatelessWidget {
  const _PreviewOrderList();

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: '¥', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(title: const Text('订单列表')),
      body: Column(
        children: [
          // Filter bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: null,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: '状态',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    items: [const DropdownMenuItem(value: null, child: Text('全部状态')), ...StatusBadge.allStatuses.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13))))],
                    onChanged: (_) {},
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: null,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: '类型',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    items: [const DropdownMenuItem(value: null, child: Text('全部类型')), ...['网课代修', 'PPT制作', '文档排版'].map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13))))],
                    onChanged: (_) {},
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: null,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: '负责人',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    items: [const DropdownMenuItem(value: null, child: Text('全部')), ...['小明', '小红', '小刚'].map((n) => DropdownMenuItem(value: n, child: Text(n, style: const TextStyle(fontSize: 13))))],
                    onChanged: (_) {},
                  ),
                ),
              ],
            ),
          ),
          // Card list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _mockOrders.length,
              itemBuilder: (_, i) {
                final o = _mockOrders[i];
                final deadline = DateTime.parse(o['deadline'] as String).add(Duration(days: i - 2));
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(o['orderNo'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
                            const SizedBox(width: 8),
                            Text(o['type'] as String, style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                            const Spacer(),
                            StatusBadge(status: o['status'] as String),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(o['title'] as String, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.person_outline, size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text(o['customer'] as String, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                            const Spacer(),
                            Text(fmt.format(o['price']), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.redAccent)),
                            const SizedBox(width: 12),
                            DeadlineHighlight(deadline: deadline),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
// Tab 2: Order Form (simplified)
// ═══════════════════════════════════════════

class _PreviewOrderForm extends StatefulWidget {
  const _PreviewOrderForm();

  @override
  State<_PreviewOrderForm> createState() => _PreviewOrderFormState();
}

class _PreviewOrderFormState extends State<_PreviewOrderForm> {
  int? _selectedTypeIndex;
  DateTime? _deadline;
  bool _showMore = false;

  final _types = const [
    {'name': '网课代修', 'icon': Icons.school},
    {'name': 'PPT制作', 'icon': Icons.slideshow},
    {'name': '文档排版', 'icon': Icons.description},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('新建订单')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ═══ Type selector ═══
            const Text('订单类型', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _types.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final t = _types[i];
                  final selected = _selectedTypeIndex == i;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedTypeIndex = i),
                    child: Container(
                      width: 100,
                      decoration: BoxDecoration(
                        color: selected ? Theme.of(context).colorScheme.primaryContainer : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: selected ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2) : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(t['icon'] as IconData, size: 28,
                              color: selected ? Theme.of(context).colorScheme.primary : Colors.grey),
                          const SizedBox(height: 4),
                          Text(t['name'] as String, style: TextStyle(fontSize: 12,
                              fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // ═══ Deadline ═══
            InkWell(
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _deadline ?? DateTime.now().add(const Duration(days: 7)),
                  firstDate: DateTime.now().subtract(const Duration(days: 30)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (d != null) setState(() => _deadline = d);
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: '截止日期',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  _deadline != null
                      ? '${_deadline!.year}-${_deadline!.month.toString().padLeft(2, '0')}-${_deadline!.day.toString().padLeft(2, '0')}'
                      : '选择日期',
                  style: TextStyle(color: _deadline != null ? null : Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ═══ Price ═══
            TextFormField(
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: '金额',
                border: OutlineInputBorder(),
                prefixText: '¥ ',
                prefixIcon: Icon(Icons.monetization_on_outlined),
              ),
            ),
            const SizedBox(height: 16),

            // ═══ More toggle ═══
            InkWell(
              onTap: () => setState(() => _showMore = !_showMore),
              child: Row(
                children: [
                  Icon(_showMore ? Icons.expand_less : Icons.expand_more,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 4),
                  Text('更多信息', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.primary)),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ═══ More fields ═══
            if (_showMore) ...[
              TextFormField(decoration: const InputDecoration(labelText: '客户名称', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextFormField(decoration: const InputDecoration(labelText: '联系方式', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextFormField(decoration: const InputDecoration(labelText: '标题', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextFormField(maxLines: 2, decoration: const InputDecoration(labelText: '描述', border: OutlineInputBorder(), alignLabelWithHint: true)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: null,
                decoration: const InputDecoration(labelText: '负责人', border: OutlineInputBorder()),
                items: ['小明', '小红', '小刚'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                onChanged: (_) {},
              ),
              if (_selectedTypeIndex != null) ...[
                const SizedBox(height: 12),
                DynamicFormFields(fieldsSchema: _mockFieldsSchema, onChanged: (_) {}),
              ],
            ],

            const SizedBox(height: 32),

            // ═══ Save ═══
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.save),
                label: const Text('保存订单', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// Tab 3: Stats
// ═══════════════════════════════════════════

class _PreviewStats extends StatelessWidget {
  const _PreviewStats();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('统计总览')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('统计功能将在后续版本上线', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// Tab 4: Profile
// ═══════════════════════════════════════════

class _PreviewProfile extends StatelessWidget {
  const _PreviewProfile();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(Icons.person, size: 40, color: Theme.of(context).colorScheme.primary),
              ),
            ),
            const SizedBox(height: 24),
            const Center(child: Text('admin@studio.com', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500))),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text('退出登录', style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red), padding: const EdgeInsets.symmetric(vertical: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
