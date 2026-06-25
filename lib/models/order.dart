class Order {
  final String id;
  final String orderNo;
  final String? typeId;
  final String customerName;
  final String? customerContact;
  final String title;
  final String? description;
  final String status;
  final String? primaryOwner;
  final DateTime? deadline;
  final double? price;
  final double? cost;
  final Map<String, dynamic> extra;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Order({
    required this.id,
    required this.orderNo,
    this.typeId,
    required this.customerName,
    this.customerContact,
    required this.title,
    this.description,
    this.status = '待接单',
    this.primaryOwner,
    this.deadline,
    this.price,
    this.cost,
    this.extra = const {},
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      orderNo: json['order_no'] as String,
      typeId: json['type_id'] as String?,
      customerName: json['customer_name'] as String,
      customerContact: json['customer_contact'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      status: (json['status'] as String?) ?? '待接单',
      primaryOwner: json['primary_owner'] as String?,
      deadline: json['deadline'] != null
          ? DateTime.parse(json['deadline'] as String)
          : null,
      price: _parseDecimal(json['price']),
      cost: _parseDecimal(json['cost']),
      extra: (json['extra'] as Map<String, dynamic>?) ?? {},
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  static double? _parseDecimal(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_no': orderNo,
      'type_id': typeId,
      'customer_name': customerName,
      'customer_contact': customerContact,
      'title': title,
      'description': description,
      'status': status,
      'primary_owner': primaryOwner,
      'deadline': deadline?.toIso8601String(),
      'price': price,
      'cost': cost,
      'extra': extra,
      'created_by': createdBy,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Order copyWith({
    String? id,
    String? orderNo,
    String? typeId,
    String? customerName,
    String? customerContact,
    String? title,
    String? description,
    String? status,
    String? primaryOwner,
    DateTime? deadline,
    double? price,
    double? cost,
    Map<String, dynamic>? extra,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Order(
      id: id ?? this.id,
      orderNo: orderNo ?? this.orderNo,
      typeId: typeId ?? this.typeId,
      customerName: customerName ?? this.customerName,
      customerContact: customerContact ?? this.customerContact,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      primaryOwner: primaryOwner ?? this.primaryOwner,
      deadline: deadline ?? this.deadline,
      price: price ?? this.price,
      cost: cost ?? this.cost,
      extra: extra ?? this.extra,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
