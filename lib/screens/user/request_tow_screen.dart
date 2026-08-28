import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../models/booking.dart';
import '../../models/booking_status.dart';
import '../../models/driver_status.dart';
import '../../models/insurance_policy.dart';
import '../../models/repair_center.dart';
import '../../models/tow_driver.dart';
import '../../models/tow_quote.dart';
import '../../models/vehicle.dart';
import '../../services/driver_dispatch_service.dart';
import '../../services/tow_calculation_service.dart';
import '../../utils/distance_utils.dart';
import 'booking_tracking_screen.dart';

/// Covers "tow service booking confirmation" plus the "free towing service
/// eligibility check" and "tow charge based on distance" key processes:
/// pick a pickup point, choose a vehicle, choose a workshop (nearest or
/// preferred — see "user can choose to go to a workshop near them or their
/// preferred workshop"), see the computed quote live, pick a driver from
/// that workshop's fleet by ETA, then confirm.
class RequestTowScreen extends StatefulWidget {
  const RequestTowScreen({super.key});

  @override
  State<RequestTowScreen> createState() => _RequestTowScreenState();
}

class _RequestTowScreenState extends State<RequestTowScreen> {
  static const _calculationService = TowCalculationService();
  static const _dispatchService = DriverDispatchService();
  static const _defaultCenter = LatLng(3.1390, 101.6869); // Kuala Lumpur

  final _mapController = MapController();
  LatLng _pickup = _defaultCenter;
  Vehicle? _selectedVehicle;
  RepairCenter? _selectedCenter;
  InsurancePolicy? _resolvedPolicy;
  TowQuote? _quote;
  List<TowDriver> _drivers = [];
  TowDriver? _selectedDriver;
  bool _hasAutoSelectedCenter = false;
  bool _isLoadingDrivers = false;
  bool _isBooking = false;
  bool _isLocating = false;

  List<RepairCenter> _sortedByDistance(List<RepairCenter> centers) {
    final sorted = [...centers];
    sorted.sort((a, b) {
      final da = haversineDistanceKm(lat1: _pickup.latitude, lng1: _pickup.longitude, lat2: a.latitude, lng2: a.longitude);
      final db = haversineDistanceKm(lat1: _pickup.latitude, lng1: _pickup.longitude, lat2: b.latitude, lng2: b.longitude);
      return da.compareTo(db);
    });
    return sorted;
  }

