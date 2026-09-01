import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../models/booking.dart';
import '../../models/booking_status.dart';
import '../../services/payment_gate_service.dart';
import '../../theme/app_theme.dart';
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
    final bookings = await appState.firestoreService.fetchBookingsForUser(
      appState.currentUser!.uid,
    );
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
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
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
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const RequestTowScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Hi, ${appState.currentUser!.name.split(' ').first} 👋'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: _isCheckingPayments ? null : () => _onRequestTow(appState),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.28),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: _isCheckingPayments
                            ? const Padding(
                                padding: EdgeInsets.all(14),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.add_road,
                                color: Colors.white,
                                size: 26,
                              ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Request a Tow',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Get a nearby workshop dispatched to you',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Active Booking',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          StreamBuilder<List<Booking>>(
            stream: appState.firestoreService.streamBookingsForUser(
              appState.currentUser!.uid,
            ),
            builder: (context, snapshot) {
              final bookings = snapshot.data ?? [];
              final active = bookings.where(
                (b) =>
                    b.status != BookingStatus.completed &&
                    b.status != BookingStatus.cancelled,
              );
              if (active.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.local_shipping_outlined,
                        color: AppColors.inkMuted,
                        size: 28,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'No active booking',
                        style: TextStyle(color: AppColors.inkMuted),
                      ),
                    ],
                  ),
                );
              }
              final booking = active.first;
              final statusColor = booking.status == BookingStatus.arrived
                  ? AppColors.success
                  : AppColors.primary;
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                builder: (context, t, child) => Opacity(
                  opacity: t,
                  child: Transform.translate(
                    offset: Offset(0, (1 - t) * 10),
                    child: child,
                  ),
                ),
                child: Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: statusColor.withValues(alpha: 0.12),
                      foregroundColor: statusColor,
                      child: const Icon(Icons.local_shipping, size: 20),
                    ),
                    title: Text(booking.status.label),
                    subtitle: Text(
                      booking.charge == 0
                          ? 'FREE'
                          : 'RM ${booking.charge.toStringAsFixed(2)}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BookingTrackingScreen(booking: booking),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
