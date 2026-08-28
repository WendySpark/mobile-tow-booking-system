import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';
import '../models/booking.dart';
import '../models/booking_status.dart';
import '../models/insurance_policy.dart';
import '../models/repair_center.dart';
import '../models/vehicle.dart';

/// Thin Firestore data-access layer shared by all three roles.
/// Screens talk to this instead of `cloud_firestore` directly.
class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore}) : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  // ---- Users ----------------------------------------------------------
  Stream<List<AppUser>> streamUsers() => _db
      .collection('users')
      .snapshots()
      .map((s) => s.docs.map((d) => AppUser.fromMap(d.id, d.data())).toList());

  // ---- Vehicles ---------------------------------------------------------
  Future<String> addVehicle(Vehicle vehicle) async {
    final doc = await _db.collection('vehicles').add(vehicle.toMap());
    return doc.id;
  }

  Stream<List<Vehicle>> streamVehiclesForOwner(String ownerUid) => _db
      .collection('vehicles')
      .where('ownerUid', isEqualTo: ownerUid)
      .snapshots()
      .map((s) => s.docs.map((d) => Vehicle.fromMap(d.id, d.data())).toList());

  Future<Vehicle?> getVehicle(String id) async {
    final doc = await _db.collection('vehicles').doc(id).get();
    return doc.exists ? Vehicle.fromMap(doc.id, doc.data()!) : null;
  }

  // ---- Insurance policies -----------------------------------------------
  Future<String> createPolicy(InsurancePolicy policy) async {
    final doc = await _db.collection('policies').add(policy.toMap());
    return doc.id;
  }

  Future<void> updatePolicy(InsurancePolicy policy) =>
      _db.collection('policies').doc(policy.id).update(policy.toMap());

  Stream<List<InsurancePolicy>> streamPoliciesForAgent(String agentUid) => _db
      .collection('policies')
      .where('agentUid', isEqualTo: agentUid)
      .snapshots()
      .map((s) => s.docs.map((d) => InsurancePolicy.fromMap(d.id, d.data())).toList());

  Future<InsurancePolicy?> findPolicyByNumber(String policyNumber) async {
    final snap =
        await _db.collection('policies').where('policyNumber', isEqualTo: policyNumber).limit(1).get();
    if (snap.docs.isEmpty) return null;
    return InsurancePolicy.fromMap(snap.docs.first.id, snap.docs.first.data());
  }

  Future<InsurancePolicy?> getPolicy(String id) async {
    final doc = await _db.collection('policies').doc(id).get();
    return doc.exists ? InsurancePolicy.fromMap(doc.id, doc.data()!) : null;
  }

  Future<void> linkVehicleToPolicy({required String vehicleId, required String policyId}) async {
    await _db.collection('vehicles').doc(vehicleId).update({'policyId': policyId});
    await _db.collection('policies').doc(policyId).update({'vehicleId': vehicleId});
  }

  // ---- Repair centers -----------------------------------------------------
  Stream<List<RepairCenter>> streamRepairCenters() => _db
      .collection('repairCenters')
      .snapshots()
      .map((s) => s.docs.map((d) => RepairCenter.fromMap(d.id, d.data())).toList());

  Future<String> addRepairCenter(RepairCenter center) async {
    final doc = await _db.collection('repairCenters').add(center.toMap());
    return doc.id;
  }

  Future<RepairCenter?> getRepairCenter(String id) async {
    final doc = await _db.collection('repairCenters').doc(id).get();
    return doc.exists ? RepairCenter.fromMap(doc.id, doc.data()!) : null;
  }

  // ---- Bookings -----------------------------------------------------------
  Future<String> createBooking(Booking booking) async {
    final doc = await _db.collection('bookings').add(booking.toMap());
    return doc.id;
  }

  Future<void> updateBookingStatus(String id, BookingStatus status) =>
      _db.collection('bookings').doc(id).update({'status': status.value});

  /// Marks a booking's outstanding charge as settled. Called from the
  /// Payments tab (or by Admin, for offline/cash settlements).
  Future<void> markBookingPaid(String id, {required String method}) =>
      _db.collection('bookings').doc(id).update({
        'paid': true,
        'paidAt': DateTime.now().toIso8601String(),
        'paymentMethod': method,
      });

  Stream<List<Booking>> streamBookingsForUser(String userUid) => _db
      .collection('bookings')
      .where('userUid', isEqualTo: userUid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => Booking.fromMap(d.id, d.data())).toList());

  /// One-off fetch (not a stream) used to gate "Request a Tow" on
  /// outstanding payments without keeping a second listener alive.
  Future<List<Booking>> fetchBookingsForUser(String userUid) async {
    final snap = await _db.collection('bookings').where('userUid', isEqualTo: userUid).get();
    return snap.docs.map((d) => Booking.fromMap(d.id, d.data())).toList();
  }

  Stream<List<Booking>> streamAllBookings() => _db
      .collection('bookings')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => Booking.fromMap(d.id, d.data())).toList());

  // ---- Settings -------------------------------------------------------
  Future<double> getDefaultRatePerKm() async {
    final doc = await _db.collection('settings').doc('towRates').get();
    if (!doc.exists) return 5.0;
    return (doc.data()?['defaultRatePerKm'] as num?)?.toDouble() ?? 5.0;
  }

  Future<void> setDefaultRatePerKm(double rate) =>
      _db.collection('settings').doc('towRates').set({'defaultRatePerKm': rate});
}
