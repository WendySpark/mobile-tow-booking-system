import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../models/booking.dart';
import '../../models/booking_status.dart';
import '../../services/payment_gate_service.dart';
import 'booking_tracking_screen.dart';
import 'payments_screen.dart';
import 'request_tow_screen.dart';

class UserDashboardTab extends StatefulWidget {
  const UserDashboardTab({super.key});

  @override
  State<UserDashboardTab> createState() => _UserDashboardTabState();
}

class _UserDashboardTabState extends State<UserDashboardTab> {
  static const _paymentGate = PaymentGateService();
  bool _isCheckingPayments = false;

  Future<void> _onRequestTow(AppState appState) async {
    setState(() => _isCheckingPayments = true);
    final bookings = await appState.firestoreService.fetchBookingsForUser(appState.currentUser!.uid);
    if (!mounted) return;
    setState(() => _isCheckingPayments = false);

    if (_paymentGate.hasOutstandingPayment(bookings)) {
      final outstanding = _paymentGate.outstandingBookings(bookings);
      final total = _paymentGate.totalOutstanding(bookings);
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Outstanding Payment'),
          content: Text(
            'You have ${outstanding.length} unpaid booking${outstanding.length == 1 ? '' : 's'} '
            'totalling RM ${total.toStringAsFixed(2)}. Please settle ${outstanding.length == 1 ? 'it' : 'them'} '
            'before requesting a new tow.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PaymentsScreen()),
                );
              },
              child: const Text('Go to Payments'),
            ),
          ],
        ),
      );
      return;
    }

    if (!mounted) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RequestTowScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: Text('Hi, ${appState.currentUser!.name}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton.icon(
              icon: _isCheckingPayments
                  ? const SizedBox(
                      height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.add_road),
              label: const Text('Request a Tow'),
              onPressed: _isCheckingPayments ? null : () => _onRequestTow(appState),
            ),
            const SizedBox(height: 24),
            Text('Active Booking', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            StreamBuilder<List<Booking>>(
              stream: appState.firestoreService.streamBookingsForUser(appState.currentUser!.uid),
              builder: (context, snapshot) {
                final bookings = snapshot.data ?? [];
                final active = bookings.where((b) =>
                    b.status != BookingStatus.completed && b.status != BookingStatus.cancelled);
                if (active.isEmpty) {
                  return const Text('No active booking.', style: TextStyle(color: Colors.grey));
                }
                final booking = active.first;
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.local_shipping, color: Colors.indigo),
                    title: Text(booking.status.label),
                    subtitle: Text(
                        booking.charge == 0 ? 'FREE' : 'RM ${booking.charge.toStringAsFixed(2)}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => BookingTrackingScreen(booking: booking)),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
