import 'package:krishi_sech/features/location/data/services/location_service.dart';
import 'package:krishi_sech/features/location/domain/entities/farm_location.dart';
import 'package:krishi_sech/features/location/domain/repositories/location_repository.dart';
import 'package:krishi_sech/features/location/domain/services/address_sanitizer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationRepositoryImpl implements LocationRepository {
  const LocationRepositoryImpl({
    required this._preferences,
    required this._locationService,
  });

  static const _countryKey = 'location_country';
  static const _stateKey = 'location_state';
  static const _districtKey = 'location_district';
  static const _cityKey = 'location_city';
  static const _villageKey = 'location_village';
  static const _postalCodeKey = 'location_postal_code';
  static const _accuracyKey = 'location_accuracy_meters';
  static const _latitudeKey = 'location_latitude';
  static const _longitudeKey = 'location_longitude';
  static const _timestampKey = 'location_gps_timestamp';
  static const _detectedLocalityKey = 'location_detected_locality';
  static const _fullAddressKey = 'location_full_address';

  final SharedPreferences _preferences;
  final LocationService _locationService;

  @override
  Future<FarmLocation> detectCurrentLocation() {
    return _locationService.determineCurrentLocation();
  }

  @override
  Future<FarmLocation?> loadSavedLocation() async {
    final state = _preferences.getString(_stateKey);
    final savedDistrict = _preferences.getString(_districtKey);
    final savedCity = _preferences.getString(_cityKey);

    if (state == null || savedDistrict == null || savedCity == null) {
      return null;
    }

    final city = firstFriendlyAddressPart([savedCity, savedDistrict, state]);
    final district = firstFriendlyAddressPart([
      savedDistrict,
      savedCity,
      state,
    ]);
    if (city == null || district == null) return null;

    return FarmLocation(
      country: _preferences.getString(_countryKey) ?? 'India',
      state: state,
      district: district,
      city: city,
      village: _preferences.getString(_villageKey),
      postalCode: _preferences.getString(_postalCodeKey),
      accuracyMeters: _preferences.getDouble(_accuracyKey),
      latitude: _preferences.getDouble(_latitudeKey),
      longitude: _preferences.getDouble(_longitudeKey),
      gpsTimestamp: DateTime.tryParse(
        _preferences.getString(_timestampKey) ?? '',
      ),
      detectedLocality: firstFriendlyAddressPart([
        _preferences.getString(_detectedLocalityKey),
        city,
      ]),
      fullAddress: sanitizeFormattedAddress(
        _preferences.getString(_fullAddressKey),
      ),
    );
  }

  @override
  Future<void> saveLocation(FarmLocation location) async {
    await Future.wait([
      _preferences.setString(_countryKey, location.country),
      _preferences.setString(_stateKey, location.state),
      _preferences.setString(_districtKey, location.district),
      _preferences.setString(_cityKey, location.city),
      if (location.village?.trim().isNotEmpty ?? false)
        _preferences.setString(_villageKey, location.village!.trim())
      else
        _preferences.remove(_villageKey),
      if (location.postalCode?.trim().isNotEmpty ?? false)
        _preferences.setString(_postalCodeKey, location.postalCode!.trim())
      else
        _preferences.remove(_postalCodeKey),
      if (location.accuracyMeters != null)
        _preferences.setDouble(_accuracyKey, location.accuracyMeters!)
      else
        _preferences.remove(_accuracyKey),
      if (location.latitude != null)
        _preferences.setDouble(_latitudeKey, location.latitude!)
      else
        _preferences.remove(_latitudeKey),
      if (location.longitude != null)
        _preferences.setDouble(_longitudeKey, location.longitude!)
      else
        _preferences.remove(_longitudeKey),
      if (location.gpsTimestamp != null)
        _preferences.setString(
          _timestampKey,
          location.gpsTimestamp!.toIso8601String(),
        )
      else
        _preferences.remove(_timestampKey),
      if (location.detectedLocality?.trim().isNotEmpty ?? false)
        _preferences.setString(
          _detectedLocalityKey,
          location.detectedLocality!.trim(),
        )
      else
        _preferences.remove(_detectedLocalityKey),
      if (location.fullAddress?.trim().isNotEmpty ?? false)
        _preferences.setString(_fullAddressKey, location.fullAddress!.trim())
      else
        _preferences.remove(_fullAddressKey),
    ]);
  }

  @override
  Future<bool> openAppSettings() => _locationService.openAppSettings();

  @override
  Future<bool> openLocationSettings() =>
      _locationService.openLocationSettings();
}
