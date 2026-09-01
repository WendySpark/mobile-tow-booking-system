import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../models/booking.dart';
import '../../models/booking_status.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/staggered_list_view.dart';
import '../invoice_screen.dart';

class ManageBookingsScreen extends StatelessWidget {
  const ManageBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('All Bookings')),
      body: StreamBuilder<List<Booking>>(
        stream: appState.firestoreService.streamAllBookings(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final bookings = snapshot.data!;
          if (bookings.isEmpty) {
            return const EmptyState(
              icon: Icons.list_alt_outlined,
              title: 'No bookings yet',
            );
          }

          return StaggeredListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: bookings.length,
            itemBuilder: (context, i) {
              final b = bookings[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: _statusIcon(b.status),
                    title: Text(
                      DateFormat.yMMMd().add_jm().format(b.createdAt),
                    ),
                    subtitle: Text(
                      '${b.status.label} · ${b.distanceKm.toStringAsFixed(1)} km'
                      '${b.requiresPayment ? (b.paid ? ' · Paid' : ' · Unpaid') : ''}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          b.charge == 0
                              ? 'FREE'
                              : 'RM ${b.charge.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        if (b.isOutstanding)
                          IconButton(
                            icon: const Icon(
                              Icons.point_of_sale,
                              color: AppColors.warning,
                            ),
                            tooltip: 'Record cash payment',
                            onPressed: () =>
                                _confirmCashPayment(context, appState, b),
                          ),
                      ],
                    ),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => InvoiceScreen(booking: b),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmCashPayment(
    BuildContext context,
    AppState appState,
    Booking booking,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Record Cash Payment'),
        content: Text(
          'Mark RM ${booking.charge.toStringAsFixed(2)} as paid in cash?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await appState.firestoreService.markBookingPaid(
        booking.id,
        method: 'Cash (Admin)',
      );
    }
  }

  Widget _statusIcon(BookingStatus status) {
    final (icon, color) = switch (status) {
      BookingStatus.completed => (Icons.check_circle, AppColors.success),
      BookingStatus.cancelled => (Icons.cancel, AppColors.danger),
      BookingStatus.arrived => (Icons.local_shipping, AppColors.success),
      BookingStatus.enRoute => (Icons.local_shipping, AppColors.warning),
      _ => (Icons.hourglass_empty, AppColors.inkMuted),
    };
    return CircleAvatar(
      backgroundColor: color.withValues(alpha: 0.12),
      foregroundColor: color,
      child: Icon(icon, size: 20),
    );
  }
}
