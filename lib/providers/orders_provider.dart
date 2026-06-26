import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:order_system/models/order.dart';

final ordersProvider = StateNotifierProvider<OrdersNotifier, AsyncValue<List<Order>>>((ref) {
  return OrdersNotifier();
});

class OrderFilters {
  final String? status;
  final String? typeId;
  final String? ownerId;
  const OrderFilters({this.status, this.typeId, this.ownerId});
}

class OrdersNotifier extends StateNotifier<AsyncValue<List<Order>>> {
  OrdersNotifier() : super(const AsyncValue.data([]));

  static const _url = 'http://123.207.255.76:8000';
  static const _anonKey =
      'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIn0.tiSYBtsxALGOt22WxGEVpvzHN3lW6Sgs7AopMpeAfA0';

  OrderFilters _filters = const OrderFilters();
  OrderFilters get filters => _filters;

  int _page = 0;
  static const _pageSize = 20;
  bool _hasMore = true;
  bool get hasMore => _hasMore;
  bool _loading = false;

  Future<void> loadOrders({bool refresh = false}) async {
    if (_loading) return;
    if (refresh) {
      _page = 0;
      _hasMore = true;
    }
    _loading = true;
    try {
      // 构造查询参数
      final params = <String, String>{
        'select': '*',
        'order': 'created_at.desc',
        'limit': '$_pageSize',
        'offset': '${_page * _pageSize}',
      };
      if (_filters.status != null) params['status'] = 'eq.${_filters.status}';
      if (_filters.typeId != null) params['type_id'] = 'eq.${_filters.typeId}';
      if (_filters.ownerId != null) params['primary_owner'] = 'eq.${_filters.ownerId}';

      final uri = Uri.parse('$_url/rest/v1/orders').replace(queryParameters: params);
      final response = await http.get(uri, headers: {'apikey': _anonKey});

      if (response.statusCode == 200) {
        final list = (jsonDecode(response.body) as List)
            .map((e) => Order.fromJson(e))
            .toList();
        if (refresh) {
          state = AsyncValue.data(list);
        } else {
          state = AsyncValue.data([...state.valueOrNull ?? [], ...list]);
        }
        _hasMore = list.length >= _pageSize;
        if (list.isNotEmpty) _page++;
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    } finally {
      _loading = false;
    }
  }

  Future<void> applyFilters(OrderFilters filters) async {
    _filters = filters;
    await loadOrders(refresh: true);
  }

  Future<void> loadMore() async {
    if (!_hasMore || _loading) return;
    await loadOrders();
  }

  Future<void> createOrder(Map<String, dynamic> data) async {
    try {
      await http.post(
        Uri.parse('$_url/rest/v1/orders'),
        headers: {
          'apikey': _anonKey,
          'Content-Type': 'application/json',
          'Prefer': 'return=representation',
        },
        body: jsonEncode(data),
      );
      await loadOrders(refresh: true);
    } catch (_) {}
  }

  Future<void> updateOrder(String orderId, Map<String, dynamic> data) async {
    try {
      await http.patch(
        Uri.parse('$_url/rest/v1/orders?id=eq.$orderId'),
        headers: {
          'apikey': _anonKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      );
      await loadOrders(refresh: true);
    } catch (_) {}
  }

  Future<void> changeStatus({
    required String orderId,
    required String fromStatus,
    required String toStatus,
    String? note,
  }) async {
    try {
      // 更新订单状态
      await http.patch(
        Uri.parse('$_url/rest/v1/orders?id=eq.$orderId'),
        headers: {
          'apikey': _anonKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'status': toStatus,
          'updated_at': DateTime.now().toIso8601String(),
        }),
      );
      // 写状态日志
      await http.post(
        Uri.parse('$_url/rest/v1/order_status_logs'),
        headers: {
          'apikey': _anonKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'order_id': orderId,
          'from_status': fromStatus,
          'to_status': toStatus,
          'note': note,
        }),
      );
      await loadOrders(refresh: true);
    } catch (_) {}
  }

  Future<void> deleteOrder(String orderId) async {
    try {
      await http.delete(
        Uri.parse('$_url/rest/v1/orders?id=eq.$orderId'),
        headers: {'apikey': _anonKey},
      );
      await loadOrders(refresh: true);
    } catch (_) {}
  }
}
