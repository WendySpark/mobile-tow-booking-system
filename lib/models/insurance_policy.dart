enum PolicyStatus { active, expired, cancelled }

extension PolicyStatusX on PolicyStatus {
  String get value => name;

  static PolicyStatus fromValue(String value) => PolicyStatus.values.firstWhere(
        (s) => s.value == value,
        orElse: () => PolicyStatus.active,
      );
}

/// An insurance policy created by an Insurance Agent, linked to a vehicle.
/// [freeTowRadiusKm] is the distance the towing service is free for; any
/// distance beyond that to the repair center is charged at [ratePerKmAfterFree].
class InsurancePolicy {
  final String id;
  final String policyNumber;
  final String agentUid;
  final String? vehicleId;
  final double freeTowRadiusKm;
  final double ratePerKmAfterFree;
  final PolicyStatus status;
  final DateTime expiryDate;

  const InsurancePolicy({
    required this.id,
    required this.policyNumber,
    required this.agentUid,
    this.vehicleId,
    required this.freeTowRadiusKm,
    required this.ratePerKmAfterFree,
    required this.status,
    required this.expiryDate,
  });

  bool get isValid => status == PolicyStatus.active && expiryDate.isAfter(DateTime.now());

  factory InsurancePolicy.fromMap(String id, Map<String, dynamic> map) => InsurancePolicy(
        id: id,
        policyNumber: map['policyNumber'] as String? ?? '',
        agentUid: map['agentUid'] as String? ?? '',
        vehicleId: map['vehicleId'] as String?,
        freeTowRadiusKm: (map['freeTowRadiusKm'] as num?)?.toDouble() ?? 0,
        ratePerKmAfterFree: (map['ratePerKmAfterFree'] as num?)?.toDouble() ?? 0,
        status: PolicyStatusX.fromValue(map['status'] as String? ?? 'active'),
        expiryDate: DateTime.parse(map['expiryDate'] as String),
      );

  Map<String, dynamic> toMap() => {
        'policyNumber': policyNumber,
        'agentUid': agentUid,
        'vehicleId': vehicleId,
        'freeTowRadiusKm': freeTowRadiusKm,
        'ratePerKmAfterFree': ratePerKmAfterFree,
        'status': status.value,
        'expiryDate': expiryDate.toIso8601String(),
      };
}
