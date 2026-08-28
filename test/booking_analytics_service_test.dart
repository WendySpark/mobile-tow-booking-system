import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_tow_booking_system/models/booking.dart';
import 'package:mobile_tow_booking_system/models/booking_status.dart';
import 'package:mobile_tow_booking_system/services/booking_analytics_service.dart';

void main() {
  const analytics = BookingAnalyticsService();

  Booking bookingWith({
    required double charge,
    required bool paid,
    DateTime? createdAt,
    String repairCenterId = 'center-1',
  }) =>
      Booking(
        id: 'b',
        userUid: 'u',
        vehicleId: 'v',
        repairCenterId: repairCenterId,
        pickupLat: 0,
        pickupLng: 0,
        distanceKm: 10,
        freeDistanceKm: 5,
        chargeableDistanceKm: 5,
        charge: charge,
        status: BookingStatus.completed,
        createdAt: createdAt ?? DateTime(2026, 1, 1),
        truckStartLat: 0,
        truckStartLng: 0,
        paid: paid,
      );

  group('BookingAnalyticsService', () {
    test('totalRevenue sums only paid bookings', () {
      final bookings = [
        bookingWith(charge: 20, paid: true),
        bookingWith(charge: 15, paid: false),
        bookingWith(charge: 0, paid: true),
      ];
      expect(analytics.totalRevenue(bookings), 20);
    });

    test('totalOutstanding sums only unpaid chargeable bookings', () {
      final bookings = [
        bookingWith(charge: 20, paid: true),
        bookingWith(charge: 15, paid: false),
        bookingWith(charge: 0, paid: false),
      ];
      expect(analytics.totalOutstanding(bookings), 15);
    });

    test('freeTowCount and paidTowCount partition by charge', () {
      final bookings = [
        bookingWith(charge: 0, paid: true),
        bookingWith(charge: 0, paid: true),
        bookingWith(charge: 10, paid: false),
      ];
      expect(analytics.freeTowCount(bookings), 2);
      expect(analytics.paidTowCount(bookings), 1);
    });

    test('bookingsPerDay always returns exactly `days` entries, zero-filled', () {
      final now = DateTime(2026, 1, 10);
      final bookings = [bookingWith(charge: 0, paid: true, createdAt: DateTime(2026, 1, 10, 9))];
      final result = analytics.bookingsPerDay(bookings, days: 7, now: now);

      expect(result, hasLength(7));
      expect(result.last.key, DateTime(2026, 1, 10));
      expect(result.last.value, 1);
      expect(result.first.key, DateTime(2026, 1, 4));
      expect(result.first.value, 0);
    });

    test('bookingsByRepairCenter counts and sorts descending', () {
      final bookings = [
        bookingWith(charge: 0, paid: true, repairCenterId: 'a'),
        bookingWith(charge: 0, paid: true, repairCenterId: 'a'),
        bookingWith(charge: 0, paid: true, repairCenterId: 'b'),
      ];
      final result = analytics.bookingsByRepairCenter(bookings);
      expect(result.first.key, 'a');
      expect(result.first.value, 2);
      expect(result.last.key, 'b');
      expect(result.last.value, 1);
    });
  });
}
