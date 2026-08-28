/// Result of an eligibility check + charge calculation for a prospective
/// tow booking, before it is confirmed.
class TowQuote {
  final double totalDistanceKm;
  final double freeDistanceKm;
  final double chargeableDistanceKm;
  final double ratePerKmAfterFree;
  final double charge;
  final bool eligibleForFreeTow;
  final String? ineligibilityReason;

  const TowQuote({
    required this.totalDistanceKm,
    required this.freeDistanceKm,
    required this.chargeableDistanceKm,
    required this.ratePerKmAfterFree,
    required this.charge,
    required this.eligibleForFreeTow,
    this.ineligibilityReason,
  });

  bool get isFullyFree => charge == 0 && ineligibilityReason == null;
}
