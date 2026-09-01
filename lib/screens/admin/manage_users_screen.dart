import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../models/app_user.dart';
import '../../models/user_role.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/staggered_list_view.dart';

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
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final users = snapshot.data!;
          if (users.isEmpty) {
            return const EmptyState(
              icon: Icons.people_outline,
              title: 'No users yet',
            );
          }
          return StaggeredListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: users.length,
            itemBuilder: (context, i) {
              final u = users[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primarySurface,
                      foregroundColor: AppColors.primary,
                      child: Text(
                        u.name.isNotEmpty ? u.name[0].toUpperCase() : '?',
                      ),
                    ),
                    title: Text(u.name),
                    subtitle: Text('${u.email} · ${u.phone}'),
                    trailing: _RoleChip(role: u.role),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final color = switch (role) {
      UserRole.admin => AppColors.danger,
      UserRole.agent => AppColors.warning,
      UserRole.workshop => AppColors.primary,
      UserRole.user => AppColors.success,
    };
    return Chip(
      label: Text(role.value),
      backgroundColor: color.withValues(alpha: 0.12),
      labelStyle: TextStyle(
        color: color,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }
}
