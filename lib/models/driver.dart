import 'driver_status.dart';

/// A tow truck driver employed by a Workshop. Replaces the earlier
/// fully-simulated "nearby drivers" with real records a workshop manages,
/// so ETA ranking (see DriverDispatchService) works off actual base
/// locations and availability.
class Driver {
  final String id;
  final String workshopUid;
  final String name;
  final String phone;
  final String plateNumber;
  final double rating;
  final DriverStatus status;
  final double baseLat;
  final double baseLng;

  const Driver({
    required this.id,
    required this.workshopUid,
    required this.name,
    required this.phone,
    required this.plateNumber,
    this.rating = 4.5,
    this.status = DriverStatus.available,
    required this.baseLat,
    required this.baseLng,
  });

  factory Driver.fromMap(String id, Map<String, dynamic> map) => Driver(
    id: id,
    workshopUid: map['workshopUid'] as String? ?? '',
    name: map['name'] as String? ?? '',
    phone: map['phone'] as String? ?? '',
    plateNumber: map['plateNumber'] as String? ?? '',
    rating: (map['rating'] as num?)?.toDouble() ?? 4.5,
    status: DriverStatusX.fromValue(map['status'] as String? ?? 'available'),
    baseLat: (map['baseLat'] as num?)?.toDouble() ?? 0,
    baseLng: (map['baseLng'] as num?)?.toDouble() ?? 0,
  );

  Map<String, dynamic> toMap() => {
    'workshopUid': workshopUid,
    'name': name,
    'phone': phone,
    'plateNumber': plateNumber,
    'rating': rating,
    'status': status.value,
    'baseLat': baseLat,
    'baseLng': baseLng,
  };

  @override
  bool operator ==(Object other) => other is Driver && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
