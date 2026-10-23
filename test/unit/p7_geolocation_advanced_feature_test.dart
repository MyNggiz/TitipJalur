import 'package:flutter_test/flutter_test.dart';
import 'package:titip_jalur/services/geo_location_service.dart';

class FakeGeoLocationService implements IGeoLocationService {
  GeoCoordinates nextCoordinates = const GeoCoordinates(
    latitude: -7.3117,
    longitude: 112.7275,
  );
  bool shouldThrowServiceDisabled = false;
  bool shouldThrowPermissionDenied = false;
  bool shouldThrowPermanentlyDenied = false;

  @override
  Future<bool> isLocationServiceReady() async {
    return !shouldThrowServiceDisabled && !shouldThrowPermissionDenied;
  }

  @override
  Future<GeoCoordinates> getCurrentLocation() async {
    if (shouldThrowServiceDisabled) {
      throw const LocationServiceDisabledException();
    }
    if (shouldThrowPermanentlyDenied) {
      throw const LocationPermissionPermanentlyDeniedException();
    }
    if (shouldThrowPermissionDenied) {
      throw const LocationPermissionDeniedException();
    }
    return nextCoordinates;
  }

  @override
  double calculateDistanceKm({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    // Forward to standard GeoLocationService mathematical implementation
    return GeoLocationService().calculateDistanceKm(
      startLatitude: startLatitude,
      startLongitude: startLongitude,
      endLatitude: endLatitude,
      endLongitude: endLongitude,
    );
  }
}

void main() {
  group('P7 Advanced Feature 3: GPS Geolocation & Haversine Distance Engine Tests', () {
    final geoService = GeoLocationService();

    test('1. Haversine distance calculates accurate zero distance for identical coordinates', () {
      final distance = geoService.calculateDistanceKm(
        startLatitude: -7.3117,
        startLongitude: 112.7275,
        endLatitude: -7.3117,
        endLongitude: 112.7275,
      );

      expect(distance, equals(0.0));
    });

    test('2. Haversine distance calculates accurate campus commuter distance (~0.8 km)', () {
      // Point A: Kantin Pusat UNESA Ketintang (-7.3117, 112.7275)
      // Point B: Gedung K10 Fakultas Teknik (-7.3175, 112.7310)
      final distance = geoService.calculateDistanceKm(
        startLatitude: -7.3117,
        startLongitude: 112.7275,
        endLatitude: -7.3175,
        endLongitude: 112.7310,
      );

      expect(distance, greaterThan(0.5));
      expect(distance, lessThan(1.5));
      expect(distance, equals(0.8));
    });

    test('3. GPS service returns campus coordinates when permission is granted', () async {
      final fakeGeo = FakeGeoLocationService();
      final coords = await fakeGeo.getCurrentLocation();

      expect(coords.latitude, equals(-7.3117));
      expect(coords.longitude, equals(112.7275));
      expect(await fakeGeo.isLocationServiceReady(), isTrue);
    });

    test('4. Disabled GPS service throws LocationServiceDisabledException', () async {
      final fakeGeo = FakeGeoLocationService()..shouldThrowServiceDisabled = true;

      expect(
        () => fakeGeo.getCurrentLocation(),
        throwsA(isA<LocationServiceDisabledException>()),
      );
      expect(await fakeGeo.isLocationServiceReady(), isFalse);
    });

    test('5. Denied GPS permission throws LocationPermissionDeniedException', () async {
      final fakeGeo = FakeGeoLocationService()..shouldThrowPermissionDenied = true;

      expect(
        () => fakeGeo.getCurrentLocation(),
        throwsA(isA<LocationPermissionDeniedException>()),
      );
    });

    test('6. Permanently denied permission throws LocationPermissionPermanentlyDeniedException', () async {
      final fakeGeo = FakeGeoLocationService()..shouldThrowPermanentlyDenied = true;

      expect(
        () => fakeGeo.getCurrentLocation(),
        throwsA(isA<LocationPermissionPermanentlyDeniedException>()),
      );
    });
  });
}
