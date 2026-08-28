import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../models/driver.dart';
import '../../models/driver_status.dart';

/// Covers "the truck drivers are managed by [the workshop]" — CRUD for a
/// Workshop's own fleet. New drivers default to the workshop's own
/// location as their base (tow trucks start their day at the workshop).
class ManageDriversScreen extends StatelessWidget {
  const ManageDriversScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final workshopUid = appState.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('My Drivers')),
      body: StreamBuilder<List<Driver>>(
        stream: appState.firestoreService.streamDriversForWorkshop(workshopUid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final drivers = snapshot.data!;
          if (drivers.isEmpty) {
            return const Center(child: Text('No drivers yet. Tap + to add one.'));
          }
          return ListView.builder(
            itemCount: drivers.length,
            itemBuilder: (context, i) {
              final d = drivers[i];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _statusColor(d.status).withValues(alpha: 0.15),
                  child: Icon(Icons.local_shipping, color: _statusColor(d.status)),
                ),
                title: Text(d.name),
                subtitle: Text('${d.plateNumber} · ${d.phone}'),
                trailing: DropdownButton<DriverStatus>(
                  value: d.status,
                  underline: const SizedBox.shrink(),
                  items: DriverStatus.values
                      .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                      .toList(),
                  onChanged: (s) {
                    if (s != null) appState.firestoreService.setDriverStatus(d.id, s);
                  },
                ),
                onLongPress: () => _confirmDelete(context, appState, d),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addDriverDialog(context, appState, workshopUid),
        child: const Icon(Icons.add),
      ),
    );
  }

  Color _statusColor(DriverStatus status) => switch (status) {
        DriverStatus.available => Colors.green,
        DriverStatus.busy => Colors.orange,
        DriverStatus.offline => Colors.grey,
      };

  Future<void> _addDriverDialog(BuildContext context, AppState appState, String workshopUid) async {
    final center = await appState.firestoreService.getWorkshopCenter(workshopUid);
    if (!context.mounted) return;
    if (center == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Set up your workshop location first (My Workshop tab).')),
      );
      return;
    }

    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final plateController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Driver'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Driver Name'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              TextFormField(
                controller: plateController,
                decoration: const InputDecoration(labelText: 'Tow Truck Plate Number'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              await appState.firestoreService.addDriver(Driver(
                id: '',
                workshopUid: workshopUid,
                name: nameController.text.trim(),
                phone: phoneController.text.trim(),
                plateNumber: plateController.text.trim(),
                baseLat: center.latitude,
                baseLng: center.longitude,
              ));
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, AppState appState, Driver driver) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove Driver'),
        content: Text('Remove ${driver.name} from your fleet?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Remove')),
        ],
      ),
    );
    if (confirmed == true) {
      await appState.firestoreService.deleteDriver(driver.id);
    }
  }
}
