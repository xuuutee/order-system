class Payment {
  final String id;
  final String orderId;
  final double amount;
  final String type; // '收入' or '支出'
  final DateTime? paidAt;
  final String? note;
  final String? recordedBy;

  const Payment({
    required this.id,
    required this.orderId,
    required this.amount,
    required this.type,
    this.paidAt,
    this.note,
    this.recordedBy,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      amount: _parseDecimal(json['amount']),
      type: json['type'] as String,
      paidAt: json['paid_at'] != null
          ? DateTime.parse(json['paid_at'] as String)
          : null,
      note: json['note'] as String?,
      recordedBy: json['recorded_by'] as String?,
    );
  }

  static double _parseDecimal(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'amount': amount,
      'type': type,
      'paid_at': paidAt?.toIso8601String(),
      'note': note,
      'recorded_by': recordedBy,
    };
  }
}
