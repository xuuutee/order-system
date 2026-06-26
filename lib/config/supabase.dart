import 'package:supabase_flutter/supabase_flutter.dart';

class AppConfig {
  AppConfig._();

  /// 服务器地址
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'http://123.207.255.76:8000',
  );

  /// 匿名访问密钥
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIn0.tiSYBtsxALGOt22WxGEVpvzHN3lW6Sgs7AopMpeAfA0',
  );

  /// 初始化 Supabase（自托管版本）
  static Future<void> initSupabase() async {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseAnonKey,
    );
  }
}
