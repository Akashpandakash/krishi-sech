class FarmLocation {
  const FarmLocation({
    required this.city,
    required this.district,
    required this.state,
    this.country = 'India',
    this.village,
    this.postalCode,
    this.accuracyMeters,
    this.latitude,
    this.longitude,
    this.gpsTimestamp,
    this.detectedLocality,
    this.fullAddress,
  });

  final String country;
  final String state;
  final String district;
  final String city;
  final String? village;
  final String? postalCode;
  final double? accuracyMeters;
  final double? latitude;
  final double? longitude;
  final DateTime? gpsTimestamp;
  final String? detectedLocality;
  final String? fullAddress;

  String get displayName {
    final parts = <String>[
      if (village?.trim().isNotEmpty ?? false) village!.trim(),
      city,
      district,
      state,
    ];
    return parts.toSet().join(', ');
  }
}
