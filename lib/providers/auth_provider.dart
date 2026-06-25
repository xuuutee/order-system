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
      await _supabase.auth.signInWithPassword(email: email, password: password);
      // state is updated by onAuthStateChange listener
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
      final res = await _supabase
          .from('team_members')
          .select('id')
          .eq('auth_id', userId)
          .maybeSingle();
      return res != null;
    } catch (_) {
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
}
