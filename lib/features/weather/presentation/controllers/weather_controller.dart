import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:krishi_sech/features/location/domain/entities/farm_location.dart';
import 'package:krishi_sech/features/location/presentation/controllers/location_controller.dart';
import 'package:krishi_sech/features/weather/domain/entities/current_weather.dart';
import 'package:krishi_sech/features/weather/domain/repositories/weather_repository.dart';
import 'package:krishi_sech/features/weather/data/services/weather_service.dart';
import 'package:krishi_sech/core/config/app_environment.dart';

enum WeatherStatus { idle, loading, loaded, error }

class WeatherController extends ChangeNotifier with WidgetsBindingObserver {
  WeatherController({
    required this.repository,
    required this.locationController,
  }) {
    WidgetsBinding.instance.addObserver(this);
    _observingLifecycle = true;
    locationController!.addListener(_onLocationChanged);
    _locationKey = _keyFor(locationController!.location);
    if (locationController!.location != null) unawaited(refresh());
  }

  WeatherController.inMemory({CurrentWeather? weather})
    : repository = null,
      locationController = null {
    _weather = weather;
    _status = weather == null ? WeatherStatus.idle : WeatherStatus.loaded;
  }

  final WeatherRepository? repository;
  final LocationController? locationController;
  CurrentWeather? _weather;
  WeatherStatus _status = WeatherStatus.idle;
  String? _locationKey;
  int _requestId = 0;
  Timer? _refreshTimer;
  String? _errorReason;
  bool _observingLifecycle = false;

  CurrentWeather? get weather => _weather;
  WeatherStatus get status => _status;
  String? get errorReason => _errorReason;
  bool get isUsingCachedData =>
      repository is WeatherSyncAwareRepository &&
      (repository! as WeatherSyncAwareRepository).isUsingCachedData;

  Future<void> refresh() async {
    final location = locationController?.location;
    if (repository == null || location == null) {
      _status = WeatherStatus.idle;
      notifyListeners();
      return;
    }

    final requestId = ++_requestId;
    _status = WeatherStatus.loading;
    _errorReason = null;
    notifyListeners();
    try {
      final weather = await repository!.fetchCurrentWeather(location);
      if (requestId != _requestId) return;
      _weather = weather;
      _status = WeatherStatus.loaded;
    } on WeatherException catch (error) {
      if (requestId != _requestId) return;
      _status = WeatherStatus.error;
      _errorReason = error.reason ?? error.type.name;
      if (kDebugMode && AppEnvironment.loggingEnabled) {
        debugPrint(
          'Weather refresh failed status=${error.statusCode ?? 'none'} reason=$_errorReason',
        );
      }
    } catch (error) {
      if (requestId != _requestId) return;
      _status = WeatherStatus.error;
      _errorReason = error.toString();
      if (kDebugMode && AppEnvironment.loggingEnabled) {
        debugPrint('Weather refresh failed reason=$_errorReason');
      }
    }
    notifyListeners();
    _scheduleAutomaticRefresh();
  }

  void _onLocationChanged() {
    final nextKey = _keyFor(locationController?.location);
    if (nextKey == _locationKey) return;
    _locationKey = nextKey;
    _refreshTimer?.cancel();
    unawaited(refresh());
  }

  void _scheduleAutomaticRefresh() {
    _refreshTimer?.cancel();
    if (repository == null || locationController?.location == null) return;
    final usingCache =
        repository is WeatherSyncAwareRepository &&
        (repository! as WeatherSyncAwareRepository).isUsingCachedData;
    _refreshTimer = Timer(
      usingCache || _status == WeatherStatus.error
          ? const Duration(seconds: 30)
          : const Duration(minutes: 10),
      refresh,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (repository != null && locationController?.location != null) {
        unawaited(refresh());
      }
      return;
    }
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  String? _keyFor(FarmLocation? location) => location == null
      ? null
      : '${location.latitude}|${location.longitude}|${location.city}|'
            '${location.district}|${location.state}|${location.country}';

  @override
  void dispose() {
    _refreshTimer?.cancel();
    if (_observingLifecycle) WidgetsBinding.instance.removeObserver(this);
    locationController?.removeListener(_onLocationChanged);
    super.dispose();
  }
}
