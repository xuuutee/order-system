import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:order_system/models/order_type.dart';

final orderTypesProvider = StateNotifierProvider<OrderTypesNotifier, AsyncValue<List<OrderType>>>((ref) {
  return OrderTypesNotifier();
});

class OrderTypesNotifier extends StateNotifier<AsyncValue<List<OrderType>>> {
  OrderTypesNotifier() : super(const AsyncValue.loading()) {
    fetchTypes();
  }

  static const _url = 'http://123.207.255.76:8000';
  static const _anonKey =
      'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIn0.tiSYBtsxALGOt22WxGEVpvzHN3lW6Sgs7AopMpeAfA0';

  Future<void> fetchTypes() async {
    state = const AsyncValue.loading();
    try {
      final response = await http.get(
        Uri.parse('$_url/rest/v1/order_types?is_active=eq.true&order=created_at'),
        headers: {'apikey': _anonKey},
      );
      if (response.statusCode == 200) {
        final list = (jsonDecode(response.body) as List)
            .map((e) => OrderType.fromJson(e))
            .toList();
        state = AsyncValue.data(list);
      } else {
        state = AsyncValue.data([]);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    try {
      final response = await http.get(
        Uri.parse('$_url/rest/v1/order_types?is_active=eq.true&order=created_at'),
        headers: {'apikey': _anonKey},
      );
      if (response.statusCode == 200) {
        final list = (jsonDecode(response.body) as List)
            .map((e) => OrderType.fromJson(e))
            .toList();
        state = AsyncValue.data(list);
      }
    } catch (_) {}
  }
}
