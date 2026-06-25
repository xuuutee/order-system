import 'package:flutter/material.dart';

import 'package:order_system/models/order_type.dart';

/// Renders form fields based on a list of FieldSchema definitions.
/// Callback returns a `Map<String, dynamic>` of field values on change.
class DynamicFormFields extends StatefulWidget {
  final List<FieldSchema> fieldsSchema;
  final Map<String, dynamic> initialValues;
  final ValueChanged<Map<String, dynamic>> onChanged;

  const DynamicFormFields({
    super.key,
    required this.fieldsSchema,
    this.initialValues = const {},
    required this.onChanged,
  });

  @override
  State<DynamicFormFields> createState() => _DynamicFormFieldsState();
}

class _DynamicFormFieldsState extends State<DynamicFormFields> {
  final Map<String, dynamic> _values = {};
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _values.addAll(widget.initialValues);
    for (final field in widget.fieldsSchema) {
      final ctrl = TextEditingController(
        text: _values[field.key]?.toString() ?? '',
      );
      _controllers[field.key] = ctrl;
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _notify(String key, dynamic value) {
    _values[key] = value;
    widget.onChanged(Map.from(_values));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.fieldsSchema.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widget.fieldsSchema.map((field) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildField(field),
        );
      }).toList(),
    );
  }

  Widget _buildField(FieldSchema field) {
    switch (field.type) {
      case 'number':
        return TextFormField(
          controller: _controllers[field.key],
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: field.label + (field.required ? ' *' : ''),
            border: const OutlineInputBorder(),
          ),
          validator: field.required
              ? (v) => (v == null || v.isEmpty) ? '请输入${field.label}' : null
              : null,
          onChanged: (v) => _notify(field.key, num.tryParse(v) ?? v),
        );
      case 'url':
        return TextFormField(
          controller: _controllers[field.key],
          keyboardType: TextInputType.url,
          decoration: InputDecoration(
            labelText: field.label + (field.required ? ' *' : ''),
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.link),
          ),
          validator: field.required
              ? (v) => (v == null || v.isEmpty) ? '请输入${field.label}' : null
              : null,
          onChanged: (v) => _notify(field.key, v),
        );
      case 'select':
        return DropdownButtonFormField<String>(
          initialValue: _values[field.key] is String ? _values[field.key] as String : null,
          decoration: InputDecoration(
            labelText: field.label + (field.required ? ' *' : ''),
            border: const OutlineInputBorder(),
          ),
          items: (field.options ?? []).map((o) {
            return DropdownMenuItem(value: o, child: Text(o));
          }).toList(),
          validator: field.required
              ? (v) => (v == null || v.isEmpty) ? '请选择${field.label}' : null
              : null,
          onChanged: (v) => _notify(field.key, v),
        );
      default: // text
        return TextFormField(
          controller: _controllers[field.key],
          decoration: InputDecoration(
            labelText: field.label + (field.required ? ' *' : ''),
            border: const OutlineInputBorder(),
          ),
          validator: field.required
              ? (v) => (v == null || v.isEmpty) ? '请输入${field.label}' : null
              : null,
          onChanged: (v) => _notify(field.key, v),
        );
    }
  }
}
