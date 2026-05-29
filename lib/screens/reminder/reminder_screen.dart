import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/reminder_provider.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_widget.dart';

class ReminderScreen extends StatelessWidget {
  const ReminderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('Reminder Promo')),
        body: Center(
          child: FilledButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
            child: const Text('Login untuk melihat reminder'),
          ),
        ),
      );
    }

    final provider = context.watch<ReminderProvider>();
    if (provider.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Reminder Promo')),
        body: const LoadingWidget(message: 'Sedang memuat reminder promo...'),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Reminder Promo')),
      body: provider.reminders.isEmpty
          ? const EmptyState(
              title: 'Belum ada reminder',
              subtitle: 'Tambahkan reminder dari halaman detail promo.',
              icon: Icons.notifications_none,
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: provider.reminders.length,
              itemBuilder: (context, index) {
                final reminder = provider.reminders[index];
                return Card(
                  child: ListTile(
                    title: Text(reminder.productName),
                    subtitle: Text(
                      '${reminder.storeName}\n${DateFormatter.dateTime(reminder.reminderTime)}',
                    ),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => provider.removeReminder(
                        auth.currentUser!.id,
                        reminder.promoId,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
