import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:krishi_sech/features/location/domain/entities/farm_location.dart';
import 'package:krishi_sech/features/location/domain/services/address_sanitizer.dart';

enum LocationFailureType {
  permissionDenied,
  permissionPermanentlyDenied,
  serviceDisabled,
  reducedAccuracy,
  detectionTimedOut,
  addressUnavailable,
}

class LocationFailure implements Exception {
  const LocationFailure(this.type);

  final LocationFailureType type;
}

class LocationService {
  const LocationService();

  static const _collectionTimeout = Duration(seconds: 18);
  static const _minimumCollectionTime = Duration(seconds: 3);
  static const _maximumPositionAge = Duration(seconds: 30);
  static const _preferredAccuracyMeters = 40.0;

  Future<FarmLocation> determineCurrentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationFailure(LocationFailureType.serviceDisabled);
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const LocationFailure(LocationFailureType.permissionDenied);
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationFailure(
        LocationFailureType.permissionPermanentlyDenied,
      );
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      final accuracyStatus = await Geolocator.getLocationAccuracy();
      if (accuracyStatus == LocationAccuracyStatus.reduced) {
        throw const LocationFailure(LocationFailureType.reducedAccuracy);
      }
    }

    final position = await _collectBestFreshPosition();
    _logPosition(position);

    final placemarks = await Geocoding().placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );
    if (placemarks.isEmpty) {
      throw const LocationFailure(LocationFailureType.addressUnavailable);
    }

    final placemark = placemarks.first;
    _logPlacemark(placemark);

    final locality = firstFriendlyAddressPart([
      placemark.locality,
      placemark.subLocality,
    ]);
    final district = firstFriendlyAddressPart([
      placemark.subAdministrativeArea,
      placemark.locality,
      placemark.subLocality,
    ]);
    final city = firstFriendlyAddressPart([
      placemark.locality,
      placemark.subLocality,
      placemark.subAdministrativeArea,
      placemark.administrativeArea,
    ]);
    final state = firstFriendlyAddressPart([placemark.administrativeArea]);
    final country = firstFriendlyAddressPart([placemark.country]);

    if (city == null || district == null || state == null || country == null) {
      throw const LocationFailure(LocationFailureType.addressUnavailable);
    }

    return FarmLocation(
      city: city,
      district: district,
      state: state,
      country: country,
      postalCode: firstFriendlyAddressPart([placemark.postalCode]),
      accuracyMeters: position.accuracy,
      latitude: position.latitude,
      longitude: position.longitude,
      gpsTimestamp: position.timestamp,
      detectedLocality: locality ?? city,
      fullAddress: _formattedAddress(placemark),
    );
  }

  Future<Position> _collectBestFreshPosition() async {
    final completer = Completer<Position>();
    final positions = <Position>[];
    final startedAt = DateTime.now();
    StreamSubscription<Position>? subscription;
    Timer? timeout;

    void completeWithBest() {
      if (completer.isCompleted || positions.isEmpty) return;
      positions.sort((a, b) {
        final accuracyComparison = a.accuracy.compareTo(b.accuracy);
        if (accuracyComparison != 0) return accuracyComparison;
        return b.timestamp.compareTo(a.timestamp);
      });
      completer.complete(positions.first);
    }

    subscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 0,
          ),
        ).listen(
          (position) {
            final age = DateTime.now().difference(position.timestamp);
            if (age.isNegative || age > _maximumPositionAge) {
              if (kDebugMode) {
                debugPrint(
                  'Location: rejected stale fix (${age.inSeconds}s old)',
                );
              }
              return;
            }

            positions.add(position);
            final sampledFor = DateTime.now().difference(startedAt);
            if (sampledFor >= _minimumCollectionTime &&
                position.accuracy <= _preferredAccuracyMeters) {
              completeWithBest();
            }
          },
          onError: (Object error, StackTrace stackTrace) {
            if (!completer.isCompleted) {
              completer.completeError(error, stackTrace);
            }
          },
        );

    timeout = Timer(_collectionTimeout, () {
      if (positions.isNotEmpty) {
        completeWithBest();
      } else if (!completer.isCompleted) {
        completer.completeError(
          const LocationFailure(LocationFailureType.detectionTimedOut),
        );
      }
    });

    try {
      return await completer.future;
    } finally {
      timeout.cancel();
      await subscription.cancel();
    }
  }

  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();

  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  String _formattedAddress(Placemark placemark) {
    final parts = <String?>[
      placemark.street,
      placemark.subLocality,
      placemark.locality,
      placemark.subAdministrativeArea,
      placemark.administrativeArea,
      placemark.postalCode,
      placemark.country,
    ];
    final address = parts
        .whereType<String>()
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty && !isAdministrativeDivisionName(part))
        .toSet()
        .join(', ');
    return sanitizeFormattedAddress(address) ?? '';
  }

  void _logPosition(Position position) {
    if (!kDebugMode) return;
    debugPrint(
      'Location fix: latitude=${position.latitude}, '
      'longitude=${position.longitude}, accuracy=${position.accuracy}m, '
      'timestamp=${position.timestamp.toIso8601String()}',
    );
  }

  void _logPlacemark(Placemark placemark) {
    if (!kDebugMode) return;
    debugPrint(
      'Location placemark: locality=${placemark.locality}, '
      'subLocality=${placemark.subLocality}, '
      'subAdministrativeArea=${placemark.subAdministrativeArea}, '
      'administrativeArea=${placemark.administrativeArea}, '
      'postalCode=${placemark.postalCode}, country=${placemark.country}',
    );
  }
}
