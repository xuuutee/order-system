import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:order_system/models/team_member.dart';

final membersProvider = StateNotifierProvider<MembersNotifier, AsyncValue<List<TeamMember>>>((ref) {
  return MembersNotifier();
});

class MembersNotifier extends StateNotifier<AsyncValue<List<TeamMember>>> {
  MembersNotifier() : super(const AsyncValue.data([])) { loadMembers(); }

  final _supabase = Supabase.instance.client;

  Future<void> loadMembers() async {
    state = const AsyncValue.loading();
    try {
      final res = await _supabase.from('team_members').select().order('name');
      final list = (res as List).map((e) => TeamMember.fromJson(e)).toList();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addMember(String name) async {
    await _supabase.from('team_members').insert({'name': name});
    await loadMembers();
  }

  Future<void> renameMember(String id, String newName) async {
    await _supabase.from('team_members').update({'name': newName}).eq('id', id);
    await loadMembers();
  }

  Future<void> removeMember(String id) async {
    await _supabase.from('team_members').delete().eq('id', id);
    await loadMembers();
  }
}
