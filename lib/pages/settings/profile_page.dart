import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:order_system/providers/auth_provider.dart';
import 'package:order_system/providers/order_types_provider.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _appVersion = 'v${info.version}+${info.buildNumber}');
  }

  @override
  Widget build(BuildContext context) {
    final typesState = ref.watch(orderTypesProvider);
    final types = typesState.valueOrNull ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── 账号信息 ──
          Center(
            child: CircleAvatar(
              radius: 36,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(Icons.person, size: 36, color: Theme.of(context).colorScheme.primary),
            ),
          ),
          const SizedBox(height: 8),
          const Center(child: Text('admin@studio.com', style: TextStyle(fontSize: 15))),
          const SizedBox(height: 24),

          // ── 订单类型 ──
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('订单类型', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  if (typesState.isLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: types.map((t) => Chip(
                        avatar: Icon(_iconForType(t.icon), size: 18),
                        label: Text(t.name, style: const TextStyle(fontSize: 13)),
                      )).toList(),
                    ),
                  const SizedBox(height: 8),
                  Text('共 ${types.length} 种类型', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── 团队成员管理 ──
          Card(
            child: ListTile(
              leading: const Icon(Icons.group),
              title: const Text('团队成员管理'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pushNamed(context, '/member-management'),
            ),
          ),
          const SizedBox(height: 12),

          // ── 版本 ──
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('版本'),
              subtitle: Text(_appVersion.isEmpty ? '...' : _appVersion),
            ),
          ),
          const SizedBox(height: 12),

          // ── 退出 ──
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await ref.read(authProvider.notifier).signOut();
                if (context.mounted) Navigator.pushReplacementNamed(context, '/');
              },
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('退出登录', style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForType(String? icon) {
    switch (icon) {
      case 'school': return Icons.school;
      case 'slideshow': return Icons.slideshow;
      case 'edit_note': return Icons.edit_note;
      case 'assignment': return Icons.assignment;
      case 'dashboard': return Icons.dashboard;
      case 'description': return Icons.description;
      case 'checklist': return Icons.checklist;
      case 'stamp': return Icons.fingerprint;
      default: return Icons.receipt_long;
    }
  }
}
