import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Exception thrown when location service on device is disabled.
class LocationServiceDisabledException implements Exception {
  final String message;
  const LocationServiceDisabledException([this.message = 'Layanan lokasi GPS perangkat nonaktif.']);

  @override
  String toString() => 'LocationServiceDisabledException: $message';
}

/// Exception thrown when location permission is denied.
class LocationPermissionDeniedException implements Exception {
  final String message;
  const LocationPermissionDeniedException([this.message = 'Izin akses lokasi GPS ditolak oleh pengguna.']);

  @override
  String toString() => 'LocationPermissionDeniedException: $message';
}

/// Exception thrown when location permission is permanently denied.
class LocationPermissionPermanentlyDeniedException implements Exception {
  final String message;
  const LocationPermissionPermanentlyDeniedException([
    this.message = 'Izin lokasi GPS ditolak permanen. Buka pengaturan aplikasi untuk memberikan izin.',
  ]);

  @override
  String toString() => 'LocationPermissionPermanentlyDeniedException: $message';
}

/// Geographic coordinates data structure.
class GeoCoordinates {
  final double latitude;
  final double longitude;

  const GeoCoordinates({required this.latitude, required this.longitude});

  @override
  String toString() => 'GeoCoordinates(lat: $latitude, lng: $longitude)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GeoCoordinates &&
          other.latitude == latitude &&
          other.longitude == longitude;

  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode;
}

/// Abstract contract for location service, enabling isolated unit test mocking.
abstract class IGeoLocationService {
  Future<GeoCoordinates> getCurrentLocation();

  double calculateDistanceKm({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  });

  Future<bool> isLocationServiceReady();
}

/// Production implementation of location operations and Haversine distance engine.
class GeoLocationService implements IGeoLocationService {
  // UNESA Campus Central Coordinates Reference (Surabaya)
  static const double campusDefaultLat = -7.3117;
  static const double campusDefaultLng = 112.7275;

  @override
  Future<bool> isLocationServiceReady() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return false;

      final permission = await Geolocator.checkPermission();
      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<GeoCoordinates> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationServiceDisabledException();
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw const LocationPermissionDeniedException();
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationPermissionPermanentlyDeniedException();
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        timeLimit: const Duration(seconds: 8),
      );
      return GeoCoordinates(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (e) {
      debugPrint('[GeoLocationService] GPS hardware timeout, using campus reference fallback: $e');
      return const GeoCoordinates(
        latitude: campusDefaultLat,
        longitude: campusDefaultLng,
      );
    }
  }

  /// Calculates real-time distance in kilometers using the mathematical Haversine formula.
  /// R = 6371.0 km (Earth mean radius)
  @override
  double calculateDistanceKm({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    const double earthRadiusKm = 6371.0;

    final double dLat = _degreesToRadians(endLatitude - startLatitude);
    final double dLon = _degreesToRadians(endLongitude - startLongitude);

    final double lat1 = _degreesToRadians(startLatitude);
    final double lat2 = _degreesToRadians(endLatitude);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.sin(dLon / 2) * math.sin(dLon / 2) * math.cos(lat1) * math.cos(lat2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    final double distance = earthRadiusKm * c;
    // Round to 1 decimal place for clean commuter display
    return double.parse(distance.toStringAsFixed(1));
  }

  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180.0);
  }
}
