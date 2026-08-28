import '../models/booking.dart';

/// Enforces the "clear all outstanding payments before a new tow can be
/// approved" rule. Kept as a pure function over a list of bookings so the
/// gating logic is unit-testable without a Firestore round trip.
class PaymentGateService {
  const PaymentGateService();

  bool hasOutstandingPayment(List<Booking> bookings) =>
      bookings.any((b) => b.isOutstanding);

  List<Booking> outstandingBookings(List<Booking> bookings) =>
      bookings.where((b) => b.isOutstanding).toList();

  double totalOutstanding(List<Booking> bookings) =>
      outstandingBookings(bookings).fold(0.0, (sum, b) => sum + b.charge);
}
