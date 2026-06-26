import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:order_system/models/order.dart';
import 'package:order_system/models/order_type.dart';
import 'package:order_system/models/team_member.dart';
import 'package:order_system/providers/orders_provider.dart';
import 'package:order_system/providers/order_types_provider.dart';
import 'package:order_system/providers/auth_provider.dart';
import 'package:order_system/widgets/status_badge.dart';
import 'package:order_system/widgets/deadline_highlight.dart';

class OrderListPage extends ConsumerStatefulWidget {
  const OrderListPage({super.key});

  @override
  ConsumerState<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends ConsumerState<OrderListPage> {
  final _scrollCtrl = ScrollController();
  String? _statusFilter, _typeFilter, _ownerFilter;
  List<OrderType> _types = [];
  List<TeamMember> _members = [];

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    Future.microtask(() {
      _loadFilters();
      ref.read(ordersProvider.notifier).loadOrders(refresh: true);
    });
  }

  @override
  void dispose() { _scrollCtrl.dispose(); super.dispose(); }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
      ref.read(ordersProvider.notifier).loadMore();
    }
  }

  Future<void> _loadFilters() async {
    final auth = ref.read(authProvider.notifier);
    _members = await auth.getAllMembers();
    _types = ref.read(orderTypesProvider).valueOrNull ?? [];
    if (_types.isEmpty) {
      await ref.read(orderTypesProvider.notifier).refresh();
      _types = ref.read(orderTypesProvider).valueOrNull ?? [];
    }
    if (mounted) setState(() {});
  }

  void _applyFilters() {
    ref.read(ordersProvider.notifier).applyFilters(OrderFilters(
      status: _statusFilter, typeId: _typeFilter, ownerId: _ownerFilter,
    ));
  }

  Future<void> _confirmDelete(Order order) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除订单'),
        content: Text('确定要删除「${order.title}」吗？\n此操作不可撤销。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确认删除'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(ordersProvider.notifier).deleteOrder(order.id);
    }
  }

  Future<void> _editOwner(Order order) async {
    String? selected = order.primaryOwner;
    final members = _members;
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('修改负责人'),
        content: DropdownButtonFormField<String>(
          initialValue: selected,
          decoration: const InputDecoration(labelText: '负责人', border: OutlineInputBorder()),
          items: members.map((m) => DropdownMenuItem(value: m.id, child: Text(m.name))).toList(),
          onChanged: (v) => selected = v,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, selected),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    if (result != null && result != order.primaryOwner) {
      await ref.read(ordersProvider.notifier).updateOrder(order.id, {'primary_owner': result});
    }
  }

  @override
  Widget build(BuildContext context) {
    final ordersState = ref.watch(ordersProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('订单列表'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(ordersProvider.notifier).loadOrders(refresh: true),
          ),
        ],
      ),
      body: Column(children: [
        // Filter bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(children: [
            _filterDropdown('状态', _statusFilter, [
              const DropdownMenuItem(value: null, child: Text('全部状态')),
              ...StatusBadge.allStatuses.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))),
            ], (v) { _statusFilter = v; _applyFilters(); }),
            const SizedBox(width: 8),
            _filterDropdown('类型', _typeFilter, [
              const DropdownMenuItem(value: null, child: Text('全部类型')),
              ..._types.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name, style: const TextStyle(fontSize: 13)))),
            ], (v) { _typeFilter = v; _applyFilters(); }),
            const SizedBox(width: 8),
            _filterDropdown('负责人', _ownerFilter, [
              const DropdownMenuItem(value: null, child: Text('全部')),
              ..._members.map((m) => DropdownMenuItem(value: m.id, child: Text(m.name, style: const TextStyle(fontSize: 13)))),
            ], (v) { _ownerFilter = v; _applyFilters(); }),
          ]),
        ),
        Expanded(
          child: ordersState.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('加载失败：$e'), const SizedBox(height: 12),
                FilledButton(onPressed: () => ref.read(ordersProvider.notifier).loadOrders(refresh: true), child: const Text('重试')),
              ]),
            ),
            data: (orders) {
              if (orders.isEmpty) return const Center(child: Text('暂无订单', style: TextStyle(fontSize: 16, color: Colors.grey)));
              return RefreshIndicator(
                onRefresh: () => ref.read(ordersProvider.notifier).loadOrders(refresh: true),
                child: ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: orders.length + (ref.read(ordersProvider.notifier).hasMore ? 1 : 0),
                  itemBuilder: (ctx, i) {
                    if (i >= orders.length) return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()));
                    return _OrderCard(order: orders[i], onDelete: () => _confirmDelete(orders[i]), onEditOwner: () => _editOwner(orders[i]));
                  },
                ),
              );
            },
          ),
        ),
      ]),
    );
  }

  Widget _filterDropdown(String label, String? value, List<DropdownMenuItem<String>> items, ValueChanged<String?> onChanged) {
    return Expanded(
      child: DropdownButtonFormField<String>(
        initialValue: value, isExpanded: true,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
        items: items, onChanged: onChanged,
      ),
    );
  }
}

class _OrderCard extends ConsumerWidget {
  final Order order;
  final VoidCallback onDelete;
  final VoidCallback onEditOwner;
  const _OrderCard({required this.order, required this.onDelete, required this.onEditOwner});

  static const _typeColors = [Colors.blue, Colors.orange, Colors.teal, Colors.purple, Colors.pink, Colors.indigo];
  static const _typeIcons = {
    'school': Icons.school, 'slideshow': Icons.slideshow, 'edit_note': Icons.edit_note,
    'assignment': Icons.assignment, 'description': Icons.description, 'checklist': Icons.checklist,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = NumberFormat.currency(symbol: '¥', decimalDigits: 0);
    final types = ref.watch(orderTypesProvider).valueOrNull ?? [];
    OrderType? match;
    try { match = types.firstWhere((t) => t.id == order.typeId); } catch (_) {}
    final typeName = match?.name ?? '订单';
    final typeIcon = match?.icon ?? 'assignment';
    final colorIndex = (order.typeId?.hashCode ?? 0).abs() % _typeColors.length;

    return Dismissible(
      key: Key(order.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async { onDelete(); return false; },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.pushNamed(context, '/order-detail', arguments: order.id),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                // 类型标签 — 醒目彩色
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _typeColors[colorIndex].withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _typeColors[colorIndex].withAlpha(100)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(_typeIcons[typeIcon] ?? Icons.receipt_long, size: 16, color: _typeColors[colorIndex]),
                    const SizedBox(width: 4),
                    Text(typeName, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _typeColors[colorIndex])),
                  ]),
                ),
                const Spacer(),
                Text(order.orderNo, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(width: 8),
                StatusBadge(status: order.status),
              ]),
              const SizedBox(height: 10),
              Text(order.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
              Row(children: [
                Icon(Icons.person_outline, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(order.customerName, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                const Spacer(),
                if (order.price != null) ...[
                  Text(fmt.format(order.price), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.redAccent)),
                  const SizedBox(width: 10),
                ],
                if (order.deadline != null) DeadlineHighlight(deadline: order.deadline!),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 18),
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'owner', child: ListTile(leading: Icon(Icons.person_add), title: Text('修改负责人'), dense: true)),
                    const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete, color: Colors.red), title: Text('删除订单', style: TextStyle(color: Colors.red)), dense: true)),
                  ],
                  onSelected: (v) {
                    if (v == 'delete') onDelete();
                    if (v == 'owner') onEditOwner();
                  },
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}
