import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../models/driver.dart';
import '../../models/driver_status.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/staggered_list_view.dart';

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
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final drivers = snapshot.data!;
          if (drivers.isEmpty) {
            return const EmptyState(
              icon: Icons.local_shipping_outlined,
              title: 'No drivers yet',
              subtitle: 'Tap the + button to add your first driver.',
            );
          }
          return StaggeredListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            itemCount: drivers.length,
            itemBuilder: (context, i) {
              final d = drivers[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: _statusColor(d.status)
                          .withValues(alpha: 0.15),
                      foregroundColor: _statusColor(d.status),
                      child: const Icon(Icons.local_shipping, size: 20),
                    ),
                    title: Text(d.name),
                    subtitle: Text('${d.plateNumber} · ${d.phone}'),
                    trailing: DropdownButton<DriverStatus>(
                      value: d.status,
                      underline: const SizedBox.shrink(),
                      items: DriverStatus.values
                          .map(
                            (s) => DropdownMenuItem(
                              value: s,
                              child: Text(s.label),
                            ),
                          )
                          .toList(),
                      onChanged: (s) {
                        if (s != null)
                          appState.firestoreService.setDriverStatus(d.id, s);
                      },
                    ),
                    onLongPress: () => _confirmDelete(context, appState, d),
                  ),
                ),
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
    DriverStatus.available => AppColors.success,
    DriverStatus.busy => AppColors.warning,
    DriverStatus.offline => AppColors.inkMuted,
  };

  Future<void> _addDriverDialog(
    BuildContext context,
    AppState appState,
    String workshopUid,
  ) async {
    final center = await appState.firestoreService.getWorkshopCenter(
      workshopUid,
    );
    if (!context.mounted) return;
    if (center == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Set up your workshop location first (My Workshop tab).',
          ),
        ),
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
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              TextFormField(
                controller: plateController,
                decoration: const InputDecoration(
                  labelText: 'Tow Truck Plate Number',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              await appState.firestoreService.addDriver(
                Driver(
                  id: '',
                  workshopUid: workshopUid,
                  name: nameController.text.trim(),
                  phone: phoneController.text.trim(),
                  plateNumber: plateController.text.trim(),
                  baseLat: center.latitude,
                  baseLng: center.longitude,
                ),
              );
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    AppState appState,
    Driver driver,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove Driver'),
        content: Text('Remove ${driver.name} from your fleet?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await appState.firestoreService.deleteDriver(driver.id);
    }
  }
}
