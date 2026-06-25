import 'package:flutter/material.dart';

import 'package:order_system/pages/orders/order_list_page.dart';
import 'package:order_system/pages/orders/order_form_page.dart';
import 'package:order_system/pages/stats/stats_page.dart';
import 'package:order_system/pages/settings/profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final _pages = const <Widget>[
    OrderListPage(),
    OrderFormPage(),
    StatsPage(),
    ProfilePage(),
  ];

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
