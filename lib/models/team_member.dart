class TeamMember {
  final String id;
  final String? authId;
  final String name;
  final String? phone;
  final DateTime? createdAt;

  const TeamMember({
    required this.id,
    this.authId,
    required this.name,
    this.phone,
    this.createdAt,
  });

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    return TeamMember(
      id: json['id'] as String,
      authId: json['auth_id'] as String?,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'auth_id': authId,
      'name': name,
      'phone': phone,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