  void _autoSelectCenterIfNeeded(AppState appState, List<RepairCenter> sorted) {
    if (_hasAutoSelectedCenter || sorted.isEmpty) return;
    _hasAutoSelectedCenter = true;
    final preferredId = appState.currentUser!.preferredWorkshopId;
    final preferred = preferredId == null ? null : sorted.where((c) => c.id == preferredId).firstOrNull;
    final chosen = preferred ?? sorted.first;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _selectedCenter = chosen);
      _recomputeQuote(appState);
    });
  }

  Future<void> _refreshDrivers() async {
    if (_selectedCenter == null) {
      setState(() {
        _drivers = [];
        _selectedDriver = null;
      });
      return;
    }
    setState(() => _isLoadingDrivers = true);
    final available = await context
        .read<AppState>()
        .firestoreService
        .fetchAvailableDrivers(_selectedCenter!.id);
    if (!mounted) return;
    final ranked = _dispatchService.rankDrivers(
      availableDrivers: available,
      pickupLat: _pickup.latitude,
      pickupLng: _pickup.longitude,
    );
    setState(() {
      _drivers = ranked;
      _selectedDriver = ranked.isEmpty ? null : ranked.first;
      _isLoadingDrivers = false;
    });
  }

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
    await _refreshDrivers();
  }

  Future<void> _confirmBooking(AppState appState) async {
    if (_quote == null || _selectedVehicle == null || _selectedCenter == null || _selectedDriver == null) {
      return;
    }
    setState(() => _isBooking = true);

    final driver = _selectedDriver!;

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
      truckStartLat: driver.baseLat,
      truckStartLng: driver.baseLng,
      driverId: driver.id,
      driverName: driver.name,
      driverEtaMinutes: driver.etaMinutes,
      paid: _quote!.charge == 0,
    );

    final id = await appState.firestoreService.createBooking(booking);
    await appState.firestoreService.setDriverStatus(driver.id, DriverStatus.busy);

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
            flex: 5,
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
                  const SizedBox(height: 16),
                  Text('Choose a Workshop', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  const Text(
                    'Sorted by distance from your pickup pin. Tap ★ to set your preferred workshop.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<List<RepairCenter>>(
                    stream: appState.firestoreService.streamRepairCenters(),
                    builder: (context, snapshot) {
                      final centers = snapshot.data ?? [];
                      final sorted = _sortedByDistance(centers);
                      _autoSelectCenterIfNeeded(appState, sorted);
                      if (sorted.isEmpty) {
                        return const Text('No workshops available yet.', style: TextStyle(color: Colors.grey));
                      }
                      return Column(
                        children: [
                          for (final center in sorted)
                            _WorkshopTile(
                              center: center,
                              distanceKm: haversineDistanceKm(
                                lat1: _pickup.latitude,
                                lng1: _pickup.longitude,
                                lat2: center.latitude,
                                lng2: center.longitude,
                              ),
                              isPreferred: appState.currentUser!.preferredWorkshopId == center.id,
                              selected: _selectedCenter?.id == center.id,
                              onTap: () {
                                setState(() => _selectedCenter = center);
                                _recomputeQuote(appState);
                              },
                              onStarTap: () => appState.setPreferredWorkshop(center.id),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_quote != null) _QuoteCard(quote: _quote!),
                  if (_isLoadingDrivers)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_selectedCenter != null && _drivers.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'This workshop has no available drivers right now — try another workshop.',
                        style: TextStyle(color: Colors.red),
                      ),
                    )
                  else if (_drivers.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text('Choose a Driver', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    for (final driver in _drivers)
                      _DriverTile(
                        driver: driver,
                        selected: driver.id == _selectedDriver?.id,
                        onTap: () => setState(() => _selectedDriver = driver),
                      ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: (_quote == null || _selectedDriver == null || _isBooking)
                        ? null
                        : () => _confirmBooking(appState),
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

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class _WorkshopTile extends StatelessWidget {
  const _WorkshopTile({
    required this.center,
    required this.distanceKm,
    required this.isPreferred,
    required this.selected,
    required this.onTap,
    required this.onStarTap,
  });

  final RepairCenter center;
  final double distanceKm;
  final bool isPreferred;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onStarTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: selected ? Colors.indigo.shade50 : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: selected ? Colors.indigo : Colors.transparent, width: 1.5),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(Icons.build_circle, color: selected ? Colors.indigo : Colors.grey),
        title: Text(center.name),
        subtitle: Text('${distanceKm.toStringAsFixed(1)} km away · ${center.address}'),
        trailing: IconButton(
          icon: Icon(isPreferred ? Icons.star : Icons.star_border, color: Colors.amber),
          tooltip: isPreferred ? 'Your preferred workshop' : 'Set as preferred workshop',
          onPressed: onStarTap,
        ),
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

class _DriverTile extends StatelessWidget {
  const _DriverTile({required this.driver, required this.selected, required this.onTap});

  final TowDriver driver;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: selected ? Colors.indigo.shade50 : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: selected ? Colors.indigo : Colors.transparent, width: 1.5),
      ),
      child: RadioListTile<String>(
        value: driver.id,
        groupValue: selected ? driver.id : null,
        onChanged: (_) => onTap(),
        title: Text(driver.name),
        subtitle: Text(
          '${driver.distanceKm.toStringAsFixed(1)} km away · ETA ${driver.etaMinutes.round()} min · '
          '★ ${driver.rating.toStringAsFixed(1)}',
        ),
      ),
    );
  }
}
