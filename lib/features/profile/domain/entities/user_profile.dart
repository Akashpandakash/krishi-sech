class UserProfile {
  const UserProfile({
    required this.id,
    required this.phone,
    required this.preferredLanguage,
    this.fullName,
    this.profilePhotoPath,
    this.profilePhotoUrl,
    this.state,
    this.district,
    this.village,
    this.updatedAt,
  });
  final String id;
  final String phone;
  final String? fullName;
  final String preferredLanguage;
  final String? profilePhotoPath;
  final String? profilePhotoUrl;
  final String? state;
  final String? district;
  final String? village;
  final DateTime? updatedAt;

  String get displayName =>
      (fullName?.trim().isNotEmpty ?? false) ? fullName!.trim() : phone;
  Map<String, dynamic> toJson() => {
    'id': id,
    'phone': phone,
    'name': fullName,
    'preferredLanguage': preferredLanguage,
    'profilePhotoPath': profilePhotoPath,
    'profilePhotoUrl': profilePhotoUrl,
    'state': state,
    'district': district,
    'village': village,
    'updatedAt': updatedAt?.toIso8601String(),
  };
  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'] as String,
    phone: json['phone'] as String,
    fullName: json['name'] as String?,
    preferredLanguage: json['preferredLanguage'] as String? ?? 'bn',
    profilePhotoPath: json['profilePhotoPath'] as String?,
    profilePhotoUrl: json['profilePhotoUrl'] as String?,
    state: json['state'] as String?,
    district: json['district'] as String?,
    village: json['village'] as String?,
    updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
  );
}
