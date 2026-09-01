import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../models/booking_status.dart';
import '../models/route_result.dart';
import '../utils/constants.dart';
import 'firestore_service.dart';

/// Drives the "real-time tracking of tow vehicle arrival" key process for
/// the prototype. Animates a marker along [route] — a real road-following
/// path from RoutingService, not a straight line — entirely client-side
/// (see plan: no real device GPS, no repeated Firestore writes needed for
/// the animation itself) while still persisting the booking status
/// transitions so other roles/screens watching Firestore see the same
/// lifecycle.
class TowTrackingSimulator {
  TowTrackingSimulator({
    required this.bookingId,
    required this.route,
    required this.firestoreService,
    this.duration = kSimulatedTowDuration,
  }) : position = ValueNotifier(route.points.first);

  final String bookingId;
  final RouteResult route;
  final FirestoreService firestoreService;
  final Duration duration;

  final ValueNotifier<LatLng> position;
  final ValueNotifier<BookingStatus> status = ValueNotifier(
    BookingStatus.confirmed,
  );

  Timer? _timer;
  DateTime? _startedAt;
  static const _tick = Duration(milliseconds: 500);

  void startSimulation() {
    _startedAt = DateTime.now();
    _setStatus(BookingStatus.enRoute);
    _timer = Timer.periodic(_tick, _onTick);
  }

  void _onTick(Timer timer) {
    final elapsed = DateTime.now().difference(_startedAt!);
    final t = (elapsed.inMilliseconds / duration.inMilliseconds).clamp(
      0.0,
      1.0,
    );

    position.value = route.pointAt(t);

    if (t >= 1.0) {
      timer.cancel();
      _setStatus(BookingStatus.arrived);
    }
  }

  void _setStatus(BookingStatus newStatus) {
    status.value = newStatus;
    firestoreService.updateBookingStatus(bookingId, newStatus);
  }

  /// Call once the driver/user confirms the tow is complete.
  void markCompleted() => _setStatus(BookingStatus.completed);

  void dispose() {
    _timer?.cancel();
    position.dispose();
    status.dispose();
  }
}
