
class UserModel {
  final String id;
  final String name;
  final String phone;
  final String? email; // Optional
  final String mode; // 'customer' or 'provider'
  final DateTime createdAt;
  final List<Map<String, dynamic>> savedAddresses; // label, address, lat, lng
  final String languagePref; // 'en' or 'ur'
  final bool notificationsEnabled;

  UserModel({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    required this.mode,
    required this.createdAt,
    required this.savedAddresses,
    required this.languagePref,
    required this.notificationsEnabled,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'],
      mode: json['mode'] ?? 'customer',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      savedAddresses: List<Map<String, dynamic>>.from(
        (json['savedAddresses'] as List?)?.map((item) => Map<String, dynamic>.from(item)) ?? [],
      ),
      languagePref: json['languagePref'] ?? 'en',
      notificationsEnabled: json['notificationsEnabled'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'mode': mode,
      'createdAt': createdAt.toIso8601String(),
      'savedAddresses': savedAddresses,
      'languagePref': languagePref,
      'notificationsEnabled': notificationsEnabled,
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? mode,
    DateTime? createdAt,
    List<Map<String, dynamic>>? savedAddresses,
    String? languagePref,
    bool? notificationsEnabled,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      mode: mode ?? this.mode,
      createdAt: createdAt ?? this.createdAt,
      savedAddresses: savedAddresses ?? this.savedAddresses,
      languagePref: languagePref ?? this.languagePref,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }
}
