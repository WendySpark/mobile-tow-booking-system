import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_tow_booking_system/models/booking.dart';
import 'package:mobile_tow_booking_system/models/booking_status.dart';
import 'package:mobile_tow_booking_system/services/payment_gate_service.dart';

void main() {
  const gate = PaymentGateService();

  Booking bookingWith({required double charge, required bool paid}) => Booking(
        id: 'b',
        userUid: 'u',
        vehicleId: 'v',
        repairCenterId: 'c',
        pickupLat: 0,
        pickupLng: 0,
        distanceKm: 10,
        freeDistanceKm: 5,
        chargeableDistanceKm: 5,
        charge: charge,
        status: BookingStatus.completed,
        createdAt: DateTime(2026, 1, 1),
        truckStartLat: 0,
        truckStartLng: 0,
        paid: paid,
      );

  group('PaymentGateService', () {
    test('a free booking never counts as outstanding', () {
      final bookings = [bookingWith(charge: 0, paid: false)];
      expect(gate.hasOutstandingPayment(bookings), isFalse);
    });

    test('a chargeable unpaid booking blocks new bookings', () {
      final bookings = [bookingWith(charge: 20, paid: false)];
      expect(gate.hasOutstandingPayment(bookings), isTrue);
      expect(gate.outstandingBookings(bookings), hasLength(1));
      expect(gate.totalOutstanding(bookings), 20);
    });

    test('a chargeable but paid booking does not block', () {
      final bookings = [bookingWith(charge: 20, paid: true)];
      expect(gate.hasOutstandingPayment(bookings), isFalse);
    });

    test('sums multiple outstanding bookings', () {
      final bookings = [
        bookingWith(charge: 20, paid: false),
        bookingWith(charge: 15, paid: true),
        bookingWith(charge: 5, paid: false),
      ];
      expect(gate.hasOutstandingPayment(bookings), isTrue);
      expect(gate.outstandingBookings(bookings), hasLength(2));
      expect(gate.totalOutstanding(bookings), 25);
    });
  });
}
