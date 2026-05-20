
class ProviderModel {
  final String id;
  final String name;
  final String phone;
  final String password; // Hashed password
  final String category; // 'AC Technician', 'Plumber', 'Electrician', 'Carpenter', 'Mechanic', 'Painter'
  final String skillLevel; // 'basic', 'intermediate', 'expert'
  final String cnicImageUrl;
  final String approvalStatus; // 'pending', 'approved', 'rejected', 'suspended'
  final double lat;
  final double lng;
  final String areaName; // Hyderabad area
  final double rating; // 1.0 - 5.0
  final int reviewCount;
  final double onTimeScore; // 0.0 - 1.0
  final double cancellationRate; // 0.0 - 1.0
  final double riskScore; // 0.0 - 1.0
  final List<String> badges;
  final List<String> negativeTags;
  final List<Map<String, dynamic>> shifts; // date, startTime, endTime
  final int baseRatePkr; // 100 - 300
  final int pkrPerKm; // 50 - 100
  final int urgentSurcharge;
  final double weeklyEarningsPending;
  final bool isOnline;
  final double currentLat;
  final double currentLng;
  final DateTime createdAt;

  ProviderModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.password,
    required this.category,
    required this.skillLevel,
    required this.cnicImageUrl,
    required this.approvalStatus,
    required this.lat,
    required this.lng,
    required this.areaName,
    required this.rating,
    required this.reviewCount,
    required this.onTimeScore,
    required this.cancellationRate,
    required this.riskScore,
    required this.badges,
    required this.negativeTags,
    required this.shifts,
    required this.baseRatePkr,
    required this.pkrPerKm,
    required this.urgentSurcharge,
    required this.weeklyEarningsPending,
    required this.isOnline,
    required this.currentLat,
    required this.currentLng,
    required this.createdAt,
  });

  factory ProviderModel.fromJson(Map<String, dynamic> json) {
    return ProviderModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      password: json['password'] ?? '',
      category: json['category'] ?? '',
      skillLevel: json['skillLevel'] ?? 'basic',
      cnicImageUrl: json['cnicImageUrl'] ?? '',
      approvalStatus: json['approvalStatus'] ?? 'pending',
      lat: (json['lat'] ?? 0.0).toDouble(),
      lng: (json['lng'] ?? 0.0).toDouble(),
      areaName: json['areaName'] ?? '',
      rating: (json['rating'] ?? 5.0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      onTimeScore: (json['onTimeScore'] ?? 1.0).toDouble(),
      cancellationRate: (json['cancellationRate'] ?? 0.0).toDouble(),
      riskScore: (json['riskScore'] ?? 0.0).toDouble(),
      badges: List<String>.from(json['badges'] ?? []),
      negativeTags: List<String>.from(json['negativeTags'] ?? []),
      shifts: List<Map<String, dynamic>>.from(
        (json['shifts'] as List?)?.map((item) => Map<String, dynamic>.from(item)) ?? [],
      ),
      baseRatePkr: json['baseRatePkr'] ?? 150,
      pkrPerKm: json['pkrPerKm'] ?? 60,
      urgentSurcharge: json['urgentSurcharge'] ?? 100,
      weeklyEarningsPending: (json['weeklyEarningsPending'] ?? 0.0).toDouble(),
      isOnline: json['isOnline'] ?? false,
      currentLat: (json['currentLat'] ?? 0.0).toDouble(),
      currentLng: (json['currentLng'] ?? 0.0).toDouble(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'password': password,
      'category': category,
      'skillLevel': skillLevel,
      'cnicImageUrl': cnicImageUrl,
      'approvalStatus': approvalStatus,
      'lat': lat,
      'lng': lng,
      'areaName': areaName,
      'rating': rating,
      'reviewCount': reviewCount,
      'onTimeScore': onTimeScore,
      'cancellationRate': cancellationRate,
      'riskScore': riskScore,
      'badges': badges,
      'negativeTags': negativeTags,
      'shifts': shifts,
      'baseRatePkr': baseRatePkr,
      'pkrPerKm': pkrPerKm,
      'urgentSurcharge': urgentSurcharge,
      'weeklyEarningsPending': weeklyEarningsPending,
      'isOnline': isOnline,
      'currentLat': currentLat,
      'currentLng': currentLng,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  ProviderModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? password,
    String? category,
    String? skillLevel,
    String? cnicImageUrl,
    String? approvalStatus,
    double? lat,
    double? lng,
    String? areaName,
    double? rating,
    int? reviewCount,
    double? onTimeScore,
    double? cancellationRate,
    double? riskScore,
    List<String>? badges,
    List<String>? negativeTags,
    List<Map<String, dynamic>>? shifts,
    int? baseRatePkr,
    int? pkrPerKm,
    int? urgentSurcharge,
    double? weeklyEarningsPending,
    bool? isOnline,
    double? currentLat,
    double? currentLng,
    DateTime? createdAt,
  }) {
    return ProviderModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      password: password ?? this.password,
      category: category ?? this.category,
      skillLevel: skillLevel ?? this.skillLevel,
      cnicImageUrl: cnicImageUrl ?? this.cnicImageUrl,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      areaName: areaName ?? this.areaName,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      onTimeScore: onTimeScore ?? this.onTimeScore,
      cancellationRate: cancellationRate ?? this.cancellationRate,
      riskScore: riskScore ?? this.riskScore,
      badges: badges ?? this.badges,
      negativeTags: negativeTags ?? this.negativeTags,
      shifts: shifts ?? this.shifts,
      baseRatePkr: baseRatePkr ?? this.baseRatePkr,
      pkrPerKm: pkrPerKm ?? this.pkrPerKm,
      urgentSurcharge: urgentSurcharge ?? this.urgentSurcharge,
      weeklyEarningsPending: weeklyEarningsPending ?? this.weeklyEarningsPending,
      isOnline: isOnline ?? this.isOnline,
      currentLat: currentLat ?? this.currentLat,
      currentLng: currentLng ?? this.currentLng,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
