import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_experience_provider.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final experience = context.watch<DashboardExperienceProvider>();
    final transactions = experience.paymentTransactions.take(8).toList();
    final vouchers = experience.redeemedVouchers.take(6).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!auth.isLoggedIn)
            Card(
              child: ListTile(
                leading: const Icon(Icons.login_rounded),
                title: const Text('Masuk untuk melihat notifikasi lengkap'),
                subtitle: const Text(
                  'Riwayat pembayaran, voucher, dan pengingat promo akan muncul setelah login.',
                ),
                trailing: FilledButton(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
                  child: const Text('Masuk'),
                ),
              ),
            ),
          if (auth.isLoggedIn) ...[
            _SectionHeader(
              title: 'Pembayaran',
              actionLabel: 'Wallet',
              onTap: () => Navigator.pushNamed(context, AppRoutes.wallet),
            ),
            if (transactions.isEmpty)
              const _EmptyCard(
                icon: Icons.receipt_long_rounded,
                title: 'Belum ada notifikasi pembayaran',
                subtitle: 'Transaksi top up, subscription, dan update status pembayaran akan muncul di sini.',
              )
            else
              ...transactions.map(
                (transaction) => Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Icon(
                        transaction.status == PaymentStatus.approved
                            ? Icons.check_rounded
                            : transaction.status == PaymentStatus.pending
                                ? Icons.schedule_rounded
                                : Icons.close_rounded,
                      ),
                    ),
                    title: Text(transaction.itemName),
                    subtitle: Text(
                      '${transaction.paymentMethod} • ${transaction.status.label}',
                    ),
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.paymentDetail,
                      arguments: transaction,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            _SectionHeader(
              title: 'Voucher',
              actionLabel: 'Wallet',
              onTap: () => Navigator.pushNamed(context, AppRoutes.wallet),
            ),
            if (vouchers.isEmpty)
              const _EmptyCard(
                icon: Icons.local_offer_outlined,
                title: 'Belum ada voucher diklaim',
                subtitle: 'Voucher yang kamu klaim atau dapat dari reward akan muncul di sini.',
              )
            else
              ...vouchers.map(
                (voucher) => Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Icon(
                        voucher.isUsed
                            ? Icons.verified_rounded
                            : Icons.redeem_rounded,
                      ),
                    ),
                    title: Text(voucher.title),
                    subtitle: Text(
                      voucher.isUsed
                          ? 'Sudah dipakai'
                          : 'Sudah diklaim, belum dipakai',
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onTap,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          TextButton(
            onPressed: onTap,
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icon, size: 32),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
