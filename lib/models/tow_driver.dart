/// A simulated tow driver candidate offered to the user during booking, so
/// they can compare ETA before confirming — mirrors the "comparison of
/// delivery time between available drivers" pattern from the brief's sibling
/// petrol-delivery system, adapted for towing. Not persisted on its own;
/// the chosen driver's name/ETA/start point are copied onto the Booking.
class TowDriver {
  final String id;
  final String name;
  final double rating;
  final double distanceKm;
  final double startLat;
  final double startLng;

  const TowDriver({
    required this.id,
    required this.name,
    required this.rating,
    required this.distanceKm,
    required this.startLat,
    required this.startLng,
  });

  /// Simulated average tow-truck speed accounting for city traffic.
  static const double _averageSpeedKmh = 28.0;

  double get etaMinutes => (distanceKm / _averageSpeedKmh) * 60;
}
