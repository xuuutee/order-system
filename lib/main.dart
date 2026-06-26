import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:order_system/config/supabase.dart';
import 'package:order_system/services/jpush_service.dart';
import 'package:order_system/pages/login_page.dart';
import 'package:order_system/pages/home_page.dart';
import 'package:order_system/pages/orders/order_detail_page.dart';
import 'package:order_system/pages/orders/order_form_page.dart';
import 'package:order_system/pages/settings/member_management_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.initSupabase();
  await JPushService().init();
  runApp(const ProviderScope(child: OrderSystemApp()));
}

class OrderSystemApp extends StatelessWidget {
  const OrderSystemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '订单管理',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: true),
      ),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (_) => const LoginPage());
          case '/home':
            return MaterialPageRoute(builder: (_) => const HomePage());
          case '/order-detail':
            final orderId = settings.arguments as String? ?? '';
            return MaterialPageRoute(builder: (_) => OrderDetailPage(orderId: orderId));
          case '/order-form':
            final editOrderId = settings.arguments as String?;
            return MaterialPageRoute(builder: (_) => OrderFormPage(editOrderId: editOrderId));
          case '/member-management':
            return MaterialPageRoute(builder: (_) => const MemberManagementPage());
          default:
            return MaterialPageRoute(builder: (_) => const LoginPage());
        }
      },
    );
  }
}
