/// ETA-ranked view of a real Driver for a specific pickup point — computed
/// by DriverDispatchService, not persisted itself. Lets the Request Tow
/// screen show "2.0 km away · ETA 4 min" without coupling the Driver model
/// to any one booking's pickup location.
class TowDriver {
  final String id;
  final String name;
  final double rating;
  final double distanceKm;
  final double baseLat;
  final double baseLng;

  const TowDriver({
    required this.id,
    required this.name,
    required this.rating,
    required this.distanceKm,
    required this.baseLat,
    required this.baseLng,
  });

  /// Simulated average tow-truck speed accounting for city traffic.
  static const double _averageSpeedKmh = 28.0;

  double get etaMinutes => (distanceKm / _averageSpeedKmh) * 60;
}
