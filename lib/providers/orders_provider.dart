import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:order_system/models/order.dart';

final ordersProvider = StateNotifierProvider<OrdersNotifier, AsyncValue<List<Order>>>((ref) {
  return OrdersNotifier();
});

/// Filter state for the order list.
class OrderFilters {
  final String? status;
  final String? typeId;
  final String? ownerId;

  const OrderFilters({this.status, this.typeId, this.ownerId});

  bool get hasActive => status != null || typeId != null || ownerId != null;
}

class OrdersNotifier extends StateNotifier<AsyncValue<List<Order>>> {
  OrdersNotifier() : super(const AsyncValue.data([]));

  final SupabaseClient _supabase = Supabase.instance.client;

  OrderFilters _filters = const OrderFilters();
  OrderFilters get filters => _filters;

  int _page = 0;
  static const int _pageSize = 20;
  bool _hasMore = true;
  bool get hasMore => _hasMore;

  bool _loading = false; // prevent concurrent fetches

  /// Load / reload orders with current filters.
  Future<void> loadOrders({bool refresh = false}) async {
    if (_loading) return;
    if (refresh) {
      _page = 0;
      _hasMore = true;
    }

    _loading = true;
    try {
      var filterQuery = _supabase.from('orders').select();

      if (_filters.status != null) {
        filterQuery = filterQuery.eq('status', _filters.status!);
      }
      if (_filters.typeId != null) {
        filterQuery = filterQuery.eq('type_id', _filters.typeId!);
      }
      if (_filters.ownerId != null) {
        filterQuery = filterQuery.eq('primary_owner', _filters.ownerId!);
      }

      final res = await filterQuery
          .order('created_at', ascending: false)
          .range(_page * _pageSize, (_page + 1) * _pageSize - 1);
      final list = (res as List).map((e) => Order.fromJson(e)).toList();

      if (refresh) {
        state = AsyncValue.data(list);
      } else {
        final current = state.valueOrNull ?? [];
        state = AsyncValue.data([...current, ...list]);
      }

      _hasMore = list.length >= _pageSize;
      if (list.isNotEmpty) _page++;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    } finally {
      _loading = false;
    }
  }

  /// Apply new filters and reload.
  Future<void> applyFilters(OrderFilters filters) async {
    _filters = filters;
    await loadOrders(refresh: true);
  }

  /// Load next page (infinite scroll).
  Future<void> loadMore() async {
    if (!_hasMore || _loading) return;
    await loadOrders();
  }

  /// Create a new order.
  Future<void> createOrder(Map<String, dynamic> data) async {
    final user = _supabase.auth.currentUser;
    final payload = {
      ...data,
      'created_by': user?.id,
    };
    await _supabase.from('orders').insert(payload);
    await loadOrders(refresh: true);
  }

  /// Update an existing order.
  Future<void> updateOrder(String orderId, Map<String, dynamic> data) async {
    await _supabase.from('orders').update(data).eq('id', orderId);
    await loadOrders(refresh: true);
  }

  /// Change order status and log the transition.
  Future<void> changeStatus({
    required String orderId,
    required String fromStatus,
    required String toStatus,
    String? note,
  }) async {
    final user = _supabase.auth.currentUser;
    // Update order status.
    await _supabase
        .from('orders')
        .update({'status': toStatus, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', orderId);
    // Write status log.
    await _supabase.from('order_status_logs').insert({
      'order_id': orderId,
      'from_status': fromStatus,
      'to_status': toStatus,
      'changed_by': user?.id,
      'note': note,
    });
    await loadOrders(refresh: true);
  }

  /// Delete an order.
  Future<void> deleteOrder(String orderId) async {
    await _supabase.from('orders').delete().eq('id', orderId);
    await loadOrders(refresh: true);
  }
}
