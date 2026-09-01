import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models/booking.dart';
import '../models/repair_center.dart';
import '../models/vehicle.dart';
import '../theme/app_theme.dart';

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
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final vehicle = snapshot.data![0] as Vehicle?;
          final center = snapshot.data![1] as RepairCenter?;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              builder: (context, t, child) => Opacity(
                opacity: t,
                child: Transform.translate(
                  offset: Offset(0, (1 - t) * 16),
                  child: child,
                ),
              ),
              child: Card(
                child: Padding(
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
                              Text(
                                'Invoice',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall,
                              ),
                              Text(
                                '#${booking.id.substring(0, booking.id.length.clamp(0, 8)).toUpperCase()}',
                                style: const TextStyle(
                                  color: AppColors.inkMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          _StatusPill(booking: booking),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateFormat.format(booking.createdAt),
                        style: const TextStyle(color: AppColors.inkMuted),
                      ),
                      const Divider(height: 32),
                      _InfoRow(
                        label: 'Vehicle',
                        value: vehicle?.displayName ?? booking.vehicleId,
                      ),
                      _InfoRow(
                        label: 'Repair Center',
                        value: center?.name ?? booking.repairCenterId,
                      ),
                      if (booking.driverName != null)
                        _InfoRow(label: 'Driver', value: booking.driverName!),
                      const Divider(height: 32),
                      Text(
                        'Charge Breakdown',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      _LineItem(
                        label: 'Total distance',
                        value: '${booking.distanceKm.toStringAsFixed(1)} km',
                      ),
                      _LineItem(
                        label: 'Free distance (policy coverage)',
                        value:
                            '${booking.freeDistanceKm.toStringAsFixed(1)} km',
                      ),
                      _LineItem(
                        label: 'Chargeable distance',
                        value:
                            '${booking.chargeableDistanceKm.toStringAsFixed(1)} km',
                      ),
                      const Divider(height: 24),
                      _LineItem(
                        label: 'Total Amount',
                        value: booking.charge == 0
                            ? 'FREE'
                            : 'RM ${booking.charge.toStringAsFixed(2)}',
                        emphasize: true,
                      ),
                      const SizedBox(height: 24),
                      if (booking.paid && booking.paidAt != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.successSurface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: AppColors.success,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Paid on ${dateFormat.format(booking.paidAt!)}'
                                  '${booking.paymentMethod != null ? ' via ${booking.paymentMethod}' : ''}',
                                  style: const TextStyle(
                                    color: AppColors.success,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (booking.requiresPayment)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.warningSurface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: AppColors.warning,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Payment outstanding',
                                style: TextStyle(
                                  color: AppColors.warning,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
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
    final color = free || booking.paid ? AppColors.success : AppColors.warning;
    return Chip(
      label: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
      backgroundColor: color.withValues(alpha: 0.12),
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
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
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.inkMuted),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _LineItem extends StatelessWidget {
  const _LineItem({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final style = emphasize
        ? Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.bold)
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
