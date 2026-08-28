import 'dart:math';

import '../models/tow_driver.dart';
import '../utils/distance_utils.dart';

/// Generates simulated nearby tow-truck driver candidates for a pickup
/// point, sorted by ETA (soonest first). Pure/deterministic given a [Random]
/// seed, so the "closest driver wins" ordering is unit-testable without
/// touching Firestore or GPS.
class DriverDispatchService {
  const DriverDispatchService();

  static const _driverNames = ['Ahmad', 'Ravi', 'Wei Ming', 'Farah', 'Ganesh', 'Siti'];

  List<TowDriver> findNearbyDrivers({
    required double pickupLat,
    required double pickupLng,
    int count = 3,
    Random? random,
  }) {
    final rng = random ?? Random();
    final shuffledNames = [..._driverNames]..shuffle(rng);

    return List.generate(count, (i) {
      // Random bearing/offset within ~1-9km of the pickup point.
      final bearing = rng.nextDouble() * 2 * pi;
      final offsetKm = 1 + rng.nextDouble() * 8;
      final latOffset = (offsetKm / 111.32) * cos(bearing);
      final lngOffset = (offsetKm / (111.32 * cos(pickupLat * pi / 180))) * sin(bearing);

      final startLat = pickupLat + latOffset;
      final startLng = pickupLng + lngOffset;
      final distanceKm = haversineDistanceKm(
        lat1: pickupLat,
        lng1: pickupLng,
        lat2: startLat,
        lng2: startLng,
      );

      return TowDriver(
        id: 'driver-$i',
        name: shuffledNames[i % shuffledNames.length],
        rating: 3.8 + rng.nextDouble() * 1.2,
        distanceKm: distanceKm,
        startLat: startLat,
        startLng: startLng,
      );
    })
      ..sort((a, b) => a.etaMinutes.compareTo(b.etaMinutes));
  }
}
