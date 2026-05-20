
class AdminLogModel {
  final String id;
  final String action;
  final String targetId;
  final String adminId;
  final DateTime timestamp;

  AdminLogModel({
    required this.id,
    required this.action,
    required this.targetId,
    required this.adminId,
    required this.timestamp,
  });

  factory AdminLogModel.fromJson(Map<String, dynamic> json) {
    return AdminLogModel(
      id: json['id'] ?? '',
      action: json['action'] ?? '',
      targetId: json['targetId'] ?? '',
      adminId: json['adminId'] ?? '',
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'action': action,
      'targetId': targetId,
      'adminId': adminId,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  AdminLogModel copyWith({
    String? id,
    String? action,
    String? targetId,
    String? adminId,
    DateTime? timestamp,
  }) {
    return AdminLogModel(
      id: id ?? this.id,
      action: action ?? this.action,
      targetId: targetId ?? this.targetId,
      adminId: adminId ?? this.adminId,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
