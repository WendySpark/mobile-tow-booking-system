import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../models/booking.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
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
        stream: appState.firestoreService.streamBookingsForUser(
          appState.currentUser!.uid,
        ),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final chargeable = snapshot.data!
              .where((b) => b.requiresPayment)
              .toList();
          if (chargeable.isEmpty) {
            return const EmptyState(
              icon: Icons.payments_outlined,
              title: 'No chargeable bookings yet',
              subtitle: 'Tows within your free radius don\'t need a payment.',
            );
          }

          final outstanding = chargeable.where((b) => !b.paid).toList();

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: ListView(
              key: ValueKey(outstanding.length),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                if (outstanding.isNotEmpty)
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutCubic,
                    builder: (context, t, child) => Opacity(
                      opacity: t,
                      child: Transform.translate(
                        offset: Offset(0, (1 - t) * 12),
                        child: child,
                      ),
                    ),
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.warningSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.warning.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'You have ${outstanding.length} outstanding payment'
                                  '${outstanding.length == 1 ? '' : 's'}',
                                  style: const TextStyle(
                                    color: AppColors.warning,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Total due: RM ${outstanding.fold(0.0, (sum, b) => sum + b.charge).toStringAsFixed(2)}. '
                                  'Settle these before booking a new tow.',
                                  style: const TextStyle(
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
                for (final booking in chargeable)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          backgroundColor:
                              (booking.paid
                                      ? AppColors.success
                                      : AppColors.warning)
                                  .withValues(alpha: 0.12),
                          foregroundColor: booking.paid
                              ? AppColors.success
                              : AppColors.warning,
                          child: Icon(
                            booking.paid
                                ? Icons.check_circle
                                : Icons.error_outline,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          DateFormat.yMMMd().format(booking.createdAt),
                        ),
                        subtitle: Text(booking.paid ? 'Paid' : 'Unpaid'),
                        trailing: booking.paid
                            ? Text(
                                'RM ${booking.charge.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            : FilledButton(
                                onPressed: () => _payDialog(context, booking),
                                child: const Text('Pay Now'),
                              ),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => InvoiceScreen(booking: booking),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
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
                  height: 80,
                  child: Center(child: CircularProgressIndicator()),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final method in [
                      'Credit/Debit Card',
                      'Online Banking',
                      'E-Wallet',
                    ])
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
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Cancel'),
                  ),
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
                            if (dialogContext.mounted)
                              Navigator.pop(dialogContext);
                          },
                    child: const Text('Confirm Payment'),
                  ),
                ],
        ),
      ),
    );
  }
}
