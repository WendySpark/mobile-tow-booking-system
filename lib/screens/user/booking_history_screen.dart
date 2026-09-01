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

class BookingHistoryScreen extends StatelessWidget {
  const BookingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Booking History')),
      body: StreamBuilder<List<Booking>>(
        stream: appState.firestoreService.streamBookingsForUser(
          appState.currentUser!.uid,
        ),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final bookings = snapshot.data!;
          if (bookings.isEmpty) {
            return const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No bookings yet',
              subtitle:
                  'Your completed and in-progress tows will show up here.',
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
                      b.requiresPayment
                          ? '${b.status.label} · ${b.paid ? "Paid" : "Unpaid"}'
                          : b.status.label,
                    ),
                    trailing: Text(
                      b.charge == 0
                          ? 'FREE'
                          : 'RM ${b.charge.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
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
