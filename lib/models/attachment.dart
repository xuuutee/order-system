class Attachment {
  final String id;
  final String orderId;
  final String fileUrl;
  final String fileName;
  final String? uploadedBy;
  final DateTime? uploadedAt;

  const Attachment({
    required this.id,
    required this.orderId,
    required this.fileUrl,
    required this.fileName,
    this.uploadedBy,
    this.uploadedAt,
  });

  factory Attachment.fromJson(Map<String, dynamic> json) {
    return Attachment(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      fileUrl: json['file_url'] as String,
      fileName: json['file_name'] as String,
      uploadedBy: json['uploaded_by'] as String?,
      uploadedAt: json['uploaded_at'] != null
          ? DateTime.parse(json['uploaded_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'file_url': fileUrl,
      'file_name': fileName,
      'uploaded_by': uploadedBy,
      'uploaded_at': uploadedAt?.toIso8601String(),
    };
  }
}
