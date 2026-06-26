import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:order_system/models/team_member.dart';
import 'package:order_system/providers/auth_provider.dart';
import 'package:order_system/providers/order_types_provider.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  String _appVersion = '';
  String _email = '';
  TeamMember? _member;
  bool _loadingMember = true;

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  Future<void> _loadInfo() async {
    final info = await PackageInfo.fromPlatform();
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('saved_email') ?? '';
    final auth = ref.read(authProvider.notifier);
    final member = await auth.getCurrentMember();
    if (mounted) {
      setState(() {
        _appVersion = 'v${info.version}+${info.buildNumber}';
        _email = email;
        _member = member;
        _loadingMember = false;
      });
    }
  }

  Future<void> _editProfile() async {
    final nameCtrl = TextEditingController(text: _member?.name ?? '');
    final phoneCtrl = TextEditingController(text: _member?.phone ?? '');
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('编辑个人信息'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: '姓名',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return '请输入姓名';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: '电话',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => saving = true);
                      try {
                        await ref.read(authProvider.notifier).updateCurrentMember(
                              name: nameCtrl.text.trim(),
                              phone: phoneCtrl.text.trim().isEmpty
                                  ? null
                                  : phoneCtrl.text.trim(),
                            );
                        if (mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('已保存')),
                          );
                          _loadInfo();
                        }
                      } catch (e) {
                        setDialogState(() => saving = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('保存失败：$e')),
                          );
                        }
                      }
                    },
              child: Text(saving ? '保存中...' : '保存'),
            ),
          ],
        ),
      ),
    );
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
              child: Text(
                (_member?.name ?? '?').isNotEmpty
                    ? (_member?.name ?? '?')[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: _loadingMember
                ? const SizedBox(
                    width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : Column(
                    children: [
                      Text(_member?.name ?? '未设置',
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(_member?.phone ?? '',
                          style: const TextStyle(fontSize: 13, color: Colors.grey)),
                      const SizedBox(height: 2),
                      Text(_email, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                    ],
                  ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _editProfile,
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('编辑信息'),
            ),
          ),
          const SizedBox(height: 24),

          // ── 订单类型 ──
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('订单类型',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  if (typesState.isLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: types
                          .map((t) => Chip(
                                avatar: Icon(_iconForType(t.icon), size: 18),
                                label:
                                    Text(t.name, style: const TextStyle(fontSize: 13)),
                              ))
                          .toList(),
                    ),
                  const SizedBox(height: 8),
                  Text('共 ${types.length} 种类型',
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
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
