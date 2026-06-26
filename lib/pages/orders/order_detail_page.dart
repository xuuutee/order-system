import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'package:order_system/models/order.dart';
import 'package:order_system/models/order_type.dart';
import 'package:order_system/models/team_member.dart';
import 'package:order_system/providers/orders_provider.dart';
import 'package:order_system/providers/auth_provider.dart';
import 'package:order_system/widgets/status_badge.dart';
import 'package:order_system/widgets/deadline_highlight.dart';

class OrderDetailPage extends ConsumerStatefulWidget {
  final String orderId;
  const OrderDetailPage({super.key, required this.orderId});

  @override
  ConsumerState<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends ConsumerState<OrderDetailPage> {
  Order? _order;
  OrderType? _type;
  List<TeamMember> _members = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  static const _url = 'http://123.207.255.76:8000';
  static const _anonKey =
      'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIn0.tiSYBtsxALGOt22WxGEVpvzHN3lW6Sgs7AopMpeAfA0';

  Future<void> _loadOrder() async {
    setState(() => _loading = true);
    try {
      // 查询订单
      final orderRes = await http.get(
        Uri.parse('$_url/rest/v1/orders?id=eq.${widget.orderId}&select=*'),
        headers: {'apikey': _anonKey},
      );
      if (orderRes.statusCode == 200) {
        final list = jsonDecode(orderRes.body) as List;
        if (list.isNotEmpty) {
          _order = Order.fromJson(list[0]);

          // 查询订单类型
          if (_order!.typeId != null) {
            final typeRes = await http.get(
              Uri.parse('$_url/rest/v1/order_types?id=eq.${_order!.typeId}&select=*'),
              headers: {'apikey': _anonKey},
            );
            if (typeRes.statusCode == 200) {
              final typeList = jsonDecode(typeRes.body) as List;
              if (typeList.isNotEmpty) {
                _type = OrderType.fromJson(typeList[0]);
              }
            }
          }
        }
      }

      final auth = ref.read(authProvider.notifier);
      _members = await auth.getAllMembers();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _deleteOrder() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定删除订单「${_order!.orderNo}」吗？此操作不可恢复。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('确认删除'),
          ),
        ],
      ),
    );
    if (confirm != true || _order == null) return;
    try {
      await ref.read(ordersProvider.notifier).deleteOrder(_order!.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('订单已删除')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('删除失败：$e')));
      }
    }
  }

  Future<void> _changeStatus(String newStatus) async {
    if (_order == null) return;
    try {
      await ref.read(ordersProvider.notifier).changeStatus(
            orderId: _order!.id,
            fromStatus: _order!.status,
            toStatus: newStatus,
          );
      _loadOrder(); // reload
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('状态已更新为「$newStatus」')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('状态更新失败：$e')),
        );
      }
    }
  }

  String _memberName(String? id) {
    if (id == null) return '未分配';
    return _members.firstWhere((m) => m.id == id, orElse: () => TeamMember(id: '', name: '未知')).name;
  }

  String _extraValue(String key) {
    if (_order == null) return '';
    final v = _order!.extra[key];
    if (v == null) return '';
    return v.toString();
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: '¥', decimalDigits: 0);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('订单详情')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('订单详情')),
        body: const Center(child: Text('订单不存在')),
      );
    }

    final order = _order!;

    return Scaffold(
      appBar: AppBar(
        title: Text(order.orderNo),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              await Navigator.pushNamed(context, '/order-form', arguments: order.id);
              _loadOrder();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: _deleteOrder,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: status + title
            Row(
              children: [
                StatusBadge(status: order.status),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    order.title,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            if (_type != null) ...[
              const SizedBox(height: 4),
              Text(
                '类型：${_type!.name}',
                style: const TextStyle(color: Colors.blueGrey, fontSize: 14),
              ),
            ],
            const SizedBox(height: 20),

            // Info fields
            _infoRow('订单编号', order.orderNo),
            _infoRow('客户名称', order.customerName),
            if (order.customerContact != null && order.customerContact!.isNotEmpty)
              _infoRow('联系方式', order.customerContact!),
            if (order.description != null && order.description!.isNotEmpty)
              _infoRow('描述', order.description!),
            _infoRow('负责人', _memberName(order.primaryOwner)),
            if (order.deadline != null)
              _infoRow('截止日期', ''),
            if (order.deadline != null)
              Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 8),
                child: DeadlineHighlight(deadline: order.deadline!),
              ),
            if (order.price != null)
              _infoRow('价格', fmt.format(order.price)),
            if (order.cost != null)
              _infoRow('成本', fmt.format(order.cost)),

            // Extra fields
            if (_type != null && _type!.fieldsSchema.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              const Text('专属信息', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...(_type!.fieldsSchema.map((f) {
                final v = _extraValue(f.key);
                if (v.isEmpty) return const SizedBox.shrink();
                return _infoRow(f.label, v);
              })),
            ],

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),

            // Status transition buttons
            const Text('状态变更', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: StatusBadge.allStatuses
                  .where((s) => s != order.status)
                  .map((s) {
                return ActionChip(
                  avatar: Icon(Icons.arrow_forward, size: 16, color: StatusBadge.colorForStatus(s)),
                  label: Text(s),
                  backgroundColor: StatusBadge.colorForStatus(s).withAlpha(20),
                  side: BorderSide(color: StatusBadge.colorForStatus(s).withAlpha(80)),
                  onPressed: () => _changeStatus(s),
                );
              }).toList(),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}
