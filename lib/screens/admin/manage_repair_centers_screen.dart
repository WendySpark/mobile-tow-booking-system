import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../models/repair_center.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/staggered_list_view.dart';

class ManageRepairCentersScreen extends StatelessWidget {
  const ManageRepairCentersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Repair Centers')),
      body: StreamBuilder<List<RepairCenter>>(
        stream: appState.firestoreService.streamRepairCenters(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final centers = snapshot.data!;
          if (centers.isEmpty) {
            return const EmptyState(
              icon: Icons.build_circle_outlined,
              title: 'No repair centers yet',
              subtitle: 'Tap the + button to add one.',
            );
          }
          return StaggeredListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            itemCount: centers.length,
            itemBuilder: (context, i) {
              final c = centers[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.primarySurface,
                      foregroundColor: AppColors.primary,
                      child: Icon(Icons.build_circle, size: 20),
                    ),
                    title: Text(c.name),
                    subtitle: Text(c.address),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addCenterDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _addCenterDialog(BuildContext context) async {
    final appState = context.read<AppState>();
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final latController = TextEditingController();
    final lngController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Repair Center'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              TextFormField(
                controller: addressController,
                decoration: const InputDecoration(labelText: 'Address'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              TextFormField(
                controller: latController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Latitude'),
                validator: (v) =>
                    double.tryParse(v ?? '') == null ? 'Enter a number' : null,
              ),
              TextFormField(
                controller: lngController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Longitude'),
                validator: (v) =>
                    double.tryParse(v ?? '') == null ? 'Enter a number' : null,
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
              await appState.firestoreService.addRepairCenter(
                RepairCenter(
                  id: '',
                  name: nameController.text.trim(),
                  address: addressController.text.trim(),
                  latitude: double.parse(latController.text),
                  longitude: double.parse(lngController.text),
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
}
