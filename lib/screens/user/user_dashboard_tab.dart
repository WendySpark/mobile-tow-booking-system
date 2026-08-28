import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../models/booking.dart';
import '../../models/booking_status.dart';
import 'booking_tracking_screen.dart';
import 'request_tow_screen.dart';

class UserDashboardTab extends StatelessWidget {
  const UserDashboardTab({super.key});

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
              icon: const Icon(Icons.add_road),
              label: const Text('Request a Tow'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RequestTowScreen()),
              ),
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
