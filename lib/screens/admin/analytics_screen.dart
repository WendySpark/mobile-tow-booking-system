import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../models/booking.dart';
import '../../models/repair_center.dart';
import '../../services/booking_analytics_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';

/// Admin dashboard: revenue, booking volume over time, free-vs-chargeable
/// mix, and busiest repair center — all derived from data already in
/// Firestore, no new collections needed.
class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  static const _analytics = BookingAnalyticsService();

  // Reused app status palette, kept fixed per series rather than cycled:
  // green = free/settled, indigo = chargeable/brand, orange = outstanding.
  static const _freeColor = AppColors.success;
  static const _chargeableColor = AppColors.primary;
  static const _outstandingColor = AppColors.warning;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: StreamBuilder<List<Booking>>(
        stream: appState.firestoreService.streamAllBookings(),
        builder: (context, bookingSnap) {
          if (!bookingSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final bookings = bookingSnap.data!;
          if (bookings.isEmpty) {
            return const EmptyState(
              icon: Icons.bar_chart_outlined,
              title: 'No bookings yet',
              subtitle: 'Analytics will appear once bookings start coming in.',
            );
          }

          final revenue = _analytics.totalRevenue(bookings);
          final outstanding = _analytics.totalOutstanding(bookings);
          final perDay = _analytics.bookingsPerDay(bookings);
          final freeCount = _analytics.freeTowCount(bookings);
          final chargeableCount = _analytics.paidTowCount(bookings);
          final byCenter = _analytics.bookingsByRepairCenter(bookings);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      label: 'Revenue Collected',
                      value: 'RM ${revenue.toStringAsFixed(2)}',
                      color: _freeColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatTile(
                      label: 'Outstanding',
                      value: 'RM ${outstanding.toStringAsFixed(2)}',
                      color: _outstandingColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Bookings — Last 7 Days',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 160,
                child: _BookingsPerDayChart(perDay: perDay),
              ),
              const SizedBox(height: 24),
              Text(
                'Free vs. Chargeable Tows',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              _FreeVsChargeable(
                freeCount: freeCount,
                chargeableCount: chargeableCount,
                freeColor: _freeColor,
                chargeableColor: _chargeableColor,
              ),
              const SizedBox(height: 24),
              Text(
                'Bookings by Repair Center',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              StreamBuilder<List<RepairCenter>>(
                stream: appState.firestoreService.streamRepairCenters(),
                builder: (context, centerSnap) {
                  final names = {
                    for (final c in centerSnap.data ?? <RepairCenter>[])
                      c.id: c.name,
                  };
                  return Column(
                    children: [
                      for (final entry in byCenter.take(5))
                        _CenterBar(
                          name: names[entry.key] ?? entry.key,
                          count: entry.value,
                          maxCount: byCenter.first.value,
                        ),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _BookingsPerDayChart extends StatelessWidget {
  const _BookingsPerDayChart({required this.perDay});

  final List<MapEntry<DateTime, int>> perDay;

  @override
  Widget build(BuildContext context) {
    final maxY = perDay.map((e) => e.value).fold(0, (m, v) => v > m ? v : m);
    return BarChart(
      BarChartData(
        maxY: (maxY < 4 ? 4 : maxY).toDouble(),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= perDay.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    DateFormat.E().format(perDay[i].key),
                    style: const TextStyle(fontSize: 11),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (int i = 0; i < perDay.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: perDay[i].value.toDouble(),
                  color: AppColors.primary,
                  width: 18,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ],
            ),
        ],
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
              '${rod.toY.toInt()} booking${rod.toY.toInt() == 1 ? '' : 's'}',
              const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

class _FreeVsChargeable extends StatelessWidget {
  const _FreeVsChargeable({
    required this.freeCount,
    required this.chargeableCount,
    required this.freeColor,
    required this.chargeableColor,
  });

  final int freeCount;
  final int chargeableCount;
  final Color freeColor;
  final Color chargeableColor;

  @override
  Widget build(BuildContext context) {
    final total = freeCount + chargeableCount;
    return Row(
      children: [
        SizedBox(
          height: 120,
          width: 120,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 28,
              sections: [
                PieChartSectionData(
                  value: freeCount.toDouble(),
                  color: freeColor,
                  title: total == 0
                      ? ''
                      : '${(freeCount / total * 100).round()}%',
                  radius: 24,
                  titleStyle: const TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                PieChartSectionData(
                  value: chargeableCount.toDouble(),
                  color: chargeableColor,
                  title: total == 0
                      ? ''
                      : '${(chargeableCount / total * 100).round()}%',
                  radius: 24,
                  titleStyle: const TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LegendRow(color: freeColor, label: 'Free', count: freeCount),
              const SizedBox(height: 8),
              _LegendRow(
                color: chargeableColor,
                label: 'Chargeable',
                count: chargeableCount,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.label,
    required this.count,
  });

  final Color color;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text('$label ($count)'),
      ],
    );
  }
}

class _CenterBar extends StatelessWidget {
  const _CenterBar({
    required this.name,
    required this.count,
    required this.maxCount,
  });

  final String name;
  final int count;
  final int maxCount;

  @override
  Widget build(BuildContext context) {
    final fraction = maxCount == 0 ? 0.0 : count / maxCount;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(name, overflow: TextOverflow.ellipsis),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 14,
                backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text('$count'),
        ],
      ),
    );
  }
}
