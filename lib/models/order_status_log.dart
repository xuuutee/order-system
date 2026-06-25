class OrderStatusLog {
  final String id;
  final String orderId;
  final String? fromStatus;
  final String toStatus;
  final String? changedBy;
  final DateTime? changedAt;
  final String? note;

  const OrderStatusLog({
    required this.id,
    required this.orderId,
    this.fromStatus,
    required this.toStatus,
    this.changedBy,
    this.changedAt,
    this.note,
  });

  factory OrderStatusLog.fromJson(Map<String, dynamic> json) {
    return OrderStatusLog(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      fromStatus: json['from_status'] as String?,
      toStatus: json['to_status'] as String,
      changedBy: json['changed_by'] as String?,
      changedAt: json['changed_at'] != null
          ? DateTime.parse(json['changed_at'] as String)
          : null,
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'from_status': fromStatus,
      'to_status': toStatus,
      'changed_by': changedBy,
      'changed_at': changedAt?.toIso8601String(),
      'note': note,
    };
  }
}
