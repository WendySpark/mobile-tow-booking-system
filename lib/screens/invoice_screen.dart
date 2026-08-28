import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models/booking.dart';
import '../models/repair_center.dart';
import '../models/vehicle.dart';

/// Read-only invoice for a single booking, covering "make an invoice for
/// them too". Shared between User (their own bookings) and Admin (any
/// booking, via Manage Bookings).
class InvoiceScreen extends StatelessWidget {
  const InvoiceScreen({super.key, required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final dateFormat = DateFormat.yMMMd().add_jm();

    return Scaffold(
      appBar: AppBar(title: const Text('Invoice')),
      body: FutureBuilder(
        future: Future.wait([
          appState.firestoreService.getVehicle(booking.vehicleId),
          appState.firestoreService.getRepairCenter(booking.repairCenterId),
        ]),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final vehicle = snapshot.data![0] as Vehicle?;
          final center = snapshot.data![1] as RepairCenter?;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Invoice', style: Theme.of(context).textTheme.headlineSmall),
                        Text('#${booking.id.substring(0, booking.id.length.clamp(0, 8)).toUpperCase()}'),
                      ],
                    ),
                    _StatusPill(booking: booking),
                  ],
                ),
                const SizedBox(height: 4),
                Text(dateFormat.format(booking.createdAt), style: const TextStyle(color: Colors.grey)),
                const Divider(height: 32),
                _InfoRow(label: 'Vehicle', value: vehicle?.displayName ?? booking.vehicleId),
                _InfoRow(label: 'Repair Center', value: center?.name ?? booking.repairCenterId),
                if (booking.driverName != null) _InfoRow(label: 'Driver', value: booking.driverName!),
                const Divider(height: 32),
                Text('Charge Breakdown', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                _LineItem(label: 'Total distance', value: '${booking.distanceKm.toStringAsFixed(1)} km'),
                _LineItem(
                    label: 'Free distance (policy coverage)',
                    value: '${booking.freeDistanceKm.toStringAsFixed(1)} km'),
                _LineItem(
                    label: 'Chargeable distance',
                    value: '${booking.chargeableDistanceKm.toStringAsFixed(1)} km'),
                const Divider(height: 24),
                _LineItem(
                  label: 'Total Amount',
                  value: booking.charge == 0 ? 'FREE' : 'RM ${booking.charge.toStringAsFixed(2)}',
                  emphasize: true,
                ),
                const SizedBox(height: 24),
                if (booking.paid && booking.paidAt != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Paid on ${dateFormat.format(booking.paidAt!)}'
                      '${booking.paymentMethod != null ? ' via ${booking.paymentMethod}' : ''}',
                      style: TextStyle(color: Colors.green.shade800),
                    ),
                  )
                else if (booking.requiresPayment)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Payment outstanding', style: TextStyle(color: Colors.orange.shade900)),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final free = !booking.requiresPayment;
    final label = free ? 'FREE' : (booking.paid ? 'PAID' : 'UNPAID');
    final color = free || booking.paid ? Colors.green : Colors.orange;
    return Chip(
      label: Text(label, style: TextStyle(color: color.shade800, fontWeight: FontWeight.bold)),
      backgroundColor: color.shade50,
      side: BorderSide(color: color.shade200),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _LineItem extends StatelessWidget {
  const _LineItem({required this.label, required this.value, this.emphasize = false});

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final style = emphasize
        ? Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)
        : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }
}
