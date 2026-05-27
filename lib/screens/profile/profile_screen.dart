import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_routes.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profil')),
        body: Center(
          child: FilledButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
            child: const Text('Login untuk melanjutkan'),
          ),
        ),
      );
    }

    final user = auth.currentUser!;
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: ListTile(
              leading: CircleAvatar(
                child: Text(user.name.substring(0, 1).toUpperCase()),
              ),
              title: Text(user.name),
              subtitle: Text('${user.email}\nRole: ${user.role}'),
              isThreeLine: true,
            ),
          ),
          const SizedBox(height: 12),
          if (auth.isAdmin)
            FilledButton.tonal(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.admin),
              child: const Text('Buka Admin Dashboard'),
            ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () async {
              await auth.logout();
              if (!context.mounted) return;
              Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
