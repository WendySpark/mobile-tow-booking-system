import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models/user_role.dart';
import 'admin/admin_home_shell.dart';
import 'agent/agent_home_shell.dart';
import 'auth/login_screen.dart';
import 'user/user_home_shell.dart';

/// Sends a signed-in user to the right module based on their stored role.
/// This is the entire "Admin, User, Insurance Agent modules" split: one
/// codebase, branching after authentication rather than three separate apps.
class RoleRouter extends StatelessWidget {
  const RoleRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final user = appState.currentUser;

    if (appState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (user == null) {
      return const LoginScreen();
    }
    return switch (user.role) {
      UserRole.admin => const AdminHomeShell(),
      UserRole.agent => const AgentHomeShell(),
      UserRole.user => const UserHomeShell(),
    };
  }
}
