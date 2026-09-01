import 'package:flutter/material.dart';

import '../profile_screen.dart';
import 'booking_history_screen.dart';
import 'payments_screen.dart';
import 'user_dashboard_tab.dart';
import 'vehicles_screen.dart';

class UserHomeShell extends StatefulWidget {
  const UserHomeShell({super.key});

  @override
  State<UserHomeShell> createState() => _UserHomeShellState();
}

class _UserHomeShellState extends State<UserHomeShell> {
  int _index = 0;

  static const _tabs = [
    UserDashboardTab(),
    VehiclesScreen(),
    PaymentsScreen(),
    BookingHistoryScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.directions_car),
            label: 'Vehicles',
          ),
          NavigationDestination(icon: Icon(Icons.payments), label: 'Payments'),
          NavigationDestination(icon: Icon(Icons.history), label: 'History'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
