import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../models/app_user.dart';
import '../../models/user_role.dart';

class ManageUsersScreen extends StatelessWidget {
  const ManageUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Users')),
      body: StreamBuilder<List<AppUser>>(
        stream: appState.firestoreService.streamUsers(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final users = snapshot.data!;
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, i) {
              final u = users[i];
              return ListTile(
                leading: CircleAvatar(child: Text(u.name.isNotEmpty ? u.name[0].toUpperCase() : '?')),
                title: Text(u.name),
                subtitle: Text('${u.email} · ${u.phone}'),
                trailing: Chip(label: Text(u.role.value)),
              );
            },
          );
        },
      ),
    );
  }
}
