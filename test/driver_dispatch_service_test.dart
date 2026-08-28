import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_tow_booking_system/models/driver.dart';
import 'package:mobile_tow_booking_system/services/driver_dispatch_service.dart';

void main() {
  const service = DriverDispatchService();
  const pickupLat = 3.1390;
  const pickupLng = 101.6869;

  Driver driverAt({required String id, required double lat, required double lng}) => Driver(
        id: id,
        workshopUid: 'w1',
        name: 'Driver $id',
        phone: '0100000000',
        plateNumber: 'ABC$id',
        baseLat: lat,
        baseLng: lng,
      );

  group('DriverDispatchService.rankDrivers', () {
    test('returns one TowDriver per input driver', () {
      final drivers = [
        driverAt(id: '1', lat: pickupLat + 0.01, lng: pickupLng),
        driverAt(id: '2', lat: pickupLat + 0.02, lng: pickupLng),
      ];
      final ranked = service.rankDrivers(availableDrivers: drivers, pickupLat: pickupLat, pickupLng: pickupLng);
      expect(ranked, hasLength(2));
    });

    test('sorts by ETA ascending — the closer driver wins', () {
      final near = driverAt(id: 'near', lat: pickupLat + 0.01, lng: pickupLng); // ~1.1km
      final far = driverAt(id: 'far', lat: pickupLat + 0.08, lng: pickupLng); // ~8.9km
      final ranked = service.rankDrivers(
        availableDrivers: [far, near],
        pickupLat: pickupLat,
        pickupLng: pickupLng,
      );
      expect(ranked.first.id, 'near');
      expect(ranked.last.id, 'far');
      expect(ranked.first.etaMinutes, lessThan(ranked.last.etaMinutes));
    });

    test('an empty driver list ranks to an empty list', () {
      final ranked = service.rankDrivers(availableDrivers: [], pickupLat: pickupLat, pickupLng: pickupLng);
      expect(ranked, isEmpty);
    });

    test('carries the driver name and rating through unchanged', () {
      final driver = Driver(
        id: 'd1',
        workshopUid: 'w1',
        name: 'Ah Kow',
        phone: '0123456789',
        plateNumber: 'WXY123',
        rating: 4.8,
        baseLat: pickupLat,
        baseLng: pickupLng,
      );
      final ranked = service.rankDrivers(availableDrivers: [driver], pickupLat: pickupLat, pickupLng: pickupLng);
      expect(ranked.single.name, 'Ah Kow');
      expect(ranked.single.rating, 4.8);
    });
  });
}
