import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../models/booking.dart';
import '../../models/booking_status.dart';
import '../../services/tow_tracking_simulator.dart';
import '../user/user_home_shell.dart';

/// Covers "real-time tracking of tow vehicle arrival" — see
/// TowTrackingSimulator for how the movement itself is simulated.
class BookingTrackingScreen extends StatefulWidget {
  const BookingTrackingScreen({super.key, required this.booking});

  final Booking booking;

  @override
  State<BookingTrackingScreen> createState() => _BookingTrackingScreenState();
}

class _BookingTrackingScreenState extends State<BookingTrackingScreen> {
  late final TowTrackingSimulator _simulator;
  final _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _simulator = TowTrackingSimulator(
      bookingId: widget.booking.id,
      start: LatLng(widget.booking.truckStartLat, widget.booking.truckStartLng),
      end: LatLng(widget.booking.pickupLat, widget.booking.pickupLng),
      firestoreService: context.read<AppState>().firestoreService,
    )..startSimulation();
  }

  @override
  void dispose() {
    _simulator.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pickup = LatLng(widget.booking.pickupLat, widget.booking.pickupLng);

    return Scaffold(
      appBar: AppBar(title: const Text('Tracking Your Tow')),
      body: Column(
        children: [
          Expanded(
            child: ValueListenableBuilder<LatLng>(
              valueListenable: _simulator.position,
              builder: (context, truckPosition, _) {
                return FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(initialCenter: pickup, initialZoom: 13),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.towbooking.mobile_tow_booking_system',
                    ),
                    PolylineLayer(polylines: [
                      Polyline(
                        points: [
                          LatLng(widget.booking.truckStartLat, widget.booking.truckStartLng),
                          pickup,
                        ],
                        strokeWidth: 3,
                        color: Colors.indigo.withValues(alpha: 0.4),
                      ),
                    ]),
                    MarkerLayer(markers: [
                      Marker(
                        point: pickup,
                        width: 40,
                        height: 40,
                        child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
                      ),
                      Marker(
                        point: truckPosition,
                        width: 40,
                        height: 40,
                        child: const Icon(Icons.local_shipping, color: Colors.indigo, size: 32),
                      ),
                    ]),
                  ],
                );
              },
            ),
          ),
          ValueListenableBuilder<BookingStatus>(
            valueListenable: _simulator.status,
            builder: (context, status, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        status == BookingStatus.arrived ? Icons.check_circle : Icons.local_shipping,
                        color: status == BookingStatus.arrived ? Colors.green : Colors.indigo,
                      ),
                      const SizedBox(width: 8),
                      Text(status.label, style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Charge: ${widget.booking.charge == 0 ? 'FREE' : 'RM ${widget.booking.charge.toStringAsFixed(2)}'}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  if (status == BookingStatus.arrived)
                    FilledButton(
                      onPressed: () {
                        _simulator.markCompleted();
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const UserHomeShell()),
                          (route) => false,
                        );
                      },
                      child: const Text('Mark Completed'),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
