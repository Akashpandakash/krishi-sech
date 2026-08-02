import 'package:krishi_sech/features/location/domain/entities/farm_location.dart';

abstract interface class LocationRepository {
  Future<FarmLocation?> loadSavedLocation();
  Future<FarmLocation> detectCurrentLocation();
  Future<void> saveLocation(FarmLocation location);
  Future<bool> openLocationSettings();
  Future<bool> openAppSettings();
}
