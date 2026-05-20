
class BookingModel {
  final String bookingId; // BK-XXXX format
  final String customerId;
  final String providerId;
  final String service;
  final double customerLat;
  final double customerLng;
  final String customerAreaName;
  final DateTime scheduledAt;
  final String status; // 'booked', 'confirmed', 'en_route', 'arrived', 'in_progress', 'completed', 'cancelled', 'disputed'
  final bool isUrgent;
  final Map<String, dynamic> pricingBreakdown; // baseFee, travelFee, urgentSurcharge, platformFee, total
  final double distanceKm;
  final String paymentStatus; // 'pending', 'paid', 'refunded'
  final DateTime createdAt;
  final DateTime? completedAt;
  final int? rating;
  final String? reviewComment;
  final List<String> customerBadges;
  final Map<String, dynamic> agentLogs; // Keys: 'IntentAgent', 'DiscoveryAgent', 'RankingAgent', 'BookingAgent', etc.

  BookingModel({
    required this.bookingId,
    required this.customerId,
    required this.providerId,
    required this.service,
    required this.customerLat,
    required this.customerLng,
    required this.customerAreaName,
    required this.scheduledAt,
    required this.status,
    required this.isUrgent,
    required this.pricingBreakdown,
    required this.distanceKm,
    required this.paymentStatus,
    required this.createdAt,
    this.completedAt,
    this.rating,
    this.reviewComment,
    required this.customerBadges,
    required this.agentLogs,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      bookingId: json['bookingId'] ?? '',
      customerId: json['customerId'] ?? '',
      providerId: json['providerId'] ?? '',
      service: json['service'] ?? '',
      customerLat: (json['customerLat'] ?? 0.0).toDouble(),
      customerLng: (json['customerLng'] ?? 0.0).toDouble(),
      customerAreaName: json['customerAreaName'] ?? '',
      scheduledAt: DateTime.tryParse(json['scheduledAt']?.toString() ?? '') ?? DateTime.now(),
      status: json['status'] ?? 'booked',
      isUrgent: json['isUrgent'] ?? false,
      pricingBreakdown: Map<String, dynamic>.from(json['pricingBreakdown'] ?? {}),
      distanceKm: (json['distanceKm'] ?? 0.0).toDouble(),
      paymentStatus: json['paymentStatus'] ?? 'pending',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      completedAt: json['completedAt'] != null
              ? DateTime.tryParse(json['completedAt'].toString())
              : null,
      rating: json['rating'] != null ? (json['rating'] as num).toInt() : null,
      reviewComment: json['reviewComment'],
      customerBadges: List<String>.from(json['customerBadges'] ?? []),
      agentLogs: Map<String, dynamic>.from(json['agentLogs'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bookingId': bookingId,
      'customerId': customerId,
      'providerId': providerId,
      'service': service,
      'customerLat': customerLat,
      'customerLng': customerLng,
      'customerAreaName': customerAreaName,
      'scheduledAt': scheduledAt.toIso8601String(),
      'status': status,
      'isUrgent': isUrgent,
      'pricingBreakdown': pricingBreakdown,
      'distanceKm': distanceKm,
      'paymentStatus': paymentStatus,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'rating': rating,
      'reviewComment': reviewComment,
      'customerBadges': customerBadges,
      'agentLogs': agentLogs,
    };
  }

  BookingModel copyWith({
    String? bookingId,
    String? customerId,
    String? providerId,
    String? service,
    double? customerLat,
    double? customerLng,
    String? customerAreaName,
    DateTime? scheduledAt,
    String? status,
    bool? isUrgent,
    Map<String, dynamic>? pricingBreakdown,
    double? distanceKm,
    String? paymentStatus,
    DateTime? createdAt,
    DateTime? completedAt,
    int? rating,
    String? reviewComment,
    List<String>? customerBadges,
    Map<String, dynamic>? agentLogs,
  }) {
    return BookingModel(
      bookingId: bookingId ?? this.bookingId,
      customerId: customerId ?? this.customerId,
      providerId: providerId ?? this.providerId,
      service: service ?? this.service,
      customerLat: customerLat ?? this.customerLat,
      customerLng: customerLng ?? this.customerLng,
      customerAreaName: customerAreaName ?? this.customerAreaName,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      status: status ?? this.status,
      isUrgent: isUrgent ?? this.isUrgent,
      pricingBreakdown: pricingBreakdown ?? this.pricingBreakdown,
      distanceKm: distanceKm ?? this.distanceKm,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      rating: rating ?? this.rating,
      reviewComment: reviewComment ?? this.reviewComment,
      customerBadges: customerBadges ?? this.customerBadges,
      agentLogs: agentLogs ?? this.agentLogs,
    );
  }
}
