import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

class NotificationService {
  NotificationService._();
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;

  static const _url = 'http://123.207.255.76:8000';
  static const _anonKey =
      'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIn0.tiSYBtsxALGOt22WxGEVpvzHN3lW6Sgs7AopMpeAfA0';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  Timer? _timer;
  bool _initialized = false;
  bool _running = false;

  /// 记录已通知过的最大 created_at，只推送真正的新订单
  String? _lastCreatedAt;

  bool get initialized => _initialized;

  Future<void> init() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    _initialized = true;
    debugPrint('NotificationService initialized');
  }

  /// 开始轮询新订单（每 30 秒），替代 Realtime websocket
  void startListening() {
    if (!_initialized) return;
    if (_running) return;
    _running = true;

    // 先查一次最新订单时间作为基准，避免把现存老订单当新订单推
    _fetchLatestCreatedAt().then((_) {
      if (_running) {
        _timer = Timer.periodic(const Duration(seconds: 30), (_) => _poll());
      }
    });
    debugPrint('NotificationService polling started');
  }

  void stopListening() {
    _running = false;
    _timer?.cancel();
    _timer = null;
    debugPrint('NotificationService polling stopped');
  }

  /// 获取当前最新订单的 created_at 作为基准线
  Future<void> _fetchLatestCreatedAt() async {
    try {
      final response = await http.get(
        Uri.parse(
            '$_url/rest/v1/orders?select=created_at&order=created_at.desc&limit=1'),
        headers: {'apikey': _anonKey},
      );
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        if (list.isNotEmpty) {
          _lastCreatedAt = list[0]['created_at'] as String?;
        }
      }
    } catch (e) {
      debugPrint('_fetchLatestCreatedAt error: $e');
    }
  }

  /// 轮询：查询比 _lastCreatedAt 更新的订单
  Future<void> _poll() async {
    try {
      if (_lastCreatedAt == null) {
        await _fetchLatestCreatedAt();
        return;
      }

      final response = await http.get(
        Uri.parse(
            '$_url/rest/v1/orders?select=order_no,title,customer_name,created_at&created_at=gt.${Uri.encodeComponent(_lastCreatedAt!)}&order=created_at.asc'),
        headers: {'apikey': _anonKey},
      );

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        for (final row in list) {
          final orderNo = row['order_no'] as String? ?? '';
          final title = row['title'] as String? ?? '无标题';
          final customerName = row['customer_name'] as String? ?? '无客户名';
          final createdAt = row['created_at'] as String?;

          _showNotification(orderNo, title, customerName);

          // 推进基准线
          if (createdAt != null) {
            _lastCreatedAt = createdAt;
          }
        }
      }
    } catch (e) {
      debugPrint('NotificationService poll error: $e');
    }
  }

  Future<void> _showNotification(
      String orderNo, String title, String customerName) async {
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000 + orderNo.hashCode,
      '新订单通知',
      '「$title」— $customerName',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'new_orders',
          '新订单',
          channelDescription: '新订单创建通知',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  void _onNotificationTap(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
  }
}
