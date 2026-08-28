import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../models/booking.dart';
import '../../models/booking_status.dart';
import '../../models/insurance_policy.dart';
import '../../models/repair_center.dart';
import '../../models/tow_quote.dart';
import '../../models/vehicle.dart';
import '../../services/tow_calculation_service.dart';
import 'booking_tracking_screen.dart';

/// Covers "tow service booking confirmation" plus the "free towing service
/// eligibility check" and "tow charge based on distance" key processes:
/// pick a pickup point, choose a vehicle + repair center, see the computed
/// quote live, then confirm.
class RequestTowScreen extends StatefulWidget {
  const RequestTowScreen({super.key});

  @override
  State<RequestTowScreen> createState() => _RequestTowScreenState();
}

class _RequestTowScreenState extends State<RequestTowScreen> {
  static const _calculationService = TowCalculationService();
  static const _defaultCenter = LatLng(3.1390, 101.6869); // Kuala Lumpur

  final _mapController = MapController();
  LatLng _pickup = _defaultCenter;
  Vehicle? _selectedVehicle;
  RepairCenter? _selectedCenter;
  InsurancePolicy? _resolvedPolicy;
  TowQuote? _quote;
  bool _isBooking = false;
  bool _isLocating = false;

  Future<void> _useCurrentLocation(AppState appState) async {
    setState(() => _isLocating = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Location permission denied.')));
        }
        return;
      }
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Location services are disabled.')));
        }
        return;
      }
      final position = await Geolocator.getCurrentPosition();
      final located = LatLng(position.latitude, position.longitude);
      setState(() => _pickup = located);
      _mapController.move(located, 15);
      await _recomputeQuote(appState);
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _recomputeQuote(AppState appState) async {
    if (_selectedVehicle == null || _selectedCenter == null) {
      setState(() => _quote = null);
      return;
    }

    InsurancePolicy? policy;
    if (_selectedVehicle!.policyId != null) {
      policy = await appState.firestoreService.getPolicy(_selectedVehicle!.policyId!);
    }
    final defaultRate = await appState.firestoreService.getDefaultRatePerKm();

    final quote = _calculationService.calculateQuote(
      pickupLat: _pickup.latitude,
      pickupLng: _pickup.longitude,
      centerLat: _selectedCenter!.latitude,
      centerLng: _selectedCenter!.longitude,
      policy: policy,
      defaultRatePerKm: defaultRate,
    );

    if (!mounted) return;
    setState(() {
      _resolvedPolicy = policy;
      _quote = quote;
    });
  }

  Future<void> _confirmBooking(AppState appState) async {
    if (_quote == null || _selectedVehicle == null || _selectedCenter == null) return;
    setState(() => _isBooking = true);

    // Randomize a plausible truck starting point ~3-6km from the pickup,
    // purely for the tracking animation to have somewhere to start from.
    final truckStart = LatLng(_pickup.latitude + 0.03, _pickup.longitude + 0.03);

    final booking = Booking(
      id: '',
      userUid: appState.currentUser!.uid,
      vehicleId: _selectedVehicle!.id,
      policyId: _resolvedPolicy?.id,
      repairCenterId: _selectedCenter!.id,
      pickupLat: _pickup.latitude,
      pickupLng: _pickup.longitude,
      distanceKm: _quote!.totalDistanceKm,
      freeDistanceKm: _quote!.freeDistanceKm,
      chargeableDistanceKm: _quote!.chargeableDistanceKm,
      charge: _quote!.charge,
      status: BookingStatus.confirmed,
      createdAt: DateTime.now(),
      truckStartLat: truckStart.latitude,
      truckStartLng: truckStart.longitude,
    );

    final id = await appState.firestoreService.createBooking(booking);

    if (!mounted) return;
    setState(() => _isBooking = false);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => BookingTrackingScreen(booking: booking.copyWith(id: id))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Request a Tow')),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _pickup,
                    initialZoom: 12,
                    onTap: (tapPosition, point) {
                      setState(() => _pickup = point);
                      _recomputeQuote(appState);
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.towbooking.mobile_tow_booking_system',
                    ),
                    MarkerLayer(markers: [
                      Marker(
                        point: _pickup,
                        width: 40,
                        height: 40,
                        child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
                      ),
                      if (_selectedCenter != null)
                        Marker(
                          point: LatLng(_selectedCenter!.latitude, _selectedCenter!.longitude),
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.build, color: Colors.indigo, size: 32),
                        ),
                    ]),
                  ],
                ),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: FloatingActionButton.small(
                    heroTag: 'locateMe',
                    onPressed: _isLocating ? null : () => _useCurrentLocation(appState),
                    child: _isLocating
                        ? const SizedBox(
                            height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.my_location),
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Text('Tap the map to set your pickup location.', style: TextStyle(fontSize: 12)),
          ),
          Expanded(
            flex: 4,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  StreamBuilder<List<Vehicle>>(
                    stream: appState.firestoreService.streamVehiclesForOwner(appState.currentUser!.uid),
                    builder: (context, snapshot) {
                      final vehicles = snapshot.data ?? [];
                      return DropdownButtonFormField<Vehicle>(
                        initialValue: _selectedVehicle,
                        decoration: const InputDecoration(labelText: 'Vehicle'),
                        items: vehicles
                            .map((v) => DropdownMenuItem(value: v, child: Text(v.displayName)))
                            .toList(),
                        onChanged: (v) {
                          setState(() => _selectedVehicle = v);
                          _recomputeQuote(appState);
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  StreamBuilder<List<RepairCenter>>(
                    stream: appState.firestoreService.streamRepairCenters(),
                    builder: (context, snapshot) {
                      final centers = snapshot.data ?? [];
                      return DropdownButtonFormField<RepairCenter>(
                        initialValue: _selectedCenter,
                        decoration: const InputDecoration(labelText: 'Panel Repair Center'),
                        items:
                            centers.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
                        onChanged: (c) {
                          setState(() => _selectedCenter = c);
                          _recomputeQuote(appState);
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_quote != null) _QuoteCard(quote: _quote!),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: (_quote == null || _isBooking) ? null : () => _confirmBooking(appState),
                    child: _isBooking
                        ? const SizedBox(
                            height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Confirm Booking'),
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

class _QuoteCard extends StatelessWidget {
  const _QuoteCard({required this.quote});

  final TowQuote quote;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: quote.isFullyFree ? Colors.green.shade50 : Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Distance: ${quote.totalDistanceKm.toStringAsFixed(1)} km'),
            if (!quote.eligibleForFreeTow)
              Text(quote.ineligibilityReason!, style: const TextStyle(color: Colors.red)),
            Text('Free distance: ${quote.freeDistanceKm.toStringAsFixed(1)} km'),
            Text('Chargeable distance: ${quote.chargeableDistanceKm.toStringAsFixed(1)} km'),
            const SizedBox(height: 8),
            Text(
              quote.isFullyFree
                  ? 'Total charge: FREE'
                  : 'Total charge: RM ${quote.charge.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}
