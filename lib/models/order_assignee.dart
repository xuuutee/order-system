class OrderAssignee {
  final String orderId;
  final String memberId;
  final String? taskNote;

  const OrderAssignee({
    required this.orderId,
    required this.memberId,
    this.taskNote,
  });

  factory OrderAssignee.fromJson(Map<String, dynamic> json) {
    return OrderAssignee(
      orderId: json['order_id'] as String,
      memberId: json['member_id'] as String,
      taskNote: json['task_note'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'member_id': memberId,
      'task_note': taskNote,
    };
  }
}
