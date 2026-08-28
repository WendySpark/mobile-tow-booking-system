/// Fallback rate ($/km) used when a booking has no valid linked insurance
/// policy. Overridable by Admin via the Settings screen (see
/// FirestoreService.setDefaultRatePerKm).
const double kDefaultRatePerKm = 5.0;

/// How long the simulated tow truck takes to "arrive" after a booking is
/// confirmed. Purely a demo/prototype device — see plan's tracking note.
const Duration kSimulatedTowDuration = Duration(seconds: 75);
