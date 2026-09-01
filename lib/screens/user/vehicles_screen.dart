import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../models/vehicle.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/staggered_list_view.dart';

class VehiclesScreen extends StatelessWidget {
  const VehiclesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final uid = appState.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('My Vehicles')),
      body: StreamBuilder<List<Vehicle>>(
        stream: appState.firestoreService.streamVehiclesForOwner(uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final vehicles = snapshot.data!;
          if (vehicles.isEmpty) {
            return EmptyState(
              icon: Icons.directions_car_outlined,
              title: 'No vehicles yet',
              subtitle: 'Tap the + button to add your first vehicle.',
            );
          }
          return StaggeredListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            itemCount: vehicles.length,
            itemBuilder: (context, i) {
              final v = vehicles[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: AppColors.primarySurface,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.directions_car,
                        color: AppColors.primary,
                      ),
                    ),
                    title: Text(v.displayName),
                    subtitle: Text(
                      v.policyId == null
                          ? 'No insurance policy linked'
                          : 'Policy linked',
                    ),
                    trailing: v.policyId == null
                        ? TextButton(
                            onPressed: () => _linkPolicyDialog(context, v),
                            child: const Text('Link Policy'),
                          )
                        : const Icon(Icons.verified, color: AppColors.success),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addVehicleDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _addVehicleDialog(BuildContext context) async {
    final appState = context.read<AppState>();
    final plateController = TextEditingController();
    final makeController = TextEditingController();
    final modelController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Vehicle'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: plateController,
                decoration: const InputDecoration(labelText: 'Plate Number'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              TextFormField(
                controller: makeController,
                decoration: const InputDecoration(labelText: 'Make'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              TextFormField(
                controller: modelController,
                decoration: const InputDecoration(labelText: 'Model'),
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
              await appState.firestoreService.addVehicle(
                Vehicle(
                  id: '',
                  ownerUid: appState.currentUser!.uid,
                  plateNumber: plateController.text.trim(),
                  make: makeController.text.trim(),
                  model: modelController.text.trim(),
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

  Future<void> _linkPolicyDialog(BuildContext context, Vehicle vehicle) async {
    final appState = context.read<AppState>();
    final policyController = TextEditingController();
    String? error;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text('Link Insurance Policy'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: policyController,
                decoration: const InputDecoration(labelText: 'Policy Number'),
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(error!, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final policy = await appState.firestoreService
                    .findPolicyByNumber(policyController.text.trim());
                if (policy == null) {
                  setState(() => error = 'No policy found with that number.');
                  return;
                }
                await appState.firestoreService.linkVehicleToPolicy(
                  vehicleId: vehicle.id,
                  policyId: policy.id,
                );
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              child: const Text('Link'),
            ),
          ],
        ),
      ),
    );
  }
}
