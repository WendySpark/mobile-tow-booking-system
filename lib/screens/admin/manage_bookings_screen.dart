import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../models/booking.dart';
import '../../models/booking_status.dart';

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
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final bookings = snapshot.data!;
          if (bookings.isEmpty) return const Center(child: Text('No bookings yet.'));

          return ListView.builder(
            itemCount: bookings.length,
            itemBuilder: (context, i) {
              final b = bookings[i];
              return ListTile(
                leading: _statusIcon(b.status),
                title: Text(DateFormat.yMMMd().add_jm().format(b.createdAt)),
                subtitle: Text('${b.status.label} · ${b.distanceKm.toStringAsFixed(1)} km'),
                trailing: Text(b.charge == 0 ? 'FREE' : 'RM ${b.charge.toStringAsFixed(2)}'),
              );
            },
          );
        },
      ),
    );
  }

  Widget _statusIcon(BookingStatus status) => switch (status) {
        BookingStatus.completed => const Icon(Icons.check_circle, color: Colors.green),
        BookingStatus.cancelled => const Icon(Icons.cancel, color: Colors.red),
        BookingStatus.arrived => const Icon(Icons.local_shipping, color: Colors.green),
        BookingStatus.enRoute => const Icon(Icons.local_shipping, color: Colors.orange),
        _ => const Icon(Icons.hourglass_empty, color: Colors.grey),
      };
}
