import 'package:flutter/material.dart';

import '../profile_screen.dart';
import 'manage_policies_screen.dart';

class AgentHomeShell extends StatefulWidget {
  const AgentHomeShell({super.key});

  @override
  State<AgentHomeShell> createState() => _AgentHomeShellState();
}

class _AgentHomeShellState extends State<AgentHomeShell> {
  int _index = 0;

  static const _tabs = [
    ManagePoliciesScreen(),
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
          NavigationDestination(icon: Icon(Icons.shield), label: 'Policies'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
