import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:order_system/providers/members_provider.dart';

class MemberManagementPage extends ConsumerStatefulWidget {
  const MemberManagementPage({super.key});
  @override
  ConsumerState<MemberManagementPage> createState() => _MemberManagementPageState();
}

class _MemberManagementPageState extends ConsumerState<MemberManagementPage> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(membersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('负责人管理')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('加载失败：$e'), const SizedBox(height: 12),
          FilledButton(onPressed: () => ref.read(membersProvider.notifier).loadMembers(), child: const Text('重试')),
        ])),
        data: (members) {
          return Column(children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
              child: Row(children: [
                Text('共 ${members.length} 人', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey)),
                const Spacer(),
                Text('仅工作室可登录', style: TextStyle(fontSize: 12, color: Colors.orange.shade700)),
                const SizedBox(width: 16),
              ]),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: members.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final m = members[i];
                  final canLogin = m.authId != null;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: canLogin ? Colors.green.shade100 : Colors.grey.shade200,
                      child: Icon(canLogin ? Icons.person : Icons.person_outline, color: canLogin ? Colors.green : Colors.grey),
                    ),
                    title: Text(m.name, style: const TextStyle(fontSize: 15)),
                    subtitle: Text(canLogin ? '可登录' : '仅负责人', style: const TextStyle(fontSize: 12)),
                    trailing: PopupMenuButton<String>(
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'rename', child: ListTile(leading: Icon(Icons.edit), title: Text('改名'), dense: true)),
                        if (!canLogin)
                          const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete, color: Colors.red), title: Text('删除', style: TextStyle(color: Colors.red)), dense: true)),
                      ],
                      onSelected: (v) {
                        if (v == 'rename') _showRename(m.id, m.name);
                        if (v == 'delete') _confirmDelete(m.id, m.name);
                      },
                    ),
                  );
                },
              ),
            ),
          ]);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAdd,
        icon: const Icon(Icons.person_add),
        label: const Text('添加负责人'),
      ),
    );
  }

  void _showAdd() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加负责人'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: '姓名', border: OutlineInputBorder()), autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(onPressed: () async {
            final name = ctrl.text.trim();
            if (name.isEmpty) return;
            await ref.read(membersProvider.notifier).addMember(name);
            if (ctx.mounted) Navigator.pop(ctx);
          }, child: const Text('添加')),
        ],
      ),
    );
  }

  void _showRename(String id, String currentName) {
    final ctrl = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('修改姓名'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: '姓名', border: OutlineInputBorder()), autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(onPressed: () async {
            final name = ctrl.text.trim();
            if (name.isEmpty) return;
            await ref.read(membersProvider.notifier).renameMember(id, name);
            if (ctx.mounted) Navigator.pop(ctx);
          }, child: const Text('确定')),
        ],
      ),
    );
  }

  void _confirmDelete(String id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除负责人'),
        content: Text('确定删除「$name」吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async { await ref.read(membersProvider.notifier).removeMember(id); if (ctx.mounted) Navigator.pop(ctx); },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}
