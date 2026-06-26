import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:order_system/models/team_member.dart';
import 'package:order_system/providers/auth_provider.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  String _appVersion = '';
  TeamMember? _member;
  List<Map<String, dynamic>> _types = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  Future<void> _loadInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final auth = ref.read(authProvider.notifier);
      final member = await auth.getCurrentMember();
      List<Map<String, dynamic>> types = [];
      try {
        final res = await Supabase.instance.client
            .from('order_types')
            .select()
            .eq('is_active', true)
            .order('created_at');
        types = List<Map<String, dynamic>>.from(res as List);
      } catch (_) {}
      if (mounted) {
        setState(() {
          _appVersion = 'v${info.version}+${info.buildNumber}';
          _member = member;
          _types = types;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _editProfile() async {
    final nameCtrl = TextEditingController(text: _member?.name ?? '');
    final phoneCtrl = TextEditingController(text: _member?.phone ?? '');
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    final ok = await showDialog<bool>(
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
              onPressed: () => Navigator.pop(ctx, false),
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
                        Navigator.pop(ctx, true);
                      } catch (e) {
                        setDialogState(() => saving = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
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

    if (ok == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已保存')),
      );
      _loadInfo();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                (_member?.name ?? '?').isNotEmpty
                    ? (_member?.name ?? '?')[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: _loading
                ? const CircularProgressIndicator()
                : Column(
                    children: [
                      Text(_member?.name ?? '未设置',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      if (_member?.phone != null && _member!.phone!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(_member!.phone!,
                              style: const TextStyle(fontSize: 14, color: Colors.grey)),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 12),
          Center(
            child: OutlinedButton.icon(
              onPressed: _editProfile,
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('编辑信息'),
            ),
          ),
          const SizedBox(height: 24),

          // ── 账号信息 ──
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('账号信息', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                _InfoRow(label: '账号', value: Supabase.instance.client.auth.currentUser?.email ?? '--'),
                const SizedBox(height: 4),
                _InfoRow(label: '密码', value: '••••••••'),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    onPressed: _changePassword,
                    icon: const Icon(Icons.lock_outline, size: 16),
                    label: const Text('修改密码', style: TextStyle(fontSize: 13)),
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 12),

          // ── 负责人管理 ──
          Card(
            child: ListTile(
              leading: const Icon(Icons.group),
              title: const Text('负责人管理'),
              subtitle: const Text('添加 / 删除 / 改名'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pushNamed(context, '/member-management'),
            ),
          ),
          const SizedBox(height: 12),

          // ── 订单类型 ──
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('订单类型', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6, runSpacing: 6,
                  children: _types.map((t) => Chip(
                    avatar: Icon(_iconForType(t['icon'] as String?), size: 18),
                    label: Text(t['name'] as String? ?? '', style: const TextStyle(fontSize: 13)),
                  )).toList(),
                ),
                const SizedBox(height: 4),
                Text('共 ${_types.length} 种类型', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ]),
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

          // ── 服务器 ──
          Card(
            child: const ListTile(
              leading: Icon(Icons.cloud_outlined),
              title: Text('服务器'),
              subtitle: Text('123.207.255.76'),
            ),
          ),
          const SizedBox(height: 24),
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
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _changePassword() async {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool saving = false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('修改密码'),
          content: Form(key: formKey, child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(controller: oldCtrl, obscureText: true, decoration: const InputDecoration(labelText: '旧密码', border: OutlineInputBorder()), validator: (v) => v == null || v.isEmpty ? '请输入旧密码' : null),
            const SizedBox(height: 12),
            TextFormField(controller: newCtrl, obscureText: true, decoration: const InputDecoration(labelText: '新密码', border: OutlineInputBorder()), validator: (v) => v == null || v.length < 6 ? '至少6位' : null),
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
            FilledButton(onPressed: saving ? null : () async {
              if (!formKey.currentState!.validate()) return;
              setDialogState(() => saving = true);
              try {
                // 先验证旧密码
                final email = Supabase.instance.client.auth.currentUser?.email ?? '';
                await ref.read(authProvider.notifier).signIn(email, oldCtrl.text);
                await ref.read(authProvider.notifier).changePassword(newCtrl.text);
                Navigator.pop(ctx, true);
              } catch (e) {
                setDialogState(() => saving = false);
                if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('修改失败：${e.toString().contains("Invalid") ? "旧密码错误" : e}')));
              }
            }, child: Text(saving ? '修改中...' : '确认修改')),
          ],
        ),
      ),
    );
    if (ok == true && mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('密码已修改')));
  }

  IconData _iconForType(String? icon) {
    switch (icon) {
      case 'school': return Icons.school;
      case 'slideshow': return Icons.slideshow;
      case 'edit_note': return Icons.edit_note;
      case 'assignment': return Icons.assignment;
      case 'description': return Icons.description;
      default: return Icons.receipt_long;
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text('$label：', style: const TextStyle(fontSize: 14, color: Colors.grey)),
      Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
    ]);
  }
}
