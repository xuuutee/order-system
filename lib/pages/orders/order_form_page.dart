import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:order_system/models/order_type.dart';
import 'package:order_system/models/team_member.dart';
import 'package:order_system/providers/order_types_provider.dart';
import 'package:order_system/providers/orders_provider.dart';
import 'package:order_system/providers/auth_provider.dart';
import 'package:order_system/widgets/dynamic_form_fields.dart';

class OrderFormPage extends ConsumerStatefulWidget {
  final String? editOrderId;
  const OrderFormPage({super.key, this.editOrderId});

  @override
  ConsumerState<OrderFormPage> createState() => _OrderFormPageState();
}

class _OrderFormPageState extends ConsumerState<OrderFormPage> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  bool _showMore = false;

  // Key fields (always visible)
  OrderType? _selectedType;
  DateTime _deadline = DateTime.now().add(const Duration(days: 3));
  final _priceCtrl = TextEditingController();
  final _receivedCtrl = TextEditingController();

  // More fields (collapsed)
  final _customerCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String? _owner;
  Map<String, dynamic> _extra = {};

  List<TeamMember> _members = [];

  bool get _isEdit => widget.editOrderId != null;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadMembers);
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    _receivedCtrl.dispose();
    _customerCtrl.dispose();
    _contactCtrl.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    final auth = ref.read(authProvider.notifier);
    _members = await auth.getAllMembers();
    if (mounted) setState(() {});
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择订单类型')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final total = double.tryParse(_priceCtrl.text) ?? 0;
      final received = double.tryParse(_receivedCtrl.text) ?? 0;
      final pending = total - received > 0 ? total - received : 0;
      final extraData = {
        ..._extra,
        'received_amount': received,
        'pending_amount': pending,
      };
      final data = {
        'type_id': _selectedType!.id,
        'deadline': _deadline.toIso8601String(),
        'price': total > 0 ? total : null,
        'customer_name': _customerCtrl.text.trim(),
        'customer_contact': _contactCtrl.text.trim(),
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'primary_owner': _owner,
        'extra': extraData,
      };

      final notifier = ref.read(ordersProvider.notifier);
      if (_isEdit) {
        await notifier.updateOrder(widget.editOrderId!, data);
      } else {
        await notifier.createOrder(data);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEdit ? '订单已更新' : '订单已创建')),
      );
      _clearForm();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失败：$e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _clearForm() {
    _priceCtrl.clear();
    _receivedCtrl.clear();
    _customerCtrl.clear();
    _contactCtrl.clear();
    _titleCtrl.clear();
    _descCtrl.clear();
    setState(() {
      _selectedType = null;
      _deadline = DateTime.now().add(const Duration(days: 3));
      _owner = null;
      _extra = {};
      _showMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final typesState = ref.watch(orderTypesProvider);
    final types = typesState.valueOrNull ?? [];

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? '编辑订单' : '新建订单')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ═══ Order type selector ═══
              const Text('订单类型', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              if (typesState.isLoading)
                const Center(child: CircularProgressIndicator())
              else
                SizedBox(
                  height: 80,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: types.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, i) {
                      final t = types[i];
                      final selected = _selectedType?.id == t.id;
                      return GestureDetector(
                        onTap: () => setState(() {
                          _selectedType = t;
                          _extra = {};
                        }),
                        child: Container(
                          width: 100,
                          decoration: BoxDecoration(
                            color: selected
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: selected
                                ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(_typeIcon(t.icon), size: 28,
                                  color: selected ? Theme.of(context).colorScheme.primary : Colors.grey),
                              const SizedBox(height: 4),
                              Text(t.name, style: TextStyle(fontSize: 12,
                                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 24),

              // ═══ Deadline ═══
              InkWell(
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    locale: const Locale('zh'),
                    initialDate: _deadline,
                    firstDate: DateTime.now().subtract(const Duration(days: 30)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (d != null) setState(() => _deadline = d);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: '截止日期',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    '${_deadline.year}-${_deadline.month.toString().padLeft(2, '0')}-${_deadline.day.toString().padLeft(2, '0')}',
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ═══ Price ═══
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: '总金额',
                      border: OutlineInputBorder(),
                      prefixText: '¥ ',
                      prefixIcon: Icon(Icons.monetization_on_outlined),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _receivedCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: '已收金额',
                      border: OutlineInputBorder(),
                      prefixText: '¥ ',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ]),
              const SizedBox(height: 6),
              Builder(builder: (_) {
                final total = double.tryParse(_priceCtrl.text) ?? 0;
                final received = double.tryParse(_receivedCtrl.text) ?? 0;
                final pending = (total - received).clamp(0, double.infinity);
                return Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  Text(
                    '待收金额: ',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  Text(
                    '¥${pending.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700,
                      color: pending > 0 ? Colors.red : Colors.green,
                    ),
                  ),
                ]);
              }),
              const SizedBox(height: 12),

              // ═══ 客户 + 标题（必填，始终可见）═══
              TextFormField(
                controller: _customerCtrl,
                decoration: const InputDecoration(labelText: '客户名称 *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person_outline)),
                validator: (v) => (v == null || v.trim().isEmpty) ? '请输入客户名称' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: '订单标题 *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.title)),
                validator: (v) => (v == null || v.trim().isEmpty) ? '请输入订单标题' : null,
              ),
              const SizedBox(height: 16),

              // ═══ More toggle ═══
              InkWell(
                onTap: () => setState(() => _showMore = !_showMore),
                child: Row(children: [
                  Icon(_showMore ? Icons.expand_less : Icons.expand_more, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 4),
                  Text('更多信息', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.primary)),
                ]),
              ),
              const SizedBox(height: 12),

              // ═══ Collapsed fields ═══
              if (_showMore) ...[
                TextFormField(
                  controller: _contactCtrl,
                  decoration: const InputDecoration(labelText: '联系方式', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: '描述',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _owner,
                  decoration: const InputDecoration(labelText: '负责人', border: OutlineInputBorder()),
                  items: _members.map((m) => DropdownMenuItem(value: m.id, child: Text(m.name))).toList(),
                  onChanged: (v) => setState(() => _owner = v),
                ),
                // Dynamic type-specific fields
                if (_selectedType != null && _selectedType!.fieldsSchema.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  DynamicFormFields(
                    fieldsSchema: _selectedType!.fieldsSchema,
                    onChanged: (v) => _extra = v,
                  ),
                ],
              ],

              const SizedBox(height: 32),

              // ═══ Save ═══
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.save),
                  label: Text(_saving ? '保存中...' : '保存订单', style: const TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  IconData _typeIcon(String name) {
    switch (name) {
      case 'school':
        return Icons.school;
      case 'slideshow':
        return Icons.slideshow;
      case 'description':
        return Icons.description;
      default:
        return Icons.assignment;
    }
  }
}
