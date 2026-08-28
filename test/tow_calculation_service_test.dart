import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_tow_booking_system/models/insurance_policy.dart';
import 'package:mobile_tow_booking_system/services/tow_calculation_service.dart';

void main() {
  const service = TowCalculationService();

  // Kuala Lumpur city centre.
  const pickupLat = 3.1390;
  const pickupLng = 101.6869;

  InsurancePolicy policyWith({
    required double freeTowRadiusKm,
    required double ratePerKmAfterFree,
    PolicyStatus status = PolicyStatus.active,
    DateTime? expiryDate,
  }) =>
      InsurancePolicy(
        id: 'p1',
        policyNumber: 'POL-001',
        agentUid: 'agent1',
        vehicleId: 'v1',
        freeTowRadiusKm: freeTowRadiusKm,
        ratePerKmAfterFree: ratePerKmAfterFree,
        status: status,
        expiryDate: expiryDate ?? DateTime.now().add(const Duration(days: 30)),
      );

  group('TowCalculationService.calculateQuote', () {
    test('distance entirely within free radius is fully free', () {
      // A center ~1km away, free radius of 5km.
      final quote = service.calculateQuote(
        pickupLat: pickupLat,
        pickupLng: pickupLng,
        centerLat: pickupLat + 0.009, // ~1km north
        centerLng: pickupLng,
        policy: policyWith(freeTowRadiusKm: 5, ratePerKmAfterFree: 2),
        defaultRatePerKm: 3,
      );

      expect(quote.eligibleForFreeTow, isTrue);
      expect(quote.chargeableDistanceKm, 0);
      expect(quote.charge, 0);
      expect(quote.isFullyFree, isTrue);
    });

    test('distance exactly at the free radius charges nothing', () {
      const freeRadius = 5.0;
      // Construct a center whose haversine distance is (very close to) exactly freeRadius.
      // 1 degree of latitude is ~111.32km, so offset = freeRadius / 111.32.
      final latOffset = freeRadius / 111.32;
      final quote = service.calculateQuote(
        pickupLat: pickupLat,
        pickupLng: pickupLng,
        centerLat: pickupLat + latOffset,
        centerLng: pickupLng,
        policy: policyWith(freeTowRadiusKm: freeRadius, ratePerKmAfterFree: 2),
        defaultRatePerKm: 3,
      );

      expect(quote.chargeableDistanceKm, closeTo(0, 0.05));
      expect(quote.charge, closeTo(0, 0.1));
    });

    test('distance beyond the free radius charges only the excess', () {
      // Center far enough away (~20km) to clearly exceed a 5km free radius.
      final quote = service.calculateQuote(
        pickupLat: pickupLat,
        pickupLng: pickupLng,
        centerLat: pickupLat + 0.18, // ~20km north
        centerLng: pickupLng,
        policy: policyWith(freeTowRadiusKm: 5, ratePerKmAfterFree: 2),
        defaultRatePerKm: 3,
      );

      expect(quote.eligibleForFreeTow, isTrue);
      expect(quote.freeDistanceKm, 5);
      expect(quote.chargeableDistanceKm, closeTo(15, 0.5));
      expect(quote.charge, closeTo(30, 1));
    });

    test('missing policy falls back to the default rate for the full distance', () {
      final quote = service.calculateQuote(
        pickupLat: pickupLat,
        pickupLng: pickupLng,
        centerLat: pickupLat + 0.09, // ~10km
        centerLng: pickupLng,
        policy: null,
        defaultRatePerKm: 3,
      );

      expect(quote.eligibleForFreeTow, isFalse);
      expect(quote.ineligibilityReason, isNotNull);
      expect(quote.freeDistanceKm, 0);
      expect(quote.chargeableDistanceKm, closeTo(quote.totalDistanceKm, 0.01));
      expect(quote.charge, closeTo(quote.totalDistanceKm * 3, 0.1));
    });

    test('expired policy is treated as ineligible for free towing', () {
      final quote = service.calculateQuote(
        pickupLat: pickupLat,
        pickupLng: pickupLng,
        centerLat: pickupLat + 0.09,
        centerLng: pickupLng,
        policy: policyWith(
          freeTowRadiusKm: 5,
          ratePerKmAfterFree: 2,
          expiryDate: DateTime.now().subtract(const Duration(days: 1)),
        ),
        defaultRatePerKm: 3,
      );

      expect(quote.eligibleForFreeTow, isFalse);
      expect(quote.ineligibilityReason, contains('expired'));
    });

    test('cancelled policy is treated as ineligible for free towing', () {
      final quote = service.calculateQuote(
        pickupLat: pickupLat,
        pickupLng: pickupLng,
        centerLat: pickupLat + 0.09,
        centerLng: pickupLng,
        policy: policyWith(
          freeTowRadiusKm: 5,
          ratePerKmAfterFree: 2,
          status: PolicyStatus.cancelled,
        ),
        defaultRatePerKm: 3,
      );

      expect(quote.eligibleForFreeTow, isFalse);
      expect(quote.ineligibilityReason, contains('cancelled'));
    });
  });
}
