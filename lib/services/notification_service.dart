import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  RealtimeChannel? _orderChannel;
  bool _initialized = false;

  /// 是否已初始化
  bool get initialized => _initialized;

  /// 初始化本地通知插件
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

  /// 开始监听新订单（Supabase Realtime）
  Future<void> startListening() async {
    if (!_initialized) {
      debugPrint('NotificationService not initialized, cannot start listening');
      return;
    }

    // 确保先取消旧订阅
    await stopListening();

    try {
      _orderChannel = Supabase.instance.client
          .channel('orders-notifications')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'orders',
            callback: _onNewOrder,
          )
          .subscribe((status, _) {
        debugPrint('Realtime subscription status: $status');
      });
      debugPrint('NotificationService started listening for new orders');
    } catch (e) {
      debugPrint('Failed to subscribe: $e');
    }
  }

  /// 停止监听
  Future<void> stopListening() async {
    if (_orderChannel != null) {
      await _orderChannel!.unsubscribe();
      _orderChannel = null;
      debugPrint('NotificationService stopped listening');
    }
  }

  /// Realtime 回调：新订单 INSERT
  void _onNewOrder(PostgresChangePayload payload) {
    final record = payload.newRecord;

    final orderNo = record['order_no'] as String? ?? '';
    final title = record['title'] as String? ?? '无标题';
    final customerName = record['customer_name'] as String? ?? '无客户名';

    _showNotification(orderNo, title, customerName);
  }

  /// 弹出本地通知
  Future<void> _showNotification(
      String orderNo, String title, String customerName) async {
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      '新订单通知',
      '「$title」— $customerName ($orderNo)',
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

  /// 通知点击回调（跳转到订单列表）
  void _onNotificationTap(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    // 目前不做跳转，后续可按需导航到订单详情
  }
}
