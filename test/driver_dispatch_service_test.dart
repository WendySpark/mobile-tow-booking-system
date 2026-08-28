import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_tow_booking_system/services/driver_dispatch_service.dart';

void main() {
  const service = DriverDispatchService();

  group('DriverDispatchService.findNearbyDrivers', () {
    test('returns the requested number of drivers', () {
      final drivers = service.findNearbyDrivers(
        pickupLat: 3.1390,
        pickupLng: 101.6869,
        count: 3,
        random: Random(1),
      );
      expect(drivers, hasLength(3));
    });

    test('sorts drivers by ETA ascending (closest first)', () {
      final drivers = service.findNearbyDrivers(
        pickupLat: 3.1390,
        pickupLng: 101.6869,
        count: 4,
        random: Random(42),
      );
      for (var i = 1; i < drivers.length; i++) {
        expect(drivers[i].etaMinutes, greaterThanOrEqualTo(drivers[i - 1].etaMinutes));
      }
    });

    test('every driver is within the simulated dispatch radius', () {
      final drivers = service.findNearbyDrivers(
        pickupLat: 3.1390,
        pickupLng: 101.6869,
        count: 5,
        random: Random(7),
      );
      for (final d in drivers) {
        expect(d.distanceKm, greaterThan(0));
        expect(d.distanceKm, lessThanOrEqualTo(9.5));
      }
    });
  });
}
