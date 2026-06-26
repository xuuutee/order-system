import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:order_system/pages/orders/order_list_page.dart';
import 'package:order_system/pages/orders/order_form_page.dart';
import 'package:order_system/pages/stats/stats_page.dart';
import 'package:order_system/pages/settings/profile_page.dart';
import 'package:order_system/services/version_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  RealtimeChannel? _orderChannel;

  final _pages = const <Widget>[
    OrderListPage(),
    OrderFormPage(),
    StatsPage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _checkUpdate();
    _listenNewOrders();
  }

  @override
  void dispose() {
    _orderChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _checkUpdate() async {
    final info = await VersionService.check();
    if (!mounted) return;
    if (info.hasUpdate && info.downloadUrl.isNotEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('发现新版本'),
          content: Text('当前版本：${info.currentVersion}\n最新版本：${info.latestVersion}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('稍后'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                launchUrl(Uri.parse(info.downloadUrl));
              },
              child: const Text('立即下载'),
            ),
          ],
        ),
      );
    }
  }

  void _listenNewOrders() {
    try {
      _orderChannel = Supabase.instance.client
          .channel('new-orders')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'orders',
            callback: (payload) {
              final row = payload.newRecord;
              if (row == null || !mounted) return;
              final title = row['title'] as String? ?? '新订单';
              final customer = row['customer_name'] as String? ?? '';
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('新订单：「$title」— $customer'),
                  duration: const Duration(seconds: 4),
                  action: SnackBarAction(
                    label: '查看',
                    onPressed: () => setState(() => _currentIndex = 0),
                  ),
                ),
              );
            },
          )
          .subscribe();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.list_alt),
            selectedIcon: Icon(Icons.list_alt, color: Colors.blue),
            label: '订单列表',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline, size: 28),
            selectedIcon: Icon(Icons.add_circle, color: Colors.blue, size: 28),
            label: '新建订单',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart),
            selectedIcon: Icon(Icons.bar_chart, color: Colors.blue),
            label: '统计总览',
          ),
          NavigationDestination(
            icon: Icon(Icons.person),
            selectedIcon: Icon(Icons.person, color: Colors.blue),
            label: '我的',
          ),
        ],
      ),
    );
  }
}
