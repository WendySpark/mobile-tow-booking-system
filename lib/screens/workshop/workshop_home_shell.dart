import 'package:flutter/material.dart';

import '../profile_screen.dart';
import 'manage_drivers_screen.dart';
import 'workshop_bookings_screen.dart';
import 'workshop_profile_tab.dart';

class WorkshopHomeShell extends StatefulWidget {
  const WorkshopHomeShell({super.key});

  @override
  State<WorkshopHomeShell> createState() => _WorkshopHomeShellState();
}

class _WorkshopHomeShellState extends State<WorkshopHomeShell> {
  int _index = 0;

  static const _tabs = [
    WorkshopProfileTab(),
    ManageDriversScreen(),
    WorkshopBookingsScreen(),
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
          NavigationDestination(icon: Icon(Icons.storefront), label: 'My Workshop'),
          NavigationDestination(icon: Icon(Icons.local_shipping), label: 'Drivers'),
          NavigationDestination(icon: Icon(Icons.list_alt), label: 'Bookings'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
