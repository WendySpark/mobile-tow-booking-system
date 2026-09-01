import '../models/booking.dart';

/// Pure aggregation logic behind the Admin analytics dashboard. Kept
/// separate from the widgets so the numbers feeding the charts are
/// unit-testable without touching Firestore.
class BookingAnalyticsService {
  const BookingAnalyticsService();

  double totalRevenue(List<Booking> bookings) =>
      bookings.where((b) => b.paid).fold(0.0, (sum, b) => sum + b.charge);

  double totalOutstanding(List<Booking> bookings) => bookings
      .where((b) => b.isOutstanding)
      .fold(0.0, (sum, b) => sum + b.charge);

  int freeTowCount(List<Booking> bookings) =>
      bookings.where((b) => b.charge == 0).length;

  int paidTowCount(List<Booking> bookings) =>
      bookings.where((b) => b.charge > 0).length;

  /// Bookings created per calendar day for the last [days] days, oldest
  /// first. Always returns exactly [days] entries (0 for days with none),
  /// keyed by the date at midnight, so the chart x-axis stays stable.
  List<MapEntry<DateTime, int>> bookingsPerDay(
    List<Booking> bookings, {
    int days = 7,
    DateTime? now,
  }) {
    final today = _dateOnly(now ?? DateTime.now());
    final counts = <DateTime, int>{
      for (int i = days - 1; i >= 0; i--) today.subtract(Duration(days: i)): 0,
    };
    for (final b in bookings) {
      final day = _dateOnly(b.createdAt);
      if (counts.containsKey(day)) counts[day] = counts[day]! + 1;
    }
    return counts.entries.toList();
  }

  /// Booking count per repair center id, descending by count.
  List<MapEntry<String, int>> bookingsByRepairCenter(List<Booking> bookings) {
    final counts = <String, int>{};
    for (final b in bookings) {
      counts[b.repairCenterId] = (counts[b.repairCenterId] ?? 0) + 1;
    }
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
