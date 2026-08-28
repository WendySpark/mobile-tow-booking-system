import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../models/booking.dart';
import '../invoice_screen.dart';

/// Covers "who will pay the extra amount — make a payment tab for them".
/// Lists every booking that ever carried a charge, lets the user settle
/// outstanding ones, and links through to each booking's invoice.
class PaymentsScreen extends StatelessWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Payments')),
      body: StreamBuilder<List<Booking>>(
        stream: appState.firestoreService.streamBookingsForUser(appState.currentUser!.uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final chargeable = snapshot.data!.where((b) => b.requiresPayment).toList();
          if (chargeable.isEmpty) {
            return const Center(child: Text('No chargeable bookings yet.'));
          }

          final outstanding = chargeable.where((b) => !b.paid).toList();

          return ListView(
            children: [
              if (outstanding.isNotEmpty)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'You have ${outstanding.length} outstanding payment'
                        '${outstanding.length == 1 ? '' : 's'}',
                        style: TextStyle(color: Colors.orange.shade900, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Total due: RM ${outstanding.fold(0.0, (sum, b) => sum + b.charge).toStringAsFixed(2)}. '
                        'Settle these before booking a new tow.',
                        style: TextStyle(color: Colors.orange.shade900),
                      ),
                    ],
                  ),
                ),
              for (final booking in chargeable)
                ListTile(
                  leading: Icon(
                    booking.paid ? Icons.check_circle : Icons.error_outline,
                    color: booking.paid ? Colors.green : Colors.orange,
                  ),
                  title: Text(DateFormat.yMMMd().format(booking.createdAt)),
                  subtitle: Text(booking.paid ? 'Paid' : 'Unpaid'),
                  trailing: booking.paid
                      ? Text('RM ${booking.charge.toStringAsFixed(2)}')
                      : FilledButton(
                          onPressed: () => _payDialog(context, booking),
                          child: const Text('Pay Now'),
                        ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => InvoiceScreen(booking: booking)),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _payDialog(BuildContext context, Booking booking) async {
    final appState = context.read<AppState>();
    String? selectedMethod;
    bool isProcessing = false;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: Text('Pay RM ${booking.charge.toStringAsFixed(2)}'),
          content: isProcessing
              ? const SizedBox(
                  height: 80, child: Center(child: CircularProgressIndicator()))
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final method in ['Credit/Debit Card', 'Online Banking', 'E-Wallet'])
                      RadioListTile<String>(
                        title: Text(method),
                        value: method,
                        groupValue: selectedMethod,
                        onChanged: (v) => setState(() => selectedMethod = v),
                      ),
                  ],
                ),
          actions: isProcessing
              ? []
              : [
                  TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
                  FilledButton(
                    onPressed: selectedMethod == null
                        ? null
                        : () async {
                            setState(() => isProcessing = true);
                            // Simulated payment gateway round-trip.
                            await Future.delayed(const Duration(seconds: 1));
                            await appState.firestoreService.markBookingPaid(
                              booking.id,
                              method: selectedMethod!,
                            );
                            if (dialogContext.mounted) Navigator.pop(dialogContext);
                          },
                    child: const Text('Confirm Payment'),
                  ),
                ],
        ),
      ),
    );
  }
}
