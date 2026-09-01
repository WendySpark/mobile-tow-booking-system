import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../models/booking.dart';
import '../../models/booking_status.dart';
import '../../models/driver_status.dart';
import '../../services/routing_service.dart';
import '../../services/tow_tracking_simulator.dart';
import '../../theme/app_theme.dart';
import '../user/payments_screen.dart';
import '../user/user_home_shell.dart';

/// Covers "real-time tracking of tow vehicle arrival" — the marker follows
/// an actual road route (via RoutingService/OSRM) rather than a straight
/// line; see TowTrackingSimulator for how the movement along it is timed.
class BookingTrackingScreen extends StatefulWidget {
  const BookingTrackingScreen({super.key, required this.booking});

  final Booking booking;

  @override
  State<BookingTrackingScreen> createState() => _BookingTrackingScreenState();
}

class _BookingTrackingScreenState extends State<BookingTrackingScreen> {
  final _routingService = RoutingService();
  final _mapController = MapController();
  TowTrackingSimulator? _simulator;

  @override
  void initState() {
    super.initState();
    _loadRouteAndStart();
  }

  Future<void> _loadRouteAndStart() async {
    final route = await _routingService.getRoute(
      start: LatLng(widget.booking.truckStartLat, widget.booking.truckStartLng),
      end: LatLng(widget.booking.pickupLat, widget.booking.pickupLng),
    );
    if (!mounted) return;
    setState(() {
      _simulator = TowTrackingSimulator(
        bookingId: widget.booking.id,
        route: route,
        firestoreService: context.read<AppState>().firestoreService,
      )..startSimulation();
    });
  }

  @override
  void dispose() {
    _simulator?.dispose();
    _routingService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pickup = LatLng(widget.booking.pickupLat, widget.booking.pickupLng);
    final simulator = _simulator;

    return Scaffold(
      appBar: AppBar(title: const Text('Tracking Your Tow')),
      body: simulator == null
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('Finding the fastest route...'),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ValueListenableBuilder<LatLng>(
                    valueListenable: simulator.position,
                    builder: (context, truckPosition, _) {
                      return FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: pickup,
                          initialZoom: 13,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName:
                                'com.towbooking.mobile_tow_booking_system',
                          ),
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: simulator.route.points,
                                strokeWidth: 4,
                                color: AppColors.primary.withValues(alpha: 0.6),
                              ),
                            ],
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: pickup,
                                width: 40,
                                height: 40,
                                child: const Icon(
                                  Icons.location_pin,
                                  color: AppColors.danger,
                                  size: 40,
                                ),
                              ),
                              Marker(
                                point: truckPosition,
                                width: 40,
                                height: 40,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.4,
                                        ),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(6),
                                  child: const Icon(
                                    Icons.local_shipping,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
                ValueListenableBuilder<BookingStatus>(
                  valueListenable: simulator.status,
                  builder: (context, status, _) {
                    final arrived = status == BookingStatus.arrived;
                    final statusColor = arrived
                        ? AppColors.success
                        : AppColors.primary;
                    return Container(
                      decoration: const BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x14000000),
                            blurRadius: 16,
                            offset: Offset(0, -4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: CircleAvatar(
                                  key: ValueKey(arrived),
                                  radius: 18,
                                  backgroundColor: statusColor.withValues(
                                    alpha: 0.12,
                                  ),
                                  foregroundColor: statusColor,
                                  child: Icon(
                                    arrived
                                        ? Icons.check_circle
                                        : Icons.local_shipping,
                                    size: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                status.label,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                          if (widget.booking.driverName != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Driver: ${widget.booking.driverName}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppColors.inkMuted),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            simulator.route.isRoadFollowing
                                ? 'Following road directions · ${simulator.route.totalDistanceKm.toStringAsFixed(1)} km'
                                : 'Route unavailable — showing a direct line',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.inkMuted,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Charge: ${widget.booking.charge == 0 ? 'FREE' : 'RM ${widget.booking.charge.toStringAsFixed(2)}'}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 16),
                          if (status == BookingStatus.arrived)
                            FilledButton(
                              onPressed: () async {
                                simulator.markCompleted();
                                if (widget.booking.driverId != null) {
                                  await context
                                      .read<AppState>()
                                      .firestoreService
                                      .setDriverStatus(
                                        widget.booking.driverId!,
                                        DriverStatus.available,
                                      );
                                }
                                if (!context.mounted) return;
                                if (widget.booking.requiresPayment &&
                                    !widget.booking.paid) {
                                  await showDialog(
                                    context: context,
                                    builder: (dialogContext) => AlertDialog(
                                      title: const Text('Payment Due'),
                                      content: Text(
                                        'This tow costs RM ${widget.booking.charge.toStringAsFixed(2)}. '
                                        'Settle it from the Payments tab before requesting another tow.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(dialogContext),
                                          child: const Text('Later'),
                                        ),
                                        FilledButton(
                                          onPressed: () {
                                            Navigator.pop(dialogContext);
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    const PaymentsScreen(),
                                              ),
                                            );
                                          },
                                          child: const Text('Pay Now'),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                                if (!context.mounted) return;
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                    builder: (_) => const UserHomeShell(),
                                  ),
                                  (route) => false,
                                );
                              },
                              child: const Text('Mark Completed'),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
    );
  }
}
