import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/promo_provider.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/empty_state.dart';

class ReminderScreen extends StatelessWidget {
  const ReminderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PromoProvider>();
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
                      onPressed: () => provider.removeReminder(reminder.promoId),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

