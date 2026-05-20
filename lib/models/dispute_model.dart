
class DisputeModel {
  final String id;
  final String bookingId;
  final String customerId;
  final String providerId;
  final String type; // 'no_show', 'overcharge', 'poor_quality', 'provider_cancelled', 'other'
  final String description;
  final String aiResolution;
  final String aiRationale;
  final String status; // 'open', 'auto_resolved', 'escalated', 'manually_resolved'
  final DateTime createdAt;

  DisputeModel({
    required this.id,
    required this.bookingId,
    required this.customerId,
    required this.providerId,
    required this.type,
    required this.description,
    required this.aiResolution,
    required this.aiRationale,
    required this.status,
    required this.createdAt,
  });

  factory DisputeModel.fromJson(Map<String, dynamic> json) {
    return DisputeModel(
      id: json['id'] ?? '',
      bookingId: json['bookingId'] ?? '',
      customerId: json['customerId'] ?? '',
      providerId: json['providerId'] ?? '',
      type: json['type'] ?? 'other',
      description: json['description'] ?? '',
      aiResolution: json['aiResolution'] ?? '',
      aiRationale: json['aiRationale'] ?? '',
      status: json['status'] ?? 'open',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookingId': bookingId,
      'customerId': customerId,
      'providerId': providerId,
      'type': type,
      'description': description,
      'aiResolution': aiResolution,
      'aiRationale': aiRationale,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  DisputeModel copyWith({
    String? id,
    String? bookingId,
    String? customerId,
    String? providerId,
    String? type,
    String? description,
    String? aiResolution,
    String? aiRationale,
    String? status,
    DateTime? createdAt,
  }) {
    return DisputeModel(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      customerId: customerId ?? this.customerId,
      providerId: providerId ?? this.providerId,
      type: type ?? this.type,
      description: description ?? this.description,
      aiResolution: aiResolution ?? this.aiResolution,
      aiRationale: aiRationale ?? this.aiRationale,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
