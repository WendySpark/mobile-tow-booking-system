import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../models/insurance_policy.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/staggered_list_view.dart';

/// Covers "vehicle insurance information database" — the Insurance Agent's
/// side of creating/maintaining policy records (free tow radius + rate).
class ManagePoliciesScreen extends StatelessWidget {
  const ManagePoliciesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Policies')),
      body: StreamBuilder<List<InsurancePolicy>>(
        stream: appState.firestoreService.streamPoliciesForAgent(
          appState.currentUser!.uid,
        ),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final policies = snapshot.data!;
          if (policies.isEmpty) {
            return const EmptyState(
              icon: Icons.shield_outlined,
              title: 'No policies yet',
              subtitle:
                  'Tap the + button to create your first insurance policy.',
            );
          }

          return StaggeredListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            itemCount: policies.length,
            itemBuilder: (context, i) {
              final p = policies[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      backgroundColor:
                          (p.isValid ? AppColors.success : AppColors.inkMuted)
                              .withValues(alpha: 0.12),
                      foregroundColor: p.isValid
                          ? AppColors.success
                          : AppColors.inkMuted,
                      child: const Icon(Icons.shield, size: 20),
                    ),
                    title: Text(p.policyNumber),
                    subtitle: Text(
                      'Free radius: ${p.freeTowRadiusKm} km · Rate: RM ${p.ratePerKmAfterFree}/km · '
                      'Expires ${DateFormat.yMMMd().format(p.expiryDate)}',
                    ),
                    trailing: Text(p.status.value),
                    onTap: () => _editPolicyDialog(context, existing: p),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _editPolicyDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _editPolicyDialog(
    BuildContext context, {
    InsurancePolicy? existing,
  }) async {
    final appState = context.read<AppState>();
    final numberController = TextEditingController(
      text: existing?.policyNumber ?? '',
    );
    final radiusController = TextEditingController(
      text: existing?.freeTowRadiusKm.toString() ?? '10',
    );
    final rateController = TextEditingController(
      text: existing?.ratePerKmAfterFree.toString() ?? '2',
    );
    var status = existing?.status ?? PolicyStatus.active;
    var expiry =
        existing?.expiryDate ?? DateTime.now().add(const Duration(days: 365));
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: Text(existing == null ? 'New Policy' : 'Edit Policy'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: numberController,
                    decoration: const InputDecoration(
                      labelText: 'Policy Number',
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: radiusController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Free Tow Radius (km)',
                    ),
                    validator: (v) => double.tryParse(v ?? '') == null
                        ? 'Enter a number'
                        : null,
                  ),
                  TextFormField(
                    controller: rateController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Rate After Free (RM/km)',
                    ),
                    validator: (v) => double.tryParse(v ?? '') == null
                        ? 'Enter a number'
                        : null,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<PolicyStatus>(
                    initialValue: status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: PolicyStatus.values
                        .map(
                          (s) =>
                              DropdownMenuItem(value: s, child: Text(s.value)),
                        )
                        .toList(),
                    onChanged: (s) => setState(() => status = s!),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Expires: ${DateFormat.yMMMd().format(expiry)}',
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: dialogContext,
                        initialDate: expiry,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(
                          const Duration(days: 365 * 5),
                        ),
                      );
                      if (picked != null) setState(() => expiry = picked);
                    },
                  ),
                ],
              ),
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
                final policy = InsurancePolicy(
                  id: existing?.id ?? '',
                  policyNumber: numberController.text.trim(),
                  agentUid: appState.currentUser!.uid,
                  vehicleId: existing?.vehicleId,
                  freeTowRadiusKm: double.parse(radiusController.text),
                  ratePerKmAfterFree: double.parse(rateController.text),
                  status: status,
                  expiryDate: expiry,
                );
                if (existing == null) {
                  await appState.firestoreService.createPolicy(policy);
                } else {
                  await appState.firestoreService.updatePolicy(policy);
                }
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
