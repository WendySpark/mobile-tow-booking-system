import 'booking_status.dart';

class Booking {
  final String id;
  final String userUid;
  final String vehicleId;
  final String? policyId;
  final String repairCenterId;
  final double pickupLat;
  final double pickupLng;
  final double distanceKm;
  final double freeDistanceKm;
  final double chargeableDistanceKm;
  final double charge;
  final BookingStatus status;
  final DateTime createdAt;
  final double truckStartLat;
  final double truckStartLng;
  final String? driverId;
  final String? driverName;
  final double? driverEtaMinutes;

  /// A booking with charge == 0 is considered paid automatically (nothing
  /// owed). Bookings with charge > 0 start unpaid until the user settles
  /// them from the Payments tab.
  final bool paid;
  final DateTime? paidAt;
  final String? paymentMethod;

  const Booking({
    required this.id,
    required this.userUid,
    required this.vehicleId,
    this.policyId,
    required this.repairCenterId,
    required this.pickupLat,
    required this.pickupLng,
    required this.distanceKm,
    required this.freeDistanceKm,
    required this.chargeableDistanceKm,
    required this.charge,
    required this.status,
    required this.createdAt,
    required this.truckStartLat,
    required this.truckStartLng,
    this.driverId,
    this.driverName,
    this.driverEtaMinutes,
    this.paid = false,
    this.paidAt,
    this.paymentMethod,
  });

  bool get requiresPayment => charge > 0;
  bool get isOutstanding => requiresPayment && !paid;

  factory Booking.fromMap(String id, Map<String, dynamic> map) => Booking(
    id: id,
    userUid: map['userUid'] as String? ?? '',
    vehicleId: map['vehicleId'] as String? ?? '',
    policyId: map['policyId'] as String?,
    repairCenterId: map['repairCenterId'] as String? ?? '',
    pickupLat: (map['pickupLat'] as num?)?.toDouble() ?? 0,
    pickupLng: (map['pickupLng'] as num?)?.toDouble() ?? 0,
    distanceKm: (map['distanceKm'] as num?)?.toDouble() ?? 0,
    freeDistanceKm: (map['freeDistanceKm'] as num?)?.toDouble() ?? 0,
    chargeableDistanceKm:
        (map['chargeableDistanceKm'] as num?)?.toDouble() ?? 0,
    charge: (map['charge'] as num?)?.toDouble() ?? 0,
    status: BookingStatusX.fromValue(map['status'] as String? ?? 'pending'),
    createdAt: DateTime.parse(map['createdAt'] as String),
    truckStartLat: (map['truckStartLat'] as num?)?.toDouble() ?? 0,
    truckStartLng: (map['truckStartLng'] as num?)?.toDouble() ?? 0,
    driverId: map['driverId'] as String?,
    driverName: map['driverName'] as String?,
    driverEtaMinutes: (map['driverEtaMinutes'] as num?)?.toDouble(),
    paid:
        map['paid'] as bool? ?? ((map['charge'] as num?)?.toDouble() ?? 0) == 0,
    paidAt: map['paidAt'] != null
        ? DateTime.parse(map['paidAt'] as String)
        : null,
    paymentMethod: map['paymentMethod'] as String?,
  );

  Map<String, dynamic> toMap() => {
    'userUid': userUid,
    'vehicleId': vehicleId,
    'policyId': policyId,
    'repairCenterId': repairCenterId,
    'pickupLat': pickupLat,
    'pickupLng': pickupLng,
    'distanceKm': distanceKm,
    'freeDistanceKm': freeDistanceKm,
    'chargeableDistanceKm': chargeableDistanceKm,
    'charge': charge,
    'status': status.value,
    'createdAt': createdAt.toIso8601String(),
    'truckStartLat': truckStartLat,
    'truckStartLng': truckStartLng,
    'driverId': driverId,
    'driverName': driverName,
    'driverEtaMinutes': driverEtaMinutes,
    'paid': paid,
    'paidAt': paidAt?.toIso8601String(),
    'paymentMethod': paymentMethod,
  };

  Booking copyWith({
    String? id,
    BookingStatus? status,
    bool? paid,
    DateTime? paidAt,
    String? paymentMethod,
  }) => Booking(
    id: id ?? this.id,
    userUid: userUid,
    vehicleId: vehicleId,
    policyId: policyId,
    repairCenterId: repairCenterId,
    pickupLat: pickupLat,
    pickupLng: pickupLng,
    distanceKm: distanceKm,
    freeDistanceKm: freeDistanceKm,
    chargeableDistanceKm: chargeableDistanceKm,
    charge: charge,
    status: status ?? this.status,
    createdAt: createdAt,
    truckStartLat: truckStartLat,
    truckStartLng: truckStartLng,
    driverId: driverId,
    driverName: driverName,
    driverEtaMinutes: driverEtaMinutes,
    paid: paid ?? this.paid,
    paidAt: paidAt ?? this.paidAt,
    paymentMethod: paymentMethod ?? this.paymentMethod,
  );
}
