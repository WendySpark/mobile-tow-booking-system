import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../models/repair_center.dart';

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
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final centers = snapshot.data!;
          if (centers.isEmpty) return const Center(child: Text('No repair centers yet. Tap + to add.'));
          return ListView.builder(
            itemCount: centers.length,
            itemBuilder: (context, i) {
              final c = centers[i];
              return ListTile(
                leading: const Icon(Icons.build_circle, color: Colors.indigo),
                title: Text(c.name),
                subtitle: Text(c.address),
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
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              TextFormField(
                controller: addressController,
                decoration: const InputDecoration(labelText: 'Address'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              TextFormField(
                controller: latController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Latitude'),
                validator: (v) => double.tryParse(v ?? '') == null ? 'Enter a number' : null,
              ),
              TextFormField(
                controller: lngController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Longitude'),
                validator: (v) => double.tryParse(v ?? '') == null ? 'Enter a number' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              await appState.firestoreService.addRepairCenter(RepairCenter(
                id: '',
                name: nameController.text.trim(),
                address: addressController.text.trim(),
                latitude: double.parse(latController.text),
                longitude: double.parse(lngController.text),
              ));
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
