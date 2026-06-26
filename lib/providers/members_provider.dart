import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:order_system/models/team_member.dart';

final membersProvider =
    StateNotifierProvider<MembersNotifier, AsyncValue<List<TeamMember>>>((ref) {
  return MembersNotifier();
});

class MembersNotifier extends StateNotifier<AsyncValue<List<TeamMember>>> {
  MembersNotifier() : super(const AsyncValue.data([])) {
    loadMembers();
  }

  static const _url = 'http://123.207.255.76:8000';
  static const _anonKey =
      'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIn0.tiSYBtsxALGOt22WxGEVpvzHN3lW6Sgs7AopMpeAfA0';

  Future<void> loadMembers() async {
    state = const AsyncValue.loading();
    try {
      final response = await http.get(
        Uri.parse('$_url/rest/v1/team_members?select=*&order=name'),
        headers: {'apikey': _anonKey},
      );
      if (response.statusCode == 200) {
        final list = (jsonDecode(response.body) as List)
            .map((e) => TeamMember.fromJson(e))
            .toList();
        state = AsyncValue.data(list);
      } else {
        state = AsyncValue.data([]);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// 添加团队成员：先创建 auth 用户，再插入 team_members 表
  Future<void> addMember({
    required String email,
    required String name,
    required String password,
  }) async {
    try {
      // 1. 创建 auth 用户
      final signupRes = await http.post(
        Uri.parse('$_url/auth/v1/signup'),
        headers: {
          'Content-Type': 'application/json',
          'apikey': _anonKey,
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (signupRes.statusCode != 200) {
        final err = jsonDecode(signupRes.body);
        throw Exception(err['msg'] ?? '注册失败');
      }

      final signupData = jsonDecode(signupRes.body);
      final userId = signupData['user']['id'] as String;

      // 2. 插入 team_members
      final insertRes = await http.post(
        Uri.parse('$_url/rest/v1/team_members'),
        headers: {
          'apikey': _anonKey,
          'Content-Type': 'application/json',
          'Prefer': 'return=representation',
        },
        body: jsonEncode({
          'id': userId,
          'name': name,
        }),
      );

      if (insertRes.statusCode == 201) {
        await loadMembers();
      } else {
        throw Exception('团队成员添加失败（auth 用户已创建但关联失败）');
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// 移除团队成员（仅删除 team_members 记录，不影响 auth.users）
  Future<void> removeMember(String memberId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_url/rest/v1/team_members?id=eq.$memberId'),
        headers: {'apikey': _anonKey},
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        await loadMembers();
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}
