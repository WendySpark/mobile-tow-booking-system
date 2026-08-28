import '../models/driver.dart';
import '../models/tow_driver.dart';
import '../utils/distance_utils.dart';

/// Ranks a Workshop's real, available drivers by ETA to a pickup point —
/// the "comparison of delivery time between available drivers" pattern,
/// now sourced from drivers a Workshop actually manages (see
/// ManageDriversScreen) rather than simulated candidates.
class DriverDispatchService {
  const DriverDispatchService();

  List<TowDriver> rankDrivers({
    required List<Driver> availableDrivers,
    required double pickupLat,
    required double pickupLng,
  }) {
    final ranked = availableDrivers.map((d) {
      final distanceKm = haversineDistanceKm(
        lat1: pickupLat,
        lng1: pickupLng,
        lat2: d.baseLat,
        lng2: d.baseLng,
      );
      return TowDriver(
        id: d.id,
        name: d.name,
        rating: d.rating,
        distanceKm: distanceKm,
        baseLat: d.baseLat,
        baseLng: d.baseLng,
      );
    }).toList();

    ranked.sort((a, b) => a.etaMinutes.compareTo(b.etaMinutes));
    return ranked;
  }
}
