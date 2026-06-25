import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:order_system/models/order_type.dart';

final orderTypesProvider = StateNotifierProvider<OrderTypesNotifier, AsyncValue<List<OrderType>>>((ref) {
  return OrderTypesNotifier();
});

class OrderTypesNotifier extends StateNotifier<AsyncValue<List<OrderType>>> {
  OrderTypesNotifier() : super(const AsyncValue.loading()) {
    fetchTypes();
  }

  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> fetchTypes() async {
    state = const AsyncValue.loading();
    try {
      final res = await _supabase
          .from('order_types')
          .select()
          .eq('is_active', true)
          .order('created_at');
      final list = (res as List)
          .map((e) => OrderType.fromJson(e))
          .toList();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Refresh types in background (no loading state change).
  Future<void> refresh() async {
    try {
      final res = await _supabase
          .from('order_types')
          .select()
          .eq('is_active', true)
          .order('created_at');
      final list = (res as List)
          .map((e) => OrderType.fromJson(e))
          .toList();
      state = AsyncValue.data(list);
    } catch (_) {
      // keep current data on refresh failure
    }
  }
}
