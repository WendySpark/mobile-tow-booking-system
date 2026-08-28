class Vehicle {
  final String id;
  final String ownerUid;
  final String plateNumber;
  final String make;
  final String model;
  final String? policyId;

  const Vehicle({
    required this.id,
    required this.ownerUid,
    required this.plateNumber,
    required this.make,
    required this.model,
    this.policyId,
  });

  factory Vehicle.fromMap(String id, Map<String, dynamic> map) => Vehicle(
        id: id,
        ownerUid: map['ownerUid'] as String? ?? '',
        plateNumber: map['plateNumber'] as String? ?? '',
        make: map['make'] as String? ?? '',
        model: map['model'] as String? ?? '',
        policyId: map['policyId'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'ownerUid': ownerUid,
        'plateNumber': plateNumber,
        'make': make,
        'model': model,
        'policyId': policyId,
      };

  String get displayName => '$make $model ($plateNumber)';
}
