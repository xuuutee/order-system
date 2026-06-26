import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:order_system/models/team_member.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  return AuthNotifier();
});

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  AuthNotifier() : super(const AsyncValue.data(null)) {
    _init();
  }

  final SupabaseClient _supabase = Supabase.instance.client;

  void _init() {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser != null) {
      state = AsyncValue.data(currentUser);
    }
    _supabase.auth.onAuthStateChange.listen((data) {
      state = AsyncValue.data(data.session?.user);
    });
  }

  User? get currentUser => _supabase.auth.currentUser;

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final res = await _supabase.auth.signInWithPassword(email: email, password: password);
      if (res.user != null) state = AsyncValue.data(res.user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    state = const AsyncValue.data(null);
  }

  /// Check if the currently logged-in user is a team member.
  Future<bool> isTeamMember(String userId) async {
    try {
      // 直接查所有成员，避免 SDK filter 兼容问题
      final res = await _supabase.from('team_members').select('auth_id');
      final list = res as List;
      return list.any((e) => e['auth_id'] == userId);
    } catch (e) {
      debugPrint('isTeamMember error: $e');
      return false;
    }
  }

  /// Fetch all team members (for assignee pickers).
  Future<List<TeamMember>> getAllMembers() async {
    try {
      final res = await _supabase
          .from('team_members')
          .select()
          .order('name');
      return (res as List).map((e) => TeamMember.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  /// 获取当前登录用户的信息
  Future<TeamMember?> getCurrentMember() async {
    try {
      final uid = _supabase.auth.currentUser?.id;
      if (uid == null) return null;
      final all = await getAllMembers();
      for (final m in all) {
        if (m.authId == uid) return m;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// 更新当前用户的名字和电话
  Future<void> updateCurrentMember({
    required String name,
    String? phone,
  }) async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) throw Exception('未登录');
    final body = <String, dynamic>{'name': name};
    if (phone != null) body['phone'] = phone;
    await _supabase
        .from('team_members')
        .update(body)
        .eq('auth_id', uid);
  }

  /// 修改当前登录用户的密码
  Future<void> changePassword(String newPassword) async {
    await _supabase.auth.updateUser(UserAttributes(password: newPassword));
  }
}
