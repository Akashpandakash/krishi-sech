import 'package:flutter/foundation.dart';
import 'package:krishi_sech/features/location/data/services/location_service.dart';
import 'package:krishi_sech/features/location/domain/entities/farm_location.dart';
import 'package:krishi_sech/features/location/domain/repositories/location_repository.dart';

class LocationController extends ChangeNotifier {
  LocationController._({required this._repository, this._location});

  final LocationRepository? _repository;
  FarmLocation? _location;
  LocationFailureType? _lastFailure;
  bool _isLoading = false;
  bool _requestedThisSession = false;

  FarmLocation? get location => _location;
  bool get isLoading => _isLoading;
  bool get hasLocation => _location != null;
  bool get canDetectLocation => _repository != null;
  LocationFailureType? get lastFailure => _lastFailure;

  static Future<LocationController> load(LocationRepository repository) async {
    return LocationController._(
      repository: repository,
      location: await repository.loadSavedLocation(),
    );
  }

  factory LocationController.inMemory({FarmLocation? location}) {
    return LocationController._(repository: null, location: location);
  }

  Future<LocationFailureType?> detectCurrentLocation({
    bool force = false,
  }) async {
    if (_repository == null || _location != null && !force) {
      return null;
    }
    if (_isLoading) {
      return null;
    }
    if (_requestedThisSession && !force) {
      return _lastFailure;
    }

    _requestedThisSession = true;
    _isLoading = true;
    notifyListeners();

    try {
      final detectedLocation = await _repository.detectCurrentLocation();
      await _repository.saveLocation(detectedLocation);
      _location = detectedLocation;
      _lastFailure = null;
      return null;
    } on LocationFailure catch (failure) {
      _lastFailure = failure.type;
      return failure.type;
    } catch (_) {
      _lastFailure = LocationFailureType.addressUnavailable;
      return _lastFailure;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectManualLocation(FarmLocation location) async {
    await _repository?.saveLocation(location);
    _location = location;
    notifyListeners();
  }

  Future<bool> openAppSettings() async =>
      await _repository?.openAppSettings() ?? false;

  Future<bool> openLocationSettings() async =>
      await _repository?.openLocationSettings() ?? false;
}
