import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../models/repair_center.dart';
import '../../theme/app_theme.dart';

/// Lets a Workshop set (and later edit) the location Users will pick it up
/// from in Request Tow — covers "user can choose... their preferred
/// workshop" needing an actual workshop-managed location to choose from,
/// rather than only Admin-seeded ones.
class WorkshopProfileTab extends StatefulWidget {
  const WorkshopProfileTab({super.key});

  @override
  State<WorkshopProfileTab> createState() => _WorkshopProfileTabState();
}

class _WorkshopProfileTabState extends State<WorkshopProfileTab> {
  static const _defaultCenter = LatLng(3.1390, 101.6869); // Kuala Lumpur

  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _mapController = MapController();
  LatLng _location = _defaultCenter;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasExistingCenter = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final appState = context.read<AppState>();
    final center = await appState.firestoreService.getWorkshopCenter(
      appState.currentUser!.uid,
    );
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (center != null) {
        _hasExistingCenter = true;
        _nameController.text = center.name;
        _addressController.text = center.address;
        _location = LatLng(center.latitude, center.longitude);
      } else {
        _nameController.text = '${appState.currentUser!.name}\'s Workshop';
      }
    });
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty ||
        _addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and address are required.')),
      );
      return;
    }
    setState(() => _isSaving = true);
    final appState = context.read<AppState>();
    final uid = appState.currentUser!.uid;
    await appState.firestoreService.setWorkshopCenter(
      uid,
      RepairCenter(
        id: uid,
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        latitude: _location.latitude,
        longitude: _location.longitude,
        ownerUid: uid,
      ),
    );
    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _hasExistingCenter = true;
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Workshop saved.')));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Workshop')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!_hasExistingCenter)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warningSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.25),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.warning,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Set up your workshop location so Users can find and book you.',
                        style: TextStyle(
                          color: AppColors.warning,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 240,
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _location,
                      initialZoom: 13,
                      onTap: (tapPosition, point) =>
                          setState(() => _location = point),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName:
                            'com.towbooking.mobile_tow_booking_system',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _location,
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.build_circle,
                              color: AppColors.primary,
                              size: 36,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Tap the map to set your workshop location.',
                style: TextStyle(fontSize: 12),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Workshop Name',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _addressController,
                    decoration: const InputDecoration(labelText: 'Address'),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _isSaving ? null : _save,
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _hasExistingCenter
                                ? 'Save Changes'
                                : 'Create Workshop',
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
