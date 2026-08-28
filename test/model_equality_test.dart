import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_tow_booking_system/models/repair_center.dart';
import 'package:mobile_tow_booking_system/models/vehicle.dart';

/// Regression test for a real bug hit during manual testing: screens pass
/// Vehicle/RepairCenter objects straight from a Firestore StreamBuilder into
/// a DropdownButtonFormField. Firestore emits a fresh object instance on
/// every snapshot, so without id-based equality the dropdown's selected
/// value stops matching any item in the rebuilt list and Flutter throws
/// "There should be exactly one item with [DropdownButton]'s value".
void main() {
  group('Vehicle equality', () {
    test('two instances with the same id are equal even with different object identity', () {
      const a = Vehicle(id: 'v1', ownerUid: 'u1', plateNumber: 'ABC1234', make: 'Toyota', model: 'Vios');
      const b = Vehicle(id: 'v1', ownerUid: 'u1', plateNumber: 'ABC1234', make: 'Toyota', model: 'Vios');

      expect(a == b, isTrue);
      expect(a.hashCode, b.hashCode);
      expect([b].contains(a), isTrue);
    });

    test('instances with different ids are not equal', () {
      const a = Vehicle(id: 'v1', ownerUid: 'u1', plateNumber: 'ABC1234', make: 'Toyota', model: 'Vios');
      const b = Vehicle(id: 'v2', ownerUid: 'u1', plateNumber: 'ABC1234', make: 'Toyota', model: 'Vios');

      expect(a == b, isFalse);
    });
  });

  group('RepairCenter equality', () {
    test('two instances with the same id are equal even with different object identity', () {
      const a = RepairCenter(id: 'c1', name: 'Central', address: 'KL', latitude: 1, longitude: 1);
      const b = RepairCenter(id: 'c1', name: 'Central', address: 'KL', latitude: 1, longitude: 1);

      expect(a == b, isTrue);
      expect(a.hashCode, b.hashCode);
      expect([b].contains(a), isTrue);
    });

    test('instances with different ids are not equal', () {
      const a = RepairCenter(id: 'c1', name: 'Central', address: 'KL', latitude: 1, longitude: 1);
      const b = RepairCenter(id: 'c2', name: 'Central', address: 'KL', latitude: 1, longitude: 1);

      expect(a == b, isFalse);
    });
  });
}
