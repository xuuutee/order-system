import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;

  static const _url = 'http://123.207.255.76:8000';
  static const _updateHost = 'http://123.207.255.76:9000';
  static const _anonKey =
      'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIn0.tiSYBtsxALGOt22WxGEVpvzHN3lW6Sgs7AopMpeAfA0';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  Timer? _timer;
  bool _initialized = false;
  bool _running = false;

  String? _lastCreatedAt;
  String _currentVersion = '';
  /// 上次已通知过的服务器版本号，避免重复弹
  String? _lastNotifiedVersion;

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

    // 读取当前 App 版本
    try {
      final info = await PackageInfo.fromPlatform();
      _currentVersion = info.version;
    } catch (_) {
      _currentVersion = '0.0.0';
    }

    _initialized = true;
    debugPrint('NotificationService initialized, version=$_currentVersion');
  }

  /// 开始轮询（每 30 秒）：新订单 + 新版本
  void startListening() {
    if (!_initialized) return;
    if (_running) return;
    _running = true;

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

  /// 轮询：新订单 + 新版本
  Future<void> _poll() async {
    await Future.wait([_checkNewOrders(), _checkNewVersion()]);
  }

  /// 查询比 _lastCreatedAt 更新的订单
  Future<void> _checkNewOrders() async {
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

          _showOrderNotification(orderNo, title, customerName);

          if (createdAt != null) {
            _lastCreatedAt = createdAt;
          }
        }
      }
    } catch (e) {
      debugPrint('_checkNewOrders error: $e');
    }
  }

  /// 检查服务器是否有新版本
  Future<void> _checkNewVersion() async {
    try {
      final response = await http.get(
        Uri.parse('$_updateHost/update/version.json'),
        headers: {'apikey': _anonKey},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        var latest = data['version'] as String? ?? '';
        // 去掉 v 前缀
        if (latest.startsWith('v')) latest = latest.substring(1);

        // 服务器版本 > 当前版本 且 未通知过
        if (latest.isNotEmpty &&
            latest != _currentVersion &&
            latest != _lastNotifiedVersion) {
          _lastNotifiedVersion = latest;
          _showUpdateNotification(latest);
        }
      }
    } catch (e) {
      debugPrint('_checkNewVersion error: $e');
    }
  }

  Future<void> _showOrderNotification(
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

  Future<void> _showUpdateNotification(String latestVersion) async {
    await _plugin.show(
      0, // 固定 ID，更新通知只保留一条
      '发现新版本 v$latestVersion',
      '点击下载更新',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'app_update',
          '版本更新',
          channelDescription: '应用版本更新通知',
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
