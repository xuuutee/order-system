import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:order_system/providers/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tryAutoLogin();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _tryAutoLogin() async {
    final auth = ref.read(authProvider.notifier);
    final user = auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final isMember = await auth.isTeamMember(user.id);
    if (!mounted) return;
    if (isMember) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      await auth.signOut();
      setState(() => _loading = false);
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    try {
      final auth = ref.read(authProvider.notifier);
      await auth.signIn(_emailCtrl.text.trim(), _passwordCtrl.text);

      final user = auth.currentUser;
      if (user == null) {
        setState(() => _error = '登录失败，请重试');
        return;
      }

      final isMember = await auth.isTeamMember(user.id);
      if (!mounted) return;
      if (!isMember) {
        await auth.signOut();
        setState(() => _error = '此账号不是团队成员，无法登录');
        return;
      }

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '登录失败：邮箱或密码错误');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: _loading
              ? const Column(mainAxisSize: MainAxisSize.min, children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('正在登录...'),
                ])
              : Form(
                  key: _formKey,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.receipt_long, size: 80,
                        color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 16),
                    Text('订单管理系统',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 40),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                          labelText: '邮箱', prefixIcon: Icon(Icons.email_outlined),
                          border: OutlineInputBorder()),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return '请输入邮箱';
                        if (!v.contains('@')) return '邮箱格式不正确';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                          labelText: '密码', prefixIcon: Icon(Icons.lock_outlined),
                          border: OutlineInputBorder()),
                      validator: (v) {
                        if (v == null || v.isEmpty) return '请输入密码';
                        return null;
                      },
                      onFieldSubmitted: (_) => _login(),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Text(_error!,
                          style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                        width: double.infinity, height: 48,
                        child: FilledButton(
                          onPressed: _loading ? null : _login,
                          child: _loading
                              ? const SizedBox(width: 20, height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text('登录', style: TextStyle(fontSize: 16)),
                        )),
                  ])),
        ),
      ),
    );
  }
}
