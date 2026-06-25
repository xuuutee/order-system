import 'dart:convert';

class OrderType {
  final String id;
  final String name;
  final String icon;
  final List<FieldSchema> fieldsSchema;
  final bool isActive;
  final DateTime? createdAt;

  const OrderType({
    required this.id,
    required this.name,
    this.icon = 'assignment',
    this.fieldsSchema = const [],
    this.isActive = true,
    this.createdAt,
  });

  factory OrderType.fromJson(Map<String, dynamic> json) {
    return OrderType(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: (json['icon'] as String?) ?? 'assignment',
      fieldsSchema: _parseFieldsSchema(json['fields_schema']),
      isActive: (json['is_active'] as bool?) ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  static List<FieldSchema> _parseFieldsSchema(dynamic schema) {
    if (schema == null) return [];
    final List<dynamic> list = schema is String
        ? _jsonDecode(schema) as List<dynamic>
        : schema as List<dynamic>;
    return list.map((e) => FieldSchema.fromJson(e as Map<String, dynamic>)).toList();
  }

  static dynamic _jsonDecode(String s) => jsonDecode(s);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'fields_schema': fieldsSchema.map((f) => f.toJson()).toList(),
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

class FieldSchema {
  final String key;
  final String label;
  final String type; // text, number, url, select
  final List<String>? options;
  final bool required;

  const FieldSchema({
    required this.key,
    required this.label,
    this.type = 'text',
    this.options,
    this.required = false,
  });

  factory FieldSchema.fromJson(Map<String, dynamic> json) {
    return FieldSchema(
      key: json['key'] as String,
      label: json['label'] as String,
      type: (json['type'] as String?) ?? 'text',
      options: (json['options'] as List<dynamic>?)?.cast<String>(),
      required: (json['required'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'label': label,
      'type': type,
      if (options != null) 'options': options,
      'required': required,
    };
  }
}
