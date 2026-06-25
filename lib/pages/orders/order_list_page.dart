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

  String? _statusFilter;
  String? _typeFilter;
  String? _ownerFilter;

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
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
      ref.read(ordersProvider.notifier).loadMore();
    }
  }

  Future<void> _loadFilters() async {
    final auth = ref.read(authProvider.notifier);
    final typesNotifier = ref.read(orderTypesProvider.notifier);
    // Load from provider states
    _members = await auth.getAllMembers();
    _types = ref.read(orderTypesProvider).valueOrNull ?? [];
    if (_types.isEmpty) {
      await typesNotifier.refresh();
      _types = ref.read(orderTypesProvider).valueOrNull ?? [];
    }
    if (mounted) setState(() {});
  }

  void _applyFilters() {
    ref.read(ordersProvider.notifier).applyFilters(OrderFilters(
      status: _statusFilter,
      typeId: _typeFilter,
      ownerId: _ownerFilter,
    ));
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
      body: Column(
        children: [
          // Filter bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _statusFilter,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: '状态',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('全部状态')),
                      ...StatusBadge.allStatuses.map((s) {
                        return DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)));
                      }),
                    ],
                    onChanged: (v) {
                      _statusFilter = v;
                      _applyFilters();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _typeFilter,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: '类型',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('全部类型')),
                      ..._types.map((t) {
                        return DropdownMenuItem(value: t.id, child: Text(t.name, style: const TextStyle(fontSize: 13)));
                      }),
                    ],
                    onChanged: (v) {
                      _typeFilter = v;
                      _applyFilters();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _ownerFilter,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: '负责人',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('全部')),
                      ..._members.map((m) {
                        return DropdownMenuItem(value: m.id, child: Text(m.name, style: const TextStyle(fontSize: 13)));
                      }),
                    ],
                    onChanged: (v) {
                      _ownerFilter = v;
                      _applyFilters();
                    },
                  ),
                ),
              ],
            ),
          ),
          // Order list
          Expanded(
            child: ordersState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('加载失败：$e'),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => ref.read(ordersProvider.notifier).loadOrders(refresh: true),
                      child: const Text('重试'),
                    ),
                  ],
                ),
              ),
              data: (orders) {
                if (orders.isEmpty) {
                  return const Center(
                    child: Text('暂无订单', style: TextStyle(fontSize: 16, color: Colors.grey)),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => ref.read(ordersProvider.notifier).loadOrders(refresh: true),
                  child: ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: orders.length + (ref.read(ordersProvider.notifier).hasMore ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i >= orders.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return _OrderCard(order: orders[i]);
                    },
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

class _OrderCard extends ConsumerWidget {
  final Order order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = NumberFormat.currency(symbol: '¥', decimalDigits: 0);
    final typesState = ref.watch(orderTypesProvider);
    final types = typesState.valueOrNull ?? [];
    OrderType? match;
    try {
      match = types.firstWhere((t) => t.id == order.typeId);
    } catch (_) {}
    final typeName = match?.name ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.pushNamed(context, '/order-detail', arguments: order.id),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    order.orderNo,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey),
                  ),
                  if (typeName.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text(typeName, style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                  ],
                  const Spacer(),
                  StatusBadge(status: order.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                order.title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.person_outline, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    order.customerName,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  if (order.price != null) ...[
                    const Spacer(),
                    Text(
                      fmt.format(order.price),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.redAccent),
                    ),
                  ],
                  if (order.deadline != null) ...[
                    const SizedBox(width: 12),
                    DeadlineHighlight(deadline: order.deadline!),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
