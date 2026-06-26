import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:jpush_flutter/jpush_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 全局 NavigatorKey，用于通知点击跳转
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class JPushService {
  JPushService._();
  static final JPushService _instance = JPushService._();
  factory JPushService() => _instance;

  final _jpush = JPush.newJPush();
  final _supabase = Supabase.instance.client;

  bool _initialized = false;
  String? _registrationId;

  bool get initialized => _initialized;
  String? get registrationId => _registrationId;

  /// 用真实 AppKey 替换此占位符
  static const String appKey = 'JPUSH_APP_KEY_PLACEHOLDER';

  Future<void> init() async {
    if (_initialized) return;

    try {
      _jpush.setup(appKey: appKey, channel: 'developer-default', debug: kDebugMode);

      // 获取 registration ID
      _jpush.getRegistrationID().then((rid) {
        _registrationId = rid;
        debugPrint('JPush registration ID: $rid');
        syncToken();
      });

      // 监听通知事件
      _jpush.addEventHandler(
        onReceiveNotification: (Map<String, dynamic> message) async {
          debugPrint('JPush onReceiveNotification: $message');
        },
        onOpenNotification: (Map<String, dynamic> message) async {
          debugPrint('JPush onOpenNotification: $message');
          _handleNotificationTap(message);
        },
      );

      _initialized = true;
      debugPrint('JPush initialized');
    } catch (e) {
      debugPrint('JPush init error: $e');
    }
  }

  /// 登录后关联设备
  Future<void> registerDevice(String memberId) async {
    if (_registrationId == null) return;
    try {
      await _supabase.from('member_push_tokens').upsert({
        'member_id': memberId,
        'registration_id': _registrationId,
        'platform': 'android',
      });
      debugPrint('JPush device registered: $memberId → $_registrationId');
    } catch (e) {
      debugPrint('JPush registerDevice error: $e');
    }
  }

  /// 退出登录后解除关联
  Future<void> unregisterDevice() async {
    if (_registrationId == null) return;
    try {
      await _supabase
          .from('member_push_tokens')
          .delete()
          .eq('registration_id', _registrationId!);
      debugPrint('JPush device unregistered: $_registrationId');
    } catch (e) {
      debugPrint('JPush unregisterDevice error: $e');
    }
  }

  /// 同步 token：登录后重新绑定
  Future<void> syncToken() async {
    final user = _supabase.auth.currentUser;
    if (user == null || _registrationId == null) return;
    try {
      final res = await _supabase
          .from('team_members')
          .select('id')
          .eq('auth_id', user.id)
          .maybeSingle();
      if (res != null) {
        await registerDevice(res['id'] as String);
      }
    } catch (_) {}
  }

  /// 点击通知 → 打开订单详情
  void _handleNotificationTap(Map<String, dynamic> message) {
    final extras = message['extras'] as Map<String, dynamic>?;
    final orderId = extras?['order_id'] as String?;
    debugPrint('JPush notification tap, orderId: $orderId');
    if (orderId != null && navigatorKey.currentContext != null) {
      Navigator.of(navigatorKey.currentContext!)
          .pushNamed('/order-detail', arguments: orderId);
    }
  }

  /// 获取当前 registration ID
  Future<String?> getRegistrationId() async {
    try {
      _registrationId = await _jpush.getRegistrationID();
      return _registrationId;
    } catch (_) {
      return null;
    }
  }
}
