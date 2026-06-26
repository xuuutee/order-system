import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
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
  static const _url = 'http://123.207.255.76:8000';
  static const _anonKey =
      'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIn0.tiSYBtsxALGOt22WxGEVpvzHN3lW6Sgs7AopMpeAfA0';
  static const _prefsKey = 'saved_refresh_token';
  static const _emailKey = 'saved_email';

  String? _accessToken;
  String? _refreshToken;
  String? _userId;
  User? _cachedUser;

  void _init() {
    _cachedUser = _supabase.auth.currentUser;
    if (_cachedUser != null) {
      state = AsyncValue.data(_cachedUser);
    }
    _supabase.auth.onAuthStateChange.listen((data) {
      _cachedUser = data.session?.user;
      state = AsyncValue.data(_cachedUser);
    });
  }

  User? get currentUser => _cachedUser ?? _supabase.auth.currentUser;
  String? get accessToken => _accessToken;
  String? get currentUserId => _userId;
  String? get savedEmail => null; // set after successful login

  /// 自动登录：用保存的 refresh token 换新 token
  Future<bool> tryAutoLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString(_prefsKey);
      if (savedToken == null || savedToken.isEmpty) return false;

      final response = await http.post(
        Uri.parse('$_url/auth/v1/token?grant_type=refresh_token'),
        headers: {
          'Content-Type': 'application/json',
          'apikey': _anonKey,
        },
        body: jsonEncode({'refresh_token': savedToken}),
      );

      if (response.statusCode != 200) {
        await prefs.remove(_prefsKey);
        return false;
      }

      final data = jsonDecode(response.body);
      _accessToken = data['access_token'] as String;
      _refreshToken = data['refresh_token'] as String;
      _userId = data['user']['id'] as String;

      // 同步 Supabase SDK auth session，Realtime 订阅需要 JWT
      try {
        await _supabase.auth.setSession(_accessToken!);
      } catch (_) {
        // setSession 失败不阻断登录（自托管 Supabase 兼容性）
        debugPrint('setSession failed, continuing without SDK auth sync');
      }

      // 保存新的 refresh token（旧的已失效）
      await prefs.setString(_prefsKey, _refreshToken!);

      // 验证团队成员身份
      final isMember = await isTeamMember(_userId!);
      if (!isMember) {
        await prefs.remove(_prefsKey);
        return false;
      }

      state = AsyncValue.data(_cachedUser ?? _supabase.auth.currentUser);
      return true;
    } catch (e) {
      debugPrint('autoLogin error: $e');
      return false;
    }
  }

  /// 邮箱密码登录
  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final response = await http.post(
        Uri.parse('$_url/auth/v1/token?grant_type=password'),
        headers: {
          'Content-Type': 'application/json',
          'apikey': _anonKey,
        },
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode != 200) {
        throw Exception('账号或密码错误');
      }

      final data = jsonDecode(response.body);
      _accessToken = data['access_token'] as String;
      _refreshToken = data['refresh_token'] as String;
      _userId = data['user']['id'] as String;

      // 同步 Supabase SDK auth session，Realtime 订阅需要 JWT
      try {
        await _supabase.auth.setSession(_accessToken!);
      } catch (_) {
        // setSession 失败不阻断登录（自托管 Supabase 兼容性）
        debugPrint('setSession failed, continuing without SDK auth sync');
      }

      // 保存 refresh token 到本地
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, _refreshToken!);
      await prefs.setString(_emailKey, email);

      state = AsyncValue.data(_cachedUser ?? _supabase.auth.currentUser);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// 退出登录（清除保存的 token）
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    _accessToken = null;
    _refreshToken = null;
    _userId = null;
    state = const AsyncValue.data(null);
  }

  Future<bool> isTeamMember(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_url/rest/v1/team_members?auth_id=eq.$userId&select=id'),
        headers: {'apikey': _anonKey},
      );
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        return list.isNotEmpty;
      }
      return false;
    } catch (e) {
      debugPrint('isTeamMember error: $e');
      return false;
    }
  }

  Future<List<TeamMember>> getAllMembers() async {
    try {
      final response = await http.get(
        Uri.parse('$_url/rest/v1/team_members?select=*&order=name'),
        headers: {'apikey': _anonKey},
      );
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        return list.map((e) => TeamMember.fromJson(e)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}
