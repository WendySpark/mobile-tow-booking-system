import '../models/insurance_policy.dart';
import '../models/tow_quote.dart';
import '../utils/distance_utils.dart';

/// Pure calculation logic for the "free towing service eligibility check"
/// and "tow charge based on distance after eligible towing distance" key
/// processes. Kept free of Firebase/Flutter so it can be unit tested in
/// isolation.
class TowCalculationService {
  const TowCalculationService();

  TowQuote calculateQuote({
    required double pickupLat,
    required double pickupLng,
    required double centerLat,
    required double centerLng,
    required InsurancePolicy? policy,
    required double defaultRatePerKm,
  }) {
    final distanceKm = haversineDistanceKm(
      lat1: pickupLat,
      lng1: pickupLng,
      lat2: centerLat,
      lng2: centerLng,
    );

    if (policy == null || !policy.isValid) {
      final reason = policy == null
          ? 'No insurance policy linked to this vehicle.'
          : policy.status != PolicyStatus.active
              ? 'Policy is ${policy.status.value}.'
              : 'Policy has expired.';
      return TowQuote(
        totalDistanceKm: distanceKm,
        freeDistanceKm: 0,
        chargeableDistanceKm: distanceKm,
        ratePerKmAfterFree: defaultRatePerKm,
        charge: _round2(distanceKm * defaultRatePerKm),
        eligibleForFreeTow: false,
        ineligibilityReason: reason,
      );
    }

    final freeDistanceKm = distanceKm < policy.freeTowRadiusKm ? distanceKm : policy.freeTowRadiusKm;
    final chargeableDistanceKm = distanceKm > policy.freeTowRadiusKm ? distanceKm - policy.freeTowRadiusKm : 0.0;

    return TowQuote(
      totalDistanceKm: distanceKm,
      freeDistanceKm: freeDistanceKm,
      chargeableDistanceKm: chargeableDistanceKm,
      ratePerKmAfterFree: policy.ratePerKmAfterFree,
      charge: _round2(chargeableDistanceKm * policy.ratePerKmAfterFree),
      eligibleForFreeTow: true,
    );
  }

  double _round2(double value) => (value * 100).round() / 100;
}
